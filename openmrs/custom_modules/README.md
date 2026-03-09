# OpenMRS Custom Modules (OMOD files)

This directory holds pre-built `.omod` files (attachments, appointments, fhir2, bahmni-ipd, medication-administration, orderexpansion) that are copied into the OpenMRS Docker image.

**These files are not committed to git** (see `.gitignore`) because they are large binaries (~50MB total) that bloat repository history and vary by build.

## How to populate

Before building the OpenMRS image, build the modules from `openmrs-backend` and copy the `.omod` artifacts here:

```bash
# From the repo root, build each module and copy its omod
cd openmrs-backend/openmrs-module-attachments && mvn package -DskipTests && cp omod/target/*.omod ../../../nidan-docker/openmrs/custom_modules/
cd ../openmrs-module-appointments && mvn package -DskipTests && cp omod/target/*.omod ../../../nidan-docker/openmrs/custom_modules/
# ... repeat for fhir2, bahmni-ipd, medication-administration, orderexpansion
```

Or use a CI workflow that builds these modules and copies them before `docker compose build openmrs-backend`.
