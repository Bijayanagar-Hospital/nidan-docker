#!/usr/bin/env python3
"""
NidanEHR Superset Comprehensive Hospital Dashboard
Creates database connections, datasets, charts, and dashboards for hospital analytics.
"""

import json
import os
import sys
from urllib.parse import quote_plus

sys.path.insert(0, "/app")


def get_db_uri(prefix: str, default_host: str, db_type: str = "postgresql") -> str:
    """Build database connection URI from env vars. db_type: postgresql or mysql."""
    host = os.environ.get(f"{prefix}_HOST", default_host)
    port = os.environ.get(f"{prefix}_PORT", "5432" if db_type == "postgresql" else "3306")
    name = os.environ.get(f"{prefix}_NAME", "")
    user = os.environ.get(f"{prefix}_USER", "")
    password = os.environ.get(f"{prefix}_PASSWORD", "")
    safe_password = quote_plus(password) if password else ""
    if db_type == "mysql":
        return f"mysql+pymysql://{user}:{safe_password}@{host}:{port}/{name}"
    return f"postgresql://{user}:{safe_password}@{host}:{port}/{name}"


def main():
    from superset.app import create_app

    app = create_app()

    openmrs_db_type = os.environ.get("OPENMRS_DB_TYPE", "mysql")
    DB_CONFIGS = {
        "openmrs": {"name": "OpenMRS", "uri": get_db_uri("OPENMRS_DB", "openmrs-db", openmrs_db_type)},
        "openelis": {"name": "OpenELIS", "uri": get_db_uri("OPENELIS_DB", "openelis-db")},
        "odoo": {"name": "Odoo", "uri": get_db_uri("ODOO_DB", "odoo-db")},
    }

    with app.app_context():
        from superset.extensions import db
        from superset.models.core import Database
        from superset.connectors.sqla.models import SqlaTable, TableColumn
        from superset.models.slice import Slice
        from superset.models.dashboard import Dashboard

        # Explicit column definitions for when fetch_metadata fails (schema mismatch, etc.)
        DATASET_COLUMNS = {
            "patient_registrations_trend": [("registration_date", "DATE"), ("patient_count", "BIGINT"), ("male_count", "BIGINT"), ("female_count", "BIGINT")],
            "patient_demographics": [("age_group", "VARCHAR"), ("gender", "VARCHAR"), ("patient_count", "BIGINT")],
            "patient_location_distribution": [("location", "VARCHAR"), ("patient_count", "BIGINT")],
            "visit_statistics": [("visit_date", "DATE"), ("visit_type", "VARCHAR"), ("visit_count", "BIGINT"), ("unique_patients", "BIGINT"), ("avg_duration_hours", "FLOAT")],
            "daily_census": [("census_date", "DATE"), ("inpatient_count", "BIGINT"), ("unique_patients", "BIGINT")],
            "encounter_types_distribution": [("encounter_type", "VARCHAR"), ("encounter_count", "BIGINT"), ("unique_patients", "BIGINT")],
            "hourly_visit_pattern": [("hour_of_day", "INTEGER"), ("visit_count", "BIGINT")],
            "lab_test_volume": [("test_date", "DATE"), ("test_name", "VARCHAR"), ("test_count", "BIGINT"), ("unique_patients", "BIGINT")],
            "lab_turnaround_time": [("order_date", "DATE"), ("test_name", "VARCHAR"), ("avg_tat_hours", "FLOAT")],
            "revenue_summary": [("invoice_date", "DATE"), ("total_revenue", "FLOAT"), ("invoice_count", "BIGINT"), ("unique_customers", "BIGINT"), ("avg_invoice_amount", "FLOAT")],
            "revenue_by_service": [("invoice_date", "DATE"), ("service_category", "VARCHAR"), ("revenue", "FLOAT"), ("invoice_count", "BIGINT")],
            "outstanding_invoices": [("aging_bucket", "VARCHAR"), ("invoice_count", "BIGINT"), ("outstanding_amount", "FLOAT")],
            "top_prescribed_drugs": [("drug_name", "VARCHAR"), ("prescription_count", "BIGINT"), ("unique_patients", "BIGINT")],
            "average_length_of_stay": [("admission_date", "DATE"), ("visit_type", "VARCHAR"), ("visit_count", "BIGINT"), ("avg_los_days", "FLOAT")],
            "bed_occupancy": [("occupancy_date", "DATE"), ("occupied_beds", "BIGINT"), ("occupancy_rate", "FLOAT")],
            "provider_productivity": [("provider_name", "VARCHAR"), ("encounter_count", "BIGINT"), ("unique_patients", "BIGINT")],
            "patient_registrations_daily": [("registration_date", "DATE"), ("patient_count", "BIGINT"), ("male_count", "BIGINT"), ("female_count", "BIGINT")],
            "visits_summary": [("visit_date", "DATE"), ("visit_type", "VARCHAR"), ("visit_count", "BIGINT"), ("unique_patients", "BIGINT")],
            "lab_tests_daily": [("test_date", "DATE"), ("test_name", "VARCHAR"), ("test_count", "BIGINT"), ("unique_patients", "BIGINT")],
            "daily_revenue": [("invoice_date", "DATE"), ("product_category", "VARCHAR"), ("revenue", "FLOAT"), ("invoice_count", "BIGINT")],
            "near_expiry_medicines": [("drug_name", "VARCHAR"), ("lot_number", "VARCHAR"), ("expiration_date", "DATE"), ("days_until_expiry", "INTEGER"), ("quantity", "FLOAT")],
            "low_stock_drugs": [("drug_name", "VARCHAR"), ("quantity_on_hand", "FLOAT")],
        }

        try:
            print("=" * 70)
            print("NidanEHR Comprehensive Hospital Dashboard Initialization")
            print("=" * 70)

            # Step 1: Create database connections
            print("\nCreating database connections...")
            databases = {}
            for key, config in DB_CONFIGS.items():
                existing = db.session.query(Database).filter_by(database_name=config["name"]).first()
                if existing:
                    print(f"  ✓ Database '{config['name']}' already exists")
                    if existing.allow_run_async:
                        existing.allow_run_async = False
                        db.session.commit()
                        print(f"    → Disabled async (no Celery workers)")
                    databases[key] = existing
                else:
                    database = Database(
                        database_name=config["name"],
                        sqlalchemy_uri=config["uri"],
                        expose_in_sqllab=True,
                        allow_run_async=False,  # No Celery workers - run queries synchronously
                        allow_ctas=False,
                        allow_cvas=False,
                        allow_dml=False,
                    )
                    db.session.add(database)
                    db.session.commit()
                    print(f"  ✓ Created database '{config['name']}'")
                    databases[key] = database

            # Step 2: Create datasets (with try/except for schema variations)
            print("\nCreating datasets...")
            datasets = {}

            def ensure_dataset_columns(dataset, table_name):
                """Ensure dataset has required columns (fixes 'Columns missing' when fetch_metadata fails)."""
                cols = DATASET_COLUMNS.get(table_name)
                if not cols:
                    return
                existing_names = {c.column_name for c in dataset.columns}
                missing = [(n, t) for n, t in cols if n not in existing_names]
                if not missing:
                    return
                for col_name, col_type in missing:
                    tc = TableColumn(column_name=col_name, type=col_type, table=dataset)
                    tc.is_dttm = col_type in ("DATE", "TIMESTAMP", "DATETIME")
                    db.session.add(tc)
                db.session.commit()
                print(f"    → Added {len(missing)} missing column(s) to '{table_name}'")

            def add_dataset(db_key, table_name, sql):
                database = databases.get(db_key)
                if not database:
                    return
                existing = db.session.query(SqlaTable).filter_by(table_name=table_name, database_id=database.id).first()
                if existing:
                    print(f"  ✓ Dataset '{table_name}' already exists")
                    # Update SQL when it differs (applies schema fixes: entered_date->entry_date, etc.)
                    new_sql = sql.strip()
                    if existing.sql != new_sql:
                        existing.sql = new_sql
                        db.session.commit()
                        print(f"    → Updated SQL")
                    ensure_dataset_columns(existing, table_name)
                    datasets[table_name] = existing
                    return
                try:
                    dataset = SqlaTable(
                        table_name=table_name,
                        sql=sql.strip(),
                        database_id=database.id,
                        database=database,
                        is_sqllab_view=False,
                    )
                    db.session.add(dataset)
                    db.session.commit()
                    try:
                        dataset.fetch_metadata()
                        db.session.commit()
                    except Exception:
                        pass
                    ensure_dataset_columns(dataset, table_name)
                    print(f"  ✓ Created dataset '{table_name}'")
                    datasets[table_name] = dataset
                except Exception as e:
                    print(f"  ✗ Failed '{table_name}': {e}")
                    db.session.rollback()

            # --- EXECUTIVE / PATIENT FLOW ---
            add_dataset("openmrs", "patient_registrations_trend", """
                SELECT DATE(p.date_created) as registration_date,
                    COUNT(DISTINCT p.patient_id) as patient_count,
                    COUNT(DISTINCT CASE WHEN pe.gender = 'M' THEN p.patient_id END) as male_count,
                    COUNT(DISTINCT CASE WHEN pe.gender = 'F' THEN p.patient_id END) as female_count
                FROM patient p
                JOIN person pe ON p.patient_id = pe.person_id
                WHERE p.voided = 0 AND p.date_created >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
                GROUP BY DATE(p.date_created) ORDER BY registration_date DESC
            """)
            add_dataset("openmrs", "patient_demographics", """
                SELECT CASE
                    WHEN TIMESTAMPDIFF(YEAR, pe.birthdate, CURDATE()) < 5 THEN '0-4'
                    WHEN TIMESTAMPDIFF(YEAR, pe.birthdate, CURDATE()) BETWEEN 5 AND 14 THEN '5-14'
                    WHEN TIMESTAMPDIFF(YEAR, pe.birthdate, CURDATE()) BETWEEN 15 AND 24 THEN '15-24'
                    WHEN TIMESTAMPDIFF(YEAR, pe.birthdate, CURDATE()) BETWEEN 25 AND 44 THEN '25-44'
                    WHEN TIMESTAMPDIFF(YEAR, pe.birthdate, CURDATE()) BETWEEN 45 AND 64 THEN '45-64'
                    ELSE '65+' END as age_group,
                    COALESCE(pe.gender, 'Unknown') as gender,
                    COUNT(DISTINCT p.patient_id) as patient_count
                FROM patient p JOIN person pe ON p.patient_id = pe.person_id
                WHERE p.voided = 0
                GROUP BY 1, COALESCE(pe.gender, 'Unknown') ORDER BY 1, 2
            """)
            add_dataset("openmrs", "patient_location_distribution", """
                SELECT COALESCE(pa.city_village, 'Unknown') as location,
                    COUNT(DISTINCT p.patient_id) as patient_count
                FROM patient p JOIN person pe ON p.patient_id = pe.person_id
                LEFT JOIN person_address pa ON pe.person_id = pa.person_id AND pa.voided = 0
                WHERE p.voided = 0
                GROUP BY pa.city_village ORDER BY patient_count DESC LIMIT 20
            """)

            # --- VISITS & ENCOUNTERS ---
            add_dataset("openmrs", "visit_statistics", """
                SELECT DATE(v.date_started) as visit_date,
                    COALESCE(vt.name, 'Unknown') as visit_type,
                    COUNT(DISTINCT v.visit_id) as visit_count,
                    COUNT(DISTINCT v.patient_id) as unique_patients,
                    AVG(TIMESTAMPDIFF(SECOND, v.date_started, COALESCE(v.date_stopped, NOW())) / 3600.0) as avg_duration_hours
                FROM visit v LEFT JOIN visit_type vt ON v.visit_type_id = vt.visit_type_id
                WHERE v.voided = 0 AND v.date_started >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
                GROUP BY DATE(v.date_started), COALESCE(vt.name, 'Unknown') ORDER BY visit_date DESC
            """)
            add_dataset("openmrs", "daily_census", """
                WITH RECURSIVE date_series AS (
                    SELECT DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) AS d
                    UNION ALL
                    SELECT DATE_ADD(d, INTERVAL 1 DAY) FROM date_series WHERE d < CURRENT_DATE
                )
                SELECT ds.d AS census_date,
                    COUNT(DISTINCT v.visit_id) AS inpatient_count,
                    COUNT(DISTINCT v.patient_id) AS unique_patients
                FROM date_series ds
                LEFT JOIN visit v ON DATE(v.date_started) <= ds.d
                    AND (v.date_stopped IS NULL OR DATE(v.date_stopped) >= ds.d) AND v.voided = 0
                GROUP BY ds.d ORDER BY census_date DESC
            """)
            add_dataset("openmrs", "encounter_types_distribution", """
                SELECT COALESCE(et.name, 'Unknown') as encounter_type,
                    COUNT(e.encounter_id) as encounter_count,
                    COUNT(DISTINCT e.patient_id) as unique_patients
                FROM encounter e LEFT JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
                WHERE e.voided = 0 AND e.encounter_datetime >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
                GROUP BY COALESCE(et.name, 'Unknown') ORDER BY encounter_count DESC
            """)
            add_dataset("openmrs", "hourly_visit_pattern", """
                SELECT HOUR(v.date_started) as hour_of_day,
                    COUNT(DISTINCT v.visit_id) as visit_count
                FROM visit v WHERE v.voided = 0 AND v.date_started >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
                GROUP BY 1 ORDER BY 1
            """)

            # --- LABORATORY ---
            add_dataset("openelis", "lab_test_volume", """
                SELECT DATE(a.entry_date) as test_date,
                    COALESCE(t.description, 'Unknown') as test_name,
                    COUNT(a.id) as test_count,
                    COUNT(DISTINCT sh.patient_id) as unique_patients
                FROM analysis a
                LEFT JOIN test t ON a.test_id = t.id
                LEFT JOIN sample_item si ON a.sampitem_id = si.id
                LEFT JOIN sample s ON si.samp_id = s.id
                LEFT JOIN sample_human sh ON s.id = sh.samp_id
                WHERE a.entry_date >= CURRENT_DATE - INTERVAL '90 days'
                GROUP BY DATE(a.entry_date), COALESCE(t.description, 'Unknown') ORDER BY test_date DESC
            """)
            add_dataset("openelis", "lab_turnaround_time", """
                SELECT DATE(a.entry_date) as order_date,
                    COALESCE(t.description, 'Unknown') as test_name,
                    ROUND(AVG(EXTRACT(EPOCH FROM (COALESCE(a.lastupdated, a.entry_date) - a.entry_date))/3600), 2) as avg_tat_hours
                FROM analysis a
                LEFT JOIN test t ON a.test_id = t.id
                WHERE a.entry_date >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY DATE(a.entry_date), COALESCE(t.description, 'Unknown') HAVING COUNT(a.id) >= 1
                ORDER BY order_date DESC
            """)

            # --- FINANCIAL ---
            add_dataset("odoo", "revenue_summary", """
                SELECT DATE(am.invoice_date) as invoice_date,
                    SUM(am.amount_total) as total_revenue,
                    COUNT(DISTINCT am.id) as invoice_count,
                    COUNT(DISTINCT am.partner_id) as unique_customers,
                    AVG(am.amount_total) as avg_invoice_amount
                FROM account_move am
                WHERE am.move_type = 'out_invoice' AND am.state = 'posted'
                    AND am.invoice_date >= CURRENT_DATE - INTERVAL '90 days'
                GROUP BY DATE(am.invoice_date) ORDER BY invoice_date DESC
            """)
            add_dataset("odoo", "revenue_by_service", """
                SELECT DATE(am.invoice_date) as invoice_date,
                    COALESCE(pt.name->>'en_US', pt.name->>'en', 'Other') as service_category,
                    SUM(aml.price_subtotal) as revenue,
                    COUNT(DISTINCT am.id) as invoice_count
                FROM account_move am JOIN account_move_line aml ON am.id = aml.move_id
                LEFT JOIN product_product pp ON aml.product_id = pp.id
                LEFT JOIN product_template pt ON pp.product_tmpl_id = pt.id
                WHERE am.move_type = 'out_invoice' AND am.state = 'posted'
                    AND am.invoice_date >= CURRENT_DATE - INTERVAL '90 days'
                GROUP BY DATE(am.invoice_date), COALESCE(pt.name->>'en_US', pt.name->>'en', 'Other') ORDER BY invoice_date DESC
            """)
            add_dataset("odoo", "outstanding_invoices", """
                SELECT CASE
                    WHEN CURRENT_DATE - am.invoice_date <= 30 THEN '0-30 days'
                    WHEN CURRENT_DATE - am.invoice_date <= 60 THEN '31-60 days'
                    WHEN CURRENT_DATE - am.invoice_date <= 90 THEN '61-90 days'
                    ELSE '90+ days' END as aging_bucket,
                    COUNT(am.id) as invoice_count, SUM(am.amount_residual) as outstanding_amount
                FROM account_move am
                WHERE am.move_type = 'out_invoice' AND am.state = 'posted' AND am.payment_state != 'paid'
                GROUP BY 1 ORDER BY 1
            """)

            # --- PHARMACY (OpenMRS orders) ---
            add_dataset("openmrs", "top_prescribed_drugs", """
                SELECT COALESCE(cn.name, 'Unknown') as drug_name,
                    COUNT(o.order_id) as prescription_count,
                    COUNT(DISTINCT o.patient_id) as unique_patients
                FROM orders o
                JOIN drug_order dord ON o.order_id = dord.order_id
                LEFT JOIN drug d ON dord.drug_inventory_id = d.drug_id
                LEFT JOIN concept_name cn ON d.concept_id = cn.concept_id AND cn.locale = 'en' AND cn.concept_name_type = 'FULLY_SPECIFIED'
                WHERE o.voided = 0 AND o.date_activated >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
                GROUP BY COALESCE(cn.name, 'Unknown') ORDER BY prescription_count DESC LIMIT 20
            """)

            # --- QUALITY METRICS ---
            add_dataset("openmrs", "average_length_of_stay", """
                SELECT DATE(v.date_started) as admission_date,
                    COALESCE(vt.name, 'Unknown') as visit_type,
                    COUNT(v.visit_id) as visit_count,
                    ROUND(AVG(TIMESTAMPDIFF(SECOND, v.date_started, v.date_stopped) / 86400.0), 2) as avg_los_days
                FROM visit v LEFT JOIN visit_type vt ON v.visit_type_id = vt.visit_type_id
                WHERE v.voided = 0 AND v.date_stopped IS NOT NULL
                    AND v.date_started >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
                GROUP BY DATE(v.date_started), COALESCE(vt.name, 'Unknown') ORDER BY admission_date DESC
            """)
            add_dataset("openmrs", "bed_occupancy", """
                WITH RECURSIVE date_series AS (
                    SELECT DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) AS d
                    UNION ALL
                    SELECT DATE_ADD(d, INTERVAL 1 DAY) FROM date_series WHERE d < CURRENT_DATE
                )
                SELECT ds.d AS occupancy_date,
                    COUNT(DISTINCT v.visit_id) AS occupied_beds,
                    ROUND(COUNT(DISTINCT v.visit_id) * 100.0 / NULLIF(50, 0), 2) AS occupancy_rate
                FROM date_series ds
                LEFT JOIN visit v ON DATE(v.date_started) <= ds.d
                    AND (v.date_stopped IS NULL OR DATE(v.date_stopped) >= ds.d) AND v.voided = 0
                GROUP BY ds.d ORDER BY occupancy_date DESC
            """)

            # --- PROVIDER PRODUCTIVITY ---
            add_dataset("openmrs", "provider_productivity", """
                SELECT COALESCE(NULLIF(TRIM(CONCAT(COALESCE(pn.given_name, ''), ' ', COALESCE(pn.family_name, ''))), ''), 'Unknown') as provider_name,
                    COUNT(DISTINCT e.encounter_id) as encounter_count,
                    COUNT(DISTINCT e.patient_id) as unique_patients
                FROM encounter e
                JOIN encounter_provider ep ON e.encounter_id = ep.encounter_id AND (ep.voided = 0 OR ep.voided IS NULL)
                LEFT JOIN provider p ON ep.provider_id = p.provider_id
                LEFT JOIN person_name pn ON p.person_id = pn.person_id AND pn.voided = 0
                WHERE e.voided = 0 AND e.encounter_datetime >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
                GROUP BY pn.given_name, pn.family_name ORDER BY encounter_count DESC
            """)

            # --- SIMPLER DATASETS (for fallback) ---
            add_dataset("openmrs", "patient_registrations_daily", """
                SELECT DATE(p.date_created) as registration_date,
                    COUNT(DISTINCT p.patient_id) as patient_count,
                    COUNT(DISTINCT CASE WHEN pe.gender = 'M' THEN p.patient_id END) as male_count,
                    COUNT(DISTINCT CASE WHEN pe.gender = 'F' THEN p.patient_id END) as female_count
                FROM patient p JOIN person pe ON p.patient_id = pe.person_id
                WHERE p.voided = 0 AND p.date_created >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
                GROUP BY DATE(p.date_created) ORDER BY registration_date DESC
            """)
            add_dataset("openmrs", "visits_summary", """
                SELECT DATE(v.date_started) as visit_date,
                    COALESCE(vt.name, 'Unknown') as visit_type,
                    COUNT(DISTINCT v.visit_id) as visit_count,
                    COUNT(DISTINCT v.patient_id) as unique_patients
                FROM visit v LEFT JOIN visit_type vt ON v.visit_type_id = vt.visit_type_id
                WHERE v.voided = 0 AND v.date_started >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
                GROUP BY DATE(v.date_started), COALESCE(vt.name, 'Unknown') ORDER BY visit_date DESC
            """)
            add_dataset("openelis", "lab_tests_daily", """
                SELECT DATE(a.entry_date) as test_date,
                    COALESCE(t.description, 'Unknown') as test_name,
                    COUNT(a.id) as test_count,
                    COUNT(DISTINCT sh.patient_id) as unique_patients
                FROM analysis a
                LEFT JOIN test t ON a.test_id = t.id
                LEFT JOIN sample_item si ON a.sampitem_id = si.id
                LEFT JOIN sample s ON si.samp_id = s.id
                LEFT JOIN sample_human sh ON s.id = sh.samp_id
                WHERE a.entry_date >= CURRENT_DATE - INTERVAL '90 days'
                GROUP BY DATE(a.entry_date), COALESCE(t.description, 'Unknown') ORDER BY test_date DESC
            """)
            add_dataset("odoo", "daily_revenue", """
                SELECT DATE(am.invoice_date) as invoice_date,
                    COALESCE(pt.name->>'en_US', pt.name->>'en', 'Other') as product_category,
                    SUM(aml.price_subtotal) as revenue,
                    COUNT(DISTINCT am.id) as invoice_count
                FROM account_move am JOIN account_move_line aml ON am.id = aml.move_id
                LEFT JOIN product_product pp ON aml.product_id = pp.id
                LEFT JOIN product_template pt ON pp.product_tmpl_id = pt.id
                WHERE am.move_type = 'out_invoice' AND am.state = 'posted'
                    AND am.invoice_date >= CURRENT_DATE - INTERVAL '90 days'
                GROUP BY DATE(am.invoice_date), COALESCE(pt.name->>'en_US', pt.name->>'en', 'Other') ORDER BY invoice_date DESC
            """)

            # --- PHARMACY (Odoo stock) ---
            # Near expiry: requires product_expiry module for expiration_date. Without it, shows drugs with lots (no expiry).
            add_dataset("odoo", "near_expiry_medicines", """
                SELECT COALESCE(pt.name->>'en_US', pt.name->>'en', 'Unknown') as drug_name,
                    sl.name as lot_number,
                    NULL::date as expiration_date,
                    NULL::int as days_until_expiry,
                    SUM(sq.quantity) as quantity
                FROM stock_quant sq
                JOIN stock_lot sl ON sq.lot_id = sl.id
                JOIN product_product pp ON sq.product_id = pp.id
                JOIN product_template pt ON pp.product_tmpl_id = pt.id
                JOIN stock_location loc ON sq.location_id = loc.id
                WHERE pt.clinical_product_type = 'drug'
                    AND loc.usage = 'internal'
                    AND sq.quantity > 0
                GROUP BY pt.id, pt.name, sl.name
                ORDER BY drug_name, sl.name
            """)
            add_dataset("odoo", "low_stock_drugs", """
                SELECT COALESCE(pt.name->>'en_US', pt.name->>'en', 'Unknown') as drug_name,
                    SUM(sq.quantity) as quantity_on_hand
                FROM stock_quant sq
                JOIN product_product pp ON sq.product_id = pp.id
                JOIN product_template pt ON pp.product_tmpl_id = pt.id
                JOIN stock_location loc ON sq.location_id = loc.id
                WHERE pt.clinical_product_type = 'drug'
                    AND loc.usage = 'internal'
                GROUP BY pt.id, pt.name
                HAVING SUM(sq.quantity) < 20
                ORDER BY quantity_on_hand ASC
            """)

            # Step 3: Create charts
            print("\nCreating charts...")
            charts = {}

            def add_chart(table_name, slice_name, viz_type, params):
                dataset = datasets.get(table_name)
                if not dataset:
                    return None
                    
                # Auto-upgrade legacy charts to modern ECharts
                if viz_type in ("bar", "dist_bar"):
                    viz_type = "echarts_timeseries_bar"
                    if "groupby" in params and params["groupby"]:
                        params["x_axis"] = params["groupby"][0]
                        params["groupby"] = []
                elif viz_type in ("pie", "echarts_pie"):
                    viz_type = "pie"
                    # ECharts pie uses 'metric' (singular object) instead of 'metrics' (array)
                    if "metrics" in params and isinstance(params["metrics"], list) and len(params["metrics"]) > 0:
                        params["metric"] = params["metrics"][0]
                        del params["metrics"]
                    
                existing = db.session.query(Slice).filter_by(slice_name=slice_name, datasource_id=dataset.id).first()
                if existing:
                    print(f"  ✓ Chart '{slice_name}' already exists")
                    needs_update = False
                    
                    if existing.viz_type != viz_type or existing.viz_type in ("bar", "dist_bar", "pie"):
                        existing.viz_type = viz_type
                        needs_update = True
                        
                    current_params = existing.params or "{}"
                    try:
                        if json.loads(current_params) != params:
                            existing.params = json.dumps(params)
                            needs_update = True
                    except Exception:
                        existing.params = json.dumps(params)
                        needs_update = True
                        
                    if needs_update:
                        db.session.commit()
                        print(f"    → Updated chart to {viz_type} and applied params")
                        
                    charts[slice_name] = existing
                    return existing
                try:
                    slice_obj = Slice(
                        slice_name=slice_name,
                        datasource_id=dataset.id,
                        datasource_type="table",
                        viz_type=viz_type,
                        params=json.dumps(params),
                    )
                    db.session.add(slice_obj)
                    db.session.commit()
                    print(f"  ✓ Created chart '{slice_name}'")
                    charts[slice_name] = slice_obj
                    return slice_obj
                except Exception as e:
                    print(f"  ✗ Failed chart '{slice_name}': {e}")
                    db.session.rollback()
                    return None

            base_params = {"time_range": "Last 30 days"}
            add_chart("patient_registrations_trend", "Daily Patient Registrations", "echarts_timeseries", {
                **base_params, "granularity_sqla": "registration_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "patient_count"}, "aggregate": "SUM", "label": "Patients"}],
                "groupby": [],
            })
            add_chart("patient_demographics", "Patient Gender Distribution", "pie", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "patient_count"}, "aggregate": "SUM", "label": "Count"}],
                "groupby": ["gender"],
                "adhoc_filters": [],
                "row_limit": 10000,
                "show_legend": True,
                "legend_type": "scroll",
            })
            add_chart("patient_demographics", "Patient Age Distribution", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "patient_count"}, "aggregate": "SUM", "label": "Count"}],
                "groupby": ["age_group"],
                "adhoc_filters": [],
                "row_limit": 10000,
            })
            add_chart("patient_location_distribution", "Geographic Distribution", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "patient_count"}, "aggregate": "SUM", "label": "Count"}],
                "groupby": ["location"],
            })
            add_chart("visit_statistics", "Visits by Type", "pie", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "visit_count"}, "aggregate": "SUM", "label": "Visits"}],
                "groupby": ["visit_type"],
            })
            add_chart("daily_census", "Inpatient Census Trend", "echarts_timeseries", {
                **base_params, "granularity_sqla": "census_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "inpatient_count"}, "aggregate": "SUM", "label": "Patients"}],
                "groupby": [],
            })
            add_chart("encounter_types_distribution", "Encounter Types", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "encounter_count"}, "aggregate": "SUM", "label": "Count"}],
                "groupby": ["encounter_type"],
            })
            add_chart("hourly_visit_pattern", "Hourly Visit Pattern", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "visit_count"}, "aggregate": "SUM", "label": "Visits"}],
                "groupby": ["hour_of_day"],
            })
            add_chart("lab_test_volume", "Lab Test Volume Trend", "echarts_timeseries", {
                **base_params, "granularity_sqla": "test_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "test_count"}, "aggregate": "SUM", "label": "Tests"}],
                "groupby": ["test_name"],
            })
            add_chart("lab_turnaround_time", "Lab Turnaround Time", "echarts_timeseries", {
                **base_params, "granularity_sqla": "order_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "avg_tat_hours"}, "aggregate": "AVG", "label": "Hours"}],
                "groupby": ["test_name"],
            })
            add_chart("revenue_summary", "Daily Revenue Trend", "echarts_timeseries", {
                **base_params, "granularity_sqla": "invoice_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "total_revenue"}, "aggregate": "SUM", "label": "Revenue"}],
                "groupby": [],
            })
            add_chart("revenue_by_service", "Revenue by Service", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "revenue"}, "aggregate": "SUM", "label": "Revenue"}],
                "groupby": ["service_category"],
            })
            add_chart("outstanding_invoices", "Outstanding Invoices Aging", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "outstanding_amount"}, "aggregate": "SUM", "label": "Amount"}],
                "groupby": ["aging_bucket"],
            })
            add_chart("top_prescribed_drugs", "Top Prescribed Drugs", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "prescription_count"}, "aggregate": "SUM", "label": "Count"}],
                "groupby": ["drug_name"],
            })
            add_chart("near_expiry_medicines", "Near Expiry Medicines", "table", {
                "all_columns": ["drug_name", "lot_number", "expiration_date", "days_until_expiry", "quantity"],
                "row_limit": 50,
            })
            add_chart("low_stock_drugs", "Low Stock Drugs", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "quantity_on_hand"}, "aggregate": "SUM", "label": "Qty"}],
                "groupby": ["drug_name"],
            })
            add_chart("average_length_of_stay", "Average Length of Stay", "echarts_timeseries", {
                **base_params, "granularity_sqla": "admission_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "avg_los_days"}, "aggregate": "AVG", "label": "Days"}],
                "groupby": ["visit_type"],
            })
            add_chart("bed_occupancy", "Bed Occupancy Rate", "echarts_timeseries", {
                **base_params, "granularity_sqla": "occupancy_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "occupancy_rate"}, "aggregate": "AVG", "label": "Rate"}],
                "groupby": [],
            })
            add_chart("provider_productivity", "Provider Productivity", "dist_bar", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "encounter_count"}, "aggregate": "SUM", "label": "Encounters"}],
                "groupby": ["provider_name"],
            })
            # Fallback charts for simpler datasets
            add_chart("patient_registrations_daily", "Patient Registrations (Daily)", "echarts_timeseries", {
                **base_params, "granularity_sqla": "registration_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "patient_count"}, "aggregate": "SUM", "label": "Patients"}],
                "groupby": [],
            })
            add_chart("visits_summary", "Visits Summary", "pie", {
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "visit_count"}, "aggregate": "SUM", "label": "Visits"}],
                "groupby": ["visit_type"],
            })
            add_chart("lab_tests_daily", "Lab Tests Daily", "echarts_timeseries", {
                **base_params, "granularity_sqla": "test_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "test_count"}, "aggregate": "SUM", "label": "Tests"}],
                "groupby": ["test_name"],
            })
            add_chart("daily_revenue", "Daily Revenue", "echarts_timeseries", {
                **base_params, "granularity_sqla": "invoice_date",
                "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "revenue"}, "aggregate": "SUM", "label": "Revenue"}],
                "groupby": [],
            })

            # Step 4: Create dashboards
            print("\nCreating dashboards...")

            def create_dashboard(title, chart_names):
                existing = db.session.query(Dashboard).filter_by(dashboard_title=title).first()
                if existing:
                    print(f"  ✓ Dashboard '{title}' already exists")
                    # Add any new charts that aren't on the dashboard yet
                    existing_slice_ids = {s.id for s in existing.slices}
                    added = 0
                    for name in chart_names:
                        if name in charts and charts[name] and charts[name].id not in existing_slice_ids:
                            existing.slices.append(charts[name])
                            added += 1
                    if added:
                        db.session.commit()
                        print(f"    → Added {added} new chart(s)")
                    return existing
                dashboard = Dashboard(dashboard_title=title, slug=title.lower().replace(" ", "-").replace("'", "")[:50], position_json="{}", published=True)
                db.session.add(dashboard)
                db.session.flush()
                for name in chart_names:
                    if name in charts and charts[name]:
                        dashboard.slices.append(charts[name])
                db.session.commit()
                print(f"  ✓ Created dashboard '{title}'")
                return dashboard

            create_dashboard("NidanEHR - Executive Dashboard", [
                "Daily Patient Registrations", "Daily Revenue Trend", "Inpatient Census Trend",
                "Visits by Type", "Lab Test Volume Trend", "Patient Gender Distribution",
            ])
            create_dashboard("NidanEHR - Clinical Operations", [
                "Encounter Types", "Provider Productivity", "Average Length of Stay",
                "Visits Summary", "Patient Age Distribution", "Hourly Visit Pattern",
            ])
            create_dashboard("NidanEHR - Financial Performance", [
                "Daily Revenue Trend", "Revenue by Service", "Outstanding Invoices Aging",
                "Daily Revenue",
            ])
            create_dashboard("NidanEHR - Laboratory Analytics", [
                "Lab Test Volume Trend", "Lab Turnaround Time", "Lab Tests Daily",
            ])
            create_dashboard("NidanEHR - Pharmacy Management", [
                "Top Prescribed Drugs",
                "Near Expiry Medicines",
                "Low Stock Drugs",
            ])
            create_dashboard("NidanEHR - Quality Metrics", [
                "Average Length of Stay", "Bed Occupancy Rate",
            ])
            create_dashboard("NidanEHR - Public Health", [
                "Geographic Distribution", "Patient Gender Distribution", "Patient Age Distribution",
            ])

            print("\n" + "=" * 70)
            print("✅ Initialization complete!")
            print("=" * 70)
            print("\nAccess: http://localhost/superset/")
            print("Dashboard: http://localhost/superset/dashboard/list/")

        except Exception as e:
            print(f"\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)


if __name__ == "__main__":
    main()
