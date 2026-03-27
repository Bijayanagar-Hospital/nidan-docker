-- ==============================================================
-- Dataset : 01-2 Hospital Summary Dataset (NEW)
-- Group   : ORC Clinics / Immunization / FCHV
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS total_fchvs_within_catchment_area,  -- Total FCHVs within Catchment Area
  NULL AS people_served,  -- Health Facilities within Catchment Area-FCHVs-People Served
  NULL AS people_served_from_immunization_clinic,  -- People Served from Immunization Clinic
  NULL AS people_served_2,  -- Health Facilities within Catchment Area-Outreach Clinics-People Served
  NULL AS people_benefitted_from_hygiene_session,  -- Immunization-People benefitted from hygiene session
  NULL AS hygiene_sessions_planned,  -- Immunization-Hygiene sessions planned
  NULL AS hygiene_sessions_conducted,  -- Immunization-Hygiene sessions conducted
  NULL AS planned,  -- Health Facilities within Catchment Area-Immunization Sessions-Planned
  NULL AS conducted,  -- Health Facilities within Catchment Area-Outreach Clinics-Conducted
  NULL AS planned_2,  -- Health Facilities within Catchment Area-Immunization Clinics-Planned
  NULL AS total_no_of_fchvs_report_submitted,  -- Total no.of FCHVs Report submitted
  NULL AS conducted_2,  -- Health Facilities within Catchment Area-Immunization Clinics-Conducted
  NULL AS conducted_3,  -- Health Facilities within Catchment Area-Immunization Sessions-Conducted
  NULL AS planned_3   -- Health Facilities within Catchment Area-Outreach Clinics-Planned

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
