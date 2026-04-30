-- ==============================================================
-- Dataset : 01-3 Hospital Indoor Service (NEW)
-- Group   : Free Services (Ultra Poor)
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS upppprfhs_ipd,  -- Ultra Poor Patients/ Poor Patients Received Free Health Services in IPD
  NULL AS upppprfhs_opd,  -- Ultra Poor Patients/ Poor Patients Received Free Health Services in OPD
  NULL AS upppprfhs_emergency,  -- Ultra Poor Patients/ Poor Patients Received Free Health Services in Emergency
  NULL AS upppprfhs_referral_out   -- Ultra Poor Patients/ Poor Patients Received Free Health Services at Referral Out

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
