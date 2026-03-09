-- OpenMRS PostgreSQL initialization
-- The database and user are created by the postgres image from POSTGRES_DB/POSTGRES_USER env vars.
-- OpenMRS backend creates tables via Hibernate (OMRS_CONFIG_CREATE_TABLES) on first run.
-- Optional: enable extensions if needed by OpenMRS modules
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
