-- ==============================================================
-- Dataset : 01-3 Hospital Indoor Service (NEW)
-- Group   : Referrals
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS fchvs_received_free_health_services_at_r,  -- FCHVs Received Free Health Services at Referred Out
  NULL AS disabled_patients_received_free_health_s   -- Disabled Patients Received Free Health Services at Referred Out

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
