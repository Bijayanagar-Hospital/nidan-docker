#!/bin/bash

BAHMNI_DOCKER_ENV_FILE="./.env"

source ./backup_utils.sh
source ${BAHMNI_DOCKER_ENV_FILE}

# Set the backup folder path
BACKUP_ROOT_FOLDER="./backup-artifacts"

# Get the current datetime
datetime=$(date +'%Y-%m-%d_%H-%M-%S')

# Create the backup folder with the current datetime
backup_subfolder_path="$BACKUP_ROOT_FOLDER/$datetime"
mkdir -p "$backup_subfolder_path"

log_info "Saving backup to $backup_subfolder_path..."


openmrs_db_backup_file_path=$backup_subfolder_path/openmrsdb_backup.sql
openelis_db_backup_file_path=$backup_subfolder_path/openelisdb_backup.sql
odoo_db_backup_file_path=$backup_subfolder_path/odoodb_backup.sql
orthanc_db_backup_file_path=$backup_subfolder_path/orthandb_backup.sql
dhis2_db_backup_file_path=$backup_subfolder_path/dhis2db_backup.sql
middleware_db_backup_file_path=$backup_subfolder_path/middlewaredb_backup.sql

openmrs_service_name="openmrs-backend"
openmrs_db_service_name="openmrs-db"
openelis_db_service_name="openelis-db"
odoo_service_name="odoo"
odoo_db_service_name="odoo-db"
orthanc_service_name="orthanc"
orthanc_db_service_name="orthanc-db"
dhis2_service_name="nidan-dhis2"
dhis2_db_service_name="nidan-dhis2-db"
middleware_db_service_name="nidan-integration-db"



log_info "Taking backup for OpenMRS Database"
backup_db "mysql" $OPENMRS_DB_NAME $OPENMRS_DB_USER $OPENMRS_DB_PASSWORD $openmrs_db_service_name $openmrs_db_backup_file_path

log_info "Taking backup for Dhis2 Database"
backup_db "mysql" $DHIS2_DB_NAME $DHIS2_DB_USER $DHIS2_DB_PASSWORD $dhis2_db_service_name $dhis2_db_backup_file_path

log_info "Taking backup for OpenELIS Database"
backup_db "postgres" $OPENELIS_DB_NAME $OPENELIS_DB_USER $OPENELIS_DB_PASSWORD $openelis_db_service_name $openelis_db_backup_file_path

log_info "Taking backup for Odoo Database"
backup_db "postgres" $ODOO_DB_NAME $ODOO_DB_USER $ODOO_DB_PASSWORD $odoo_db_service_name $odoo_db_backup_file_path

log_info "Taking backup for Middleware Database"
backup_db "postgres" $INTEGRATION_DB_NAME $INTEGRATION_DB_USER $INTEGRATION_DB_PASSWORD $middleware_db_service_name $middleware_db_backup_file_path

log_info "Taking backup for Orthanc Database"
backup_db "postgres" $ORTHANC_DB_NAME $ORTHANC_DB_USER $ORTHANC_DB_PASSWORD $orthanc_db_service_name $orthanc_db_backup_file_path 

log_info "Taking backup for Clinical-Forms"
backup_container_file_system $openmrs_service_name "/openmrs/data/configuration" "$BACKUP_ROOT_FOLDER"

log_info "Taking backup for Configuration Checksums"
backup_container_file_system $openmrs_service_name "/openmrs/data/configuration_checksums" "$BACKUP_ROOT_FOLDER"

log_info "Taking backup for Odoo Files"
backup_container_file_system $odoo_service_name "/var/lib/odoo/filestore" "$BACKUP_ROOT_FOLDER"

log_info "Taking backup for orthanc worklists" 
backup_container_file_system $orthanc_service_name "/var/lib/orthanc" "$BACKUP_ROOT_FOLDER"

log_info "Taking backup for Dhis2 Mappings"
backup_container_file_system $dhis2_service_name "/app/mappings" "$BACKUP_ROOT_FOLDER"

log_info "Taking backup for Dhis2 SQL"
backup_container_file_system $dhis2_service_name "/app/sql" "$BACKUP_ROOT_FOLDER"
