# Extend Apache Superset with PostgreSQL driver (psycopg2)
# Required for connecting to OpenMRS, OpenELIS, Odoo databases
FROM apache/superset:latest

USER root

# Install PostgreSQL adapter into Superset's venv - use uv (Superset 5.x uses uv)
# SQLAlchemy needs psycopg2 for PostgreSQL connections to OpenMRS, OpenELIS, Odoo
RUN uv pip install --no-cache-dir psycopg2-binary

USER superset
