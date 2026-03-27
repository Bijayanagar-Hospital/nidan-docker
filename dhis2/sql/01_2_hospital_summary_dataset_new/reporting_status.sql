-- ==============================================================
-- Dataset : 01-2 Hospital Summary Dataset (NEW)
-- Group   : Reporting Status
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS score,  -- Reporting Status-MSS-Score
  NULL AS implementation   -- Reporting Status-MSS-Implementation

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
