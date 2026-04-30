-- ==============================================================
-- Dataset : 01-3 Hospital Indoor Service (NEW)
-- Group   : ORC Clinics / Immunization / FCHV
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS frfhs_emergency,  -- FCHVs Received Free Health Services in Emergency
  NULL AS frfhs_opd,  -- FCHVs Received Free Health Services in OPD
  NULL AS frfhs_ipd   -- FCHVs Received Free Health Services in IPD

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
