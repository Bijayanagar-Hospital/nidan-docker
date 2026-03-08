# syntax=docker/dockerfile:1

### Dev Stage
FROM openmrs/openmrs-core:2.8.x-dev-amazoncorretto-21 AS dev
WORKDIR /openmrs_distro

# Build profile switch:
#   no-demo (default/production) — excludes referencedemodata, stockmanagement, billing
#   distro  (with demo data)     — full demo stack
# Override at build time: docker-compose build --build-arg OMRS_PROFILE=distro openmrs-backend
ARG OMRS_PROFILE="no-demo"
ARG MVN_ARGS_SETTINGS="-s /usr/share/maven/ref/settings-docker.xml -U -P distro"

# Copy build files
COPY pom.xml ./
COPY distro ./distro/

ARG CACHE_BUST
# Build the distro; activate the selected profile; only deploy from amd64 builds
RUN --mount=type=secret,id=m2settings,target=/usr/share/maven/ref/settings-docker.xml \
    MVN_ARGS="install -P ${OMRS_PROFILE}"; \
    if [[ "$MVN_ARGS" != "deploy -P ${OMRS_PROFILE}" || "$(arch)" = "x86_64" ]]; then \
    mvn $MVN_ARGS_SETTINGS $MVN_ARGS; \
    else \
    mvn $MVN_ARGS_SETTINGS install -P ${OMRS_PROFILE}; \
    fi

RUN cp /openmrs_distro/distro/target/sdk-distro/web/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/

RUN cp /openmrs_distro/distro/target/sdk-distro/web/openmrs-distro.properties /openmrs/distribution/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_modules /openmrs/distribution/openmrs_modules/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_owas /openmrs/distribution/openmrs_owas/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_config /openmrs/distribution/openmrs_config/

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

# ── Nidan customisations ──────────────────────────────────────────────────────
# All filesystem operations run as root (openmrs user may not exist in this image)
USER root
RUN rm -f /openmrs/distribution/openmrs_modules/attachments-*.omod && \
    rm -f /openmrs/distribution/openmrs_modules/appointments-*.omod && \
    rm -f /openmrs/distribution/openmrs_modules/fhir2-*.omod && \
    rm -f /openmrs/distribution/openmrs_modules/patientdocuments-*.omod && \
    rm -f /openmrs/distribution/openmrs_modules/stockmanagement-*.omod && \
    rm -f /openmrs/distribution/openmrs_modules/billing-*.omod && \
    rm -f /openmrs/distribution/openmrs_modules/referencedemodata-*.omod && \
    mkdir -p /openmrs/distribution/ocl/loadAtStartup

# Copy custom SNAPSHOT modules (attachments, appointments, fhir2, bahmni-ipd,
# medication-administration, orderexpansion — see custom_modules/README)
COPY custom_modules/ /openmrs/distribution/openmrs_modules/

# Copy Nidan PostgreSQL Dialect jar into Tomcat shared lib
# (startup-custom.sh also injects it into the WAR's WEB-INF/lib for safety)
COPY nidan-dialect.jar /usr/local/tomcat/lib/nidan-dialect.jar

