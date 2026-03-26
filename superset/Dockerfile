# Extend Apache Superset with DB drivers: PostgreSQL + MySQL
# - psycopg2: OpenMRS/OpenELIS/Odoo when using PostgreSQL
# - pymysql: OpenMRS or other sources using mysql+pymysql://
FROM apache/superset:latest

USER root

RUN uv pip install --no-cache-dir psycopg2-binary pymysql

USER superset
