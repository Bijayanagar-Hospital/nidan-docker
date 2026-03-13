# syntax=docker/dockerfile:1

### Clone content repo (base image has no git; use alpine)
FROM alpine:3.19 AS content-clone
ARG CONTENT_REPO_URL="https://github.com/Trigonal-Technology/openmrs-content-referenceapplication-demo.git"
ARG CONTENT_REPO_REF="main"
ARG CACHE_BUST
RUN apk add --no-cache git && \
    echo "CACHE_BUST=${CACHE_BUST}" >/dev/null && \
    git clone --depth 1 --branch "${CONTENT_REPO_REF}" "${CONTENT_REPO_URL}" /content

### Dev Stage
FROM openmrs/openmrs-core:2.8.x-dev-amazoncorretto-21 AS dev
WORKDIR /openmrs_distro

# Build profile switch:
#   no-demo (default/production) — excludes referencedemodata, stockmanagement, billing
#   distro  (with demo data)     — full demo stack
# Override at build time: docker-compose build --build-arg OMRS_PROFILE=distro openmrs-backend
ARG OMRS_PROFILE="no-demo"
ARG MVN_ARGS_SETTINGS="-s /usr/share/maven/ref/settings-docker.xml -B -P distro"
ARG CONTENT_VERSION="1.8.0-nidan-SNAPSHOT"

# Copy build files (paths relative to build context = ./openmrs)
COPY pom.xml ./
COPY distro ./distro/
COPY custom_modules /openmrs_distro/custom_modules/

# Copy cloned content from content-clone stage
COPY --from=content-clone /content /tmp/openmrs-content-referenceapplication-demo

ARG CACHE_BUST
# Build content + distro in ONE RUN; use default ~/.m2/repository so install and build share same repo.
RUN --mount=type=secret,id=m2settings,target=/usr/share/maven/ref/settings-docker.xml \
    mkdir -p /root/.m2 && \
    echo "statsEnabled=false" > /root/.m2/sdk-stats.properties && \
    echo "statsEnabled=false" > sdk-stats.properties && \
    for f in /openmrs_distro/custom_modules/medication-administration-*.omod; do \
      [ -f "$$f" ] && mvn -s /usr/share/maven/ref/settings-docker.xml install:install-file -Dfile="$$f" -DgroupId=org.bahmni.module \
        -DartifactId=medication-administration-omod -Dversion=2.0.0-SNAPSHOT -Dpackaging=jar -q; break; \
    done && \
    sed -i "s|<version>1.8.0-SNAPSHOT</version>|<version>${CONTENT_VERSION}</version>|" /tmp/openmrs-content-referenceapplication-demo/pom.xml && \
    mvn $MVN_ARGS_SETTINGS -f /tmp/openmrs-content-referenceapplication-demo/pom.xml install -DskipTests -q && \
    rm -rf /tmp/openmrs-content-referenceapplication-demo && \
    sed -i "s|<reference-demo-content.version>.*</reference-demo-content.version>|<reference-demo-content.version>${CONTENT_VERSION}</reference-demo-content.version>|" distro/pom.xml && \
    MVN_ARGS="clean install -P ${OMRS_PROFILE}"; \
    if [[ "$MVN_ARGS" != "deploy -P ${OMRS_PROFILE}" || "$(arch)" = "x86_64" ]]; then \
    mvn $MVN_ARGS_SETTINGS $MVN_ARGS; \
    else \
    mvn $MVN_ARGS_SETTINGS clean install -P ${OMRS_PROFILE}; \
    fi

RUN cp /openmrs_distro/distro/target/sdk-distro/web/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/

RUN cp /openmrs_distro/distro/target/sdk-distro/web/openmrs-distro.properties /openmrs/distribution/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_modules /openmrs/distribution/openmrs_modules/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_owas /openmrs/distribution/openmrs_owas/
# SDK build-distro only includes config from referenceapplication base (8 domains).
# Overlay full configuration from cloned content so all domains are present.
COPY --from=content-clone /content/configuration /tmp/content-config
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_config /openmrs/distribution/openmrs_config/ && \
    cp -R /tmp/content-config/* /openmrs/distribution/openmrs_config/ && \
    rm -rf /tmp/content-config

# Clean up after copying needed artifacts
RUN mvn $MVN_ARGS_SETTINGS clean

### Run Stage
FROM openmrs/openmrs-core:2.8.x-amazoncorretto-21

# Copy built artifacts from dev stage
COPY --from=dev /openmrs/distribution/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/
COPY --from=dev /openmrs/distribution/openmrs-distro.properties /openmrs/distribution/
COPY --from=dev /openmrs/distribution/openmrs_modules /openmrs/distribution/openmrs_modules
COPY --from=dev /openmrs/distribution/openmrs_owas /openmrs/distribution/openmrs_owas
COPY --from=dev /openmrs/distribution/openmrs_config /openmrs/distribution/openmrs_config

# Copy custom SNAPSHOT modules (attachments, appointments, fhir2, bahmni-ipd,
# medication-administration, orderexpansion — see custom_modules/README)
COPY custom_modules/ /openmrs/distribution/openmrs_modules/

# Copy Nidan PostgreSQL Dialect jar into Tomcat shared lib
# (startup-custom.sh also injects it into the WAR's WEB-INF/lib for safety)
COPY nidan-dialect.jar /usr/local/tomcat/lib/nidan-dialect.jar
