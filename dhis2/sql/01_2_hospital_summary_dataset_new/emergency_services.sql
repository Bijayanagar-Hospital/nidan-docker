-- ==============================================================
-- Dataset : 01-2 Hospital Summary Dataset (NEW)
-- Group   : Emergency Services
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS v_59_years_f,  -- Clients Received Emergency Services- Age Group  20-59 Years / Female
  NULL AS v_59_years_m,  -- Clients Received Emergency Services- Age Group  20-59 Years / Male
  NULL AS age_group_60_years_f,  -- Clients Received Emergency Services- Age Group  ≥60 Years / Female
  NULL AS age_group_60_years_m,  -- Clients Received Emergency Services- Age Group  ≥60 Years / Male
  NULL AS age_group_70_years_f,  -- Clients Received Emergency Services- Age Group  ≥70 Years / Female
  NULL AS age_group_70_years_m,  -- Clients Received Emergency Services- Age Group  ≥70 Years / Male
  NULL AS v_19_years_f,  -- Clients Received Emergency Services- Age Group  15-19 Years / Female
  NULL AS v_19_years_m,  -- Clients Received Emergency Services- Age Group  15-19 Years / Male
  NULL AS v_9_years_f,  -- Clients Received Emergency Services- Age Group  0-9 Years / Female
  NULL AS v_9_years_m,  -- Clients Received Emergency Services- Age Group  0-9 Years / Male
  NULL AS v_14_years_f,  -- Clients Received Emergency Services- Age Group  10-14 Years / Female
  NULL AS v_14_years_m,  -- Clients Received Emergency Services- Age Group  10-14 Years / Male
  NULL AS v_19_years_f_2,  -- Clients Received Emergency Services- Age Group  10-19 Years / Female
  NULL AS v_19_years_m_2,  -- Clients Received Emergency Services- Age Group  10-19 Years / Male
  NULL AS age_group_60_to_69_years_f,  -- Clients Received Emergency Services- Age Group 60 to 69 Years / Female
  NULL AS age_group_60_to_69_years_m,  -- Clients Received Emergency Services- Age Group 60 to 69 Years / Male
  NULL AS emergency_patients_referred_out_from_t_f,  -- Emergency Patients Referred Out from the Hospital / Female
  NULL AS emergency_patients_referred_out_from_t_m   -- Emergency Patients Referred Out from the Hospital / Male

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
