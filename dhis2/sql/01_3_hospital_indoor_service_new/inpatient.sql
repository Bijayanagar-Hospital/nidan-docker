-- ==============================================================
-- Dataset : 01-3 Hospital Indoor Service (NEW)
-- Group   : Inpatient
-- Params  : :start_date  :end_date
-- ==============================================================
-- TODO: Replace NULL with actual SQL expressions
WITH real_data AS (
  SELECT
CASE
WHEN cn1.name IN ('Referred out', 'Referred on request') THEN 'Referred out'
WHEN cn1.name IN ('DOR', 'LAMA/DAMA') THEN 'DOPR/LAMA'
ELSE cn1.name
END AS outcome_name,

p.gender,

CASE
WHEN TIMESTAMPDIFF(DAY, p.birthdate, o.obs_datetime) BETWEEN 0 AND 7
THEN '0-7 days'
WHEN TIMESTAMPDIFF(DAY, p.birthdate, o.obs_datetime) BETWEEN 8 AND 28
THEN '8-28 days'
WHEN TIMESTAMPDIFF(DAY, p.birthdate, o.obs_datetime) BETWEEN 29 AND 365
THEN '29 Days - 1 Year'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 1 AND 4
THEN '01 - 04 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 5 AND 14
THEN '05 - 14 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 15 AND 19
THEN '15 - 19 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 20 AND 29
THEN '20 - 29 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 30 AND 39
THEN '30 - 39 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 40 AND 49
THEN '40 - 49 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 50 AND 59
THEN '50 - 59 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 60 AND 69
THEN '60 - 69 Years'
WHEN TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) >= 70
THEN '≥ 70 Years'
END AS age_group

FROM openmrs.obs o

INNER JOIN openmrs.concept_name cn
ON o.concept_id = cn.concept_id
AND cn.concept_name_type = 'FULLY_SPECIFIED'
AND cn.name = 'Inpatient Outcome'

INNER JOIN openmrs.concept_name cn1
ON o.value_coded = cn1.concept_id
AND cn1.concept_name_type = 'FULLY_SPECIFIED'

INNER JOIN openmrs.person p
ON o.person_id = p.person_id

WHERE
o.obs_datetime >= :start_date
AND o.obs_datetime <= :end_date
AND cn1.name IN (
'Recovered',
'Not improved',
'DOR',
'LAMA/DAMA',
'Absconded',
'Referred out',
'Referred on request',
'Death<48 hours',
'Death>48 hours'
)
AND p.gender IN ('M', 'F')
AND p.birthdate IS NOT NULL
AND o.obs_datetime IS NOT NULL
AND o.voided = 0
AND p.voided = 0
)

SELECT
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '0-7 days' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_0_7_days_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '0-7 days' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_0_7_days_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '8-28 days' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_8_28_days_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '8-28 days' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_8_28_days_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '29 Days - 1 Year' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_29_days_to_1_year_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '29 Days - 1 Year' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_29_days_to_1_year_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '01 - 04 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_01_04_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '01 - 04 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_01_04_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '05 - 14 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_05_14_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '05 - 14 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS v_14_years_m_4,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '15 - 19 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_15_19_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '15 - 19 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_15_19_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '20 - 29 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_20_29_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '20 - 29 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_20_29_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '30 - 39 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_30_39_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '30 - 39 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_30_39_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '40 - 49 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_40_49_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '40 - 49 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_40_49_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '50 - 59 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_50_59_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '50 - 59 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_50_59_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '60 - 69 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_60_69_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '60 - 69 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_60_69_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '≥ 70 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS recovered_70_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Recovered' AND age_group = '≥ 70 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS recovered_70_years_m,



COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '0-7 days' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_0_7_days_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '0-7 days' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_0_7_days_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '8-28 days' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_8_28_days_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '8-28 days' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_8_28_days_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '29 Days - 1 Year' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_29_days_to_1_year_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '29 Days - 1 Year' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_29_days_to_1_year_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '01 - 04 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_01_04_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '01 - 04 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_01_04_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '05 - 14 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_05_14_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '05 - 14 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_05_14_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '15 - 19 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_15_19_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '15 - 19 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_15_19_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '20 - 29 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_20_29_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '20 - 29 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_20_29_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '30 - 39 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_30_39_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '30 - 39 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_30_39_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '40 - 49 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_40_49_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '40 - 49 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_40_49_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '50 - 59 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_50_59_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '50 - 59 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_50_59_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '60 - 69 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_60_69_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '60 - 69 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_60_69_years_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '≥ 70 Years' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS not_improved_70_years_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Not improved' AND age_group = '≥ 70 Years' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS not_improved_70_years_m,



COALESCE(SUM(CASE WHEN outcome_name = 'Referred out' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS referred_out_total_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Referred out' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS referred_out_total_m,

COALESCE(SUM(CASE WHEN outcome_name = 'DOPR/LAMA' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS dopr_lama_total_f,
COALESCE(SUM(CASE WHEN outcome_name = 'DOPR/LAMA' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS dopr_lama_total_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Absconded' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS absconded_total_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Absconded' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS absconded_total_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Death<48 hours' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS death_less_48_total_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Death<48 hours' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS death_less_48_total_m,

COALESCE(SUM(CASE WHEN outcome_name = 'Death>48 hours' AND gender = 'F' THEN 1 ELSE 0 END), 0) AS death_greater_48_total_f,
COALESCE(SUM(CASE WHEN outcome_name = 'Death>48 hours' AND gender = 'M' THEN 1 ELSE 0 END), 0) AS death_greater_48_total_m

FROM real_data
WHERE age_group IS NOT NULL;