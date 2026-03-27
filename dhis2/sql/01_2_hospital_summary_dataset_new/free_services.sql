-- ==============================================================
-- Dataset : 01-2 Hospital Summary Dataset (NEW)
-- Group   : Free Services (Ultra Poor)
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions

SELECT
  NULL AS upprfs_kidney_ailments_f,  -- Ultra Poor Patients Received Free Services for Kidney Ailments / Female
  NULL AS upprfs_kidney_ailments_m,  -- Ultra Poor Patients Received Free Services for Kidney Ailments / Male
  NULL AS upprfs_cancer_treatment_f,  -- Ultra Poor PatientsReceived Free Services  for Cancer Treatment / Female
  NULL AS upprfs_cancer_treatment_m,  -- Ultra Poor PatientsReceived Free Services  for Cancer Treatment / Male
  NULL AS upprfs_head_injury_f,  -- Ultra Poor Patients Received Free Services for Head Injury / Female
  NULL AS upprfs_head_injury_m,  -- Ultra Poor Patients Received Free Services for Head Injury / Male
  NULL AS upprfs_heart_ailments_f,  -- Ultra Poor Patients Received Free Services for Heart Ailments / Female
  NULL AS upprfs_heart_ailments_m,  -- Ultra Poor Patients Received Free Services for Heart Ailments / Male
  NULL AS upprfs_sickle_cell_anaemia_f,  -- Ultra Poor Patients Received Free Services for Sickle Cell Anaemia / Female
  NULL AS upprfs_sickle_cell_anaemia_m,  -- Ultra Poor Patients Received Free Services for Sickle Cell Anaemia / Male
  NULL AS upprfs_alzheimer_parkinson_disease_f,  -- Ultra Poor Patients Received Free Services for Alzheimer/Parkinson Disease / Female
  NULL AS upprfs_alzheimer_parkinson_disease_m,  -- Ultra Poor Patients Received Free Services for Alzheimer/Parkinson Disease / Male
  NULL AS upprfs_parkinson_f,  -- Ultra Poor Patients Received Free Services for Parkinson / Female
  NULL AS upprfs_parkinson_m,  -- Ultra Poor Patients Received Free Services for Parkinson / Male
  NULL AS upprfs_spinal_and_head_injury_f,  -- Ultra Poor Patients Received Free Services for Spinal and Head Injury / Female
  NULL AS upprfs_spinal_and_head_injury_m   -- Ultra Poor Patients Received Free Services for Spinal and Head Injury / Male

FROM
  -- TODO: replace with your actual source table(s)
  encounter e
  JOIN encounter_type et ON et.encounter_type_id = e.encounter_type

WHERE
  e.encounter_datetime BETWEEN :start_date AND :end_date
  AND e.voided = 0
