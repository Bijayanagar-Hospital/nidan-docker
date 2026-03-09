# NidanEHR Superset Configuration

## Comprehensive Hospital Dashboard

7 dashboards covering all critical hospital operations:

| Dashboard | Charts |
|-----------|--------|
| **Executive** | KPIs, Patient Registrations, Revenue, Census, Visits, Lab Volume |
| **Clinical Operations** | Encounters, Provider Productivity, Length of Stay, Visits, Demographics |
| **Financial Performance** | Revenue Trend, Revenue by Service, Outstanding Invoices |
| **Laboratory Analytics** | Lab Volume, Turnaround Time |
| **Pharmacy Management** | Top Prescribed Drugs |
| **Quality Metrics** | Length of Stay, Bed Occupancy |
| **Public Health** | Geographic Distribution, Demographics |

## Structure

```
superset/
├── superset_config.py          # Flask/Superset config
├── init_superset_metadata.py   # Creates DBs, datasets, charts, dashboards at startup
├── init_metadata.sh            # Standalone init script (optional)
├── docker-entrypoint.sh        # Container entrypoint
└── metadata/                   # YAML definitions (reference)
    ├── databases/
    ├── datasets/
    ├── charts/
    └── dashboards/
```

## Database Connections (from env vars)

| Database | Env vars |
|----------|----------|
| OpenMRS  | `OPENMRS_DB_HOST`, `OPENMRS_DB_PORT`, `OPENMRS_DB_NAME`, `OPENMRS_DB_USER`, `OPENMRS_DB_PASSWORD` |
| OpenELIS | `OPENELIS_DB_HOST`, `OPENELIS_DB_PORT`, `OPENELIS_DB_NAME`, `OPENELIS_DB_USER`, `OPENELIS_DB_PASSWORD` |
| Odoo     | `ODOO_DB_HOST`, `ODOO_DB_PORT`, `ODOO_DB_NAME`, `ODOO_DB_USER`, `ODOO_DB_PASSWORD` |

## Datasets (20+ virtual tables)

**Patient Flow:** patient_registrations_trend, patient_demographics, patient_location_distribution  
**Visits:** visit_statistics, daily_census, encounter_types_distribution, hourly_visit_pattern  
**Lab:** lab_test_volume, lab_turnaround_time, lab_tests_daily  
**Finance:** revenue_summary, revenue_by_service, outstanding_invoices, daily_revenue  
**Pharmacy:** top_prescribed_drugs  
**Quality:** average_length_of_stay, bed_occupancy  
**Staff:** provider_productivity  

## Access

- **URL**: http://localhost/superset/
- **Dashboards**: http://localhost/superset/dashboard/list/
- **SQL Lab**: http://localhost/superset/sqllab/
