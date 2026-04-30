-- ==============================================================
-- Dataset : 01-3 Hospital Indoor Service (NEW)
-- Group   : Diagnostic Services
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS post_operative_infection_in_major_surger,  -- Post Operative Infection in Major Surgeries at Emergency
  NULL AS cases_of_post_operative_infection_report,  -- Cases of Post Operative Infection Reported in Outpatient Minor Surgeries
  NULL AS cases_of_post_operative_infection_report_2,  -- Cases of Post Operative Infection Reported in Emergency Minor Surgeries
  NULL AS post_operative_infection_in_major_surger_2   -- Post Operative Infection in Major Surgeries at IPD

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
