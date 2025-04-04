--Massachussets General Hospital 

--A. Exploratory Data Analysis (EDA) on Patient Encounters, Length of Stay & Health Trends (EDA)
SELECT *
FROM patients

SELECT *
FROM encounters 


--1. How many patients visited the hospital per year between 2011 and 2022?
SELECT YEAR(START) AS Encounter_Year, COUNT(DISTINCT PATIENT_ID) AS Total_Patients
FROM encounters 
WHERE YEAR(START) BETWEEN 2011 AND 2022
GROUP BY YEAR(START)
ORDER BY Total_Patients DESC;
--2021 had the highest patients with a total of 649 patients.


--2. Which cities have the most hospital patients?
SELECT CITY, COUNT(*) AS total_patients
FROM patients
GROUP BY CITY
ORDER BY total_patients DESC;
--Boston has the most patients


--3. What is the average length of stay per encounter?
SELECT Description, AVG(DATEDIFF(DAY,START, STOP)) AS avg_length_of_stay_in_days
FROM encounters
GROUP BY DESCRIPTION
ORDER BY avg_length_of_stay_in_days DESC;
-- Periodic reevaluation and management of healthy individual (procedure) requires longer hospitalization


--4. What are the top 5 most common encounters among patients?
SELECT TOP (5) DESCRIPTION, COUNT(*) AS occurrence 
FROM encounters
GROUP BY DESCRIPTION 
ORDER BY occurrence DESC;
--Procedures for check ups, examinations, symptoms and clinic care


--5. What is the distribution of patient encounters by age group?
SELECT 
    CASE  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 0 AND 17 THEN '0-17'  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 18 AND 35 THEN '18-35'  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 36 AND 50 THEN '36-50'  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 51 AND 65 THEN '51-65'  
        ELSE '65+'  
    END AS age_group,  
    COUNT(*) AS total_patients  
FROM encounters e  
JOIN patients p
ON P.patient_id = e.patient_id  
GROUP BY  
    CASE  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 0 AND 17 THEN '0-17'  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 18 AND 35 THEN '18-35'  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 36 AND 50 THEN '36-50'  
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 51 AND 65 THEN '51-65'  
        ELSE '65+'  
    END  
ORDER BY total_patients DESC;
--Patients above 65 tend to come to the hospital more.


--6. What is the gender distribution of patients?
SELECT GENDER, COUNT(*) AS total_patients
FROM patients
GROUP BY GENDER
ORDER BY total_patients DESC;
--Male patients are more than female patients



--7. What is the gender distribution of patients across illnesses?
SELECT p.Gender , e.REASONDESCRIPTION, e.description, COUNT(*) AS total_patients
FROM encounters e  
JOIN patients p
ON P.patient_id = e.patient_id  
GROUP BY  p.GENDER, e.REASONDESCRIPTION, e.DESCRIPTION
ORDER BY total_patients DESC
--SN 20; men can have breast cancer too
--Apart from general checkups and exams, females come to the hospital mostly for pregnancy and males for heart failure.


-- 8. What is the racial and ethnic distribution of patients?
SELECT RACE, ETHNICITY, COUNT(*) AS total_patients
FROM patients
GROUP BY RACE, ETHNICITY
ORDER BY total_patients DESC;



-- 9. How many encounters were recorded for each encounter type?
SELECT ENCOUNTERCLASS, COUNT(*) AS total_encounters
FROM encounters
WHERE CAST(START AS DATE) >= DATEADD(YEAR, 0, CAST(STOP AS DATE))
GROUP BY ENCOUNTERCLASS;
--ambulatory was the highest. care either therapeutic or diagnostic in a one day setting. 
--Ambulatory care does not require overnight stay in a hospital


--10. What are the busiest days of the week for patient encounters?
SELECT DATENAME(WEEKDAY, START) AS day_of_week, COUNT(*) AS total_encounters 
FROM encounters
GROUP BY DATENAME(WEEKDAY, START)  
ORDER BY total_encounters DESC;
--Mondays are the busiest days despire it being the first working day


--11. How does the average length of stay vary by encounter type?
SELECT ENCOUNTERCLASS, AVG(DATEDIFF(DAY, START, STOP)) AS avg_length_of_stay 
FROM encounters
GROUP BY ENCOUNTERCLASS 
ORDER BY avg_length_of_stay DESC;
--Inpatients stay longer because they're the only ones admitted compared to the other types that don't require overnight stay


--B. Cost & Payer (insurance) Coverage Analysis
SELECT *
FROM payers

--1. What is the average total claim cost per encounter type
SELECT ENCOUNTERCLASS, AVG(TOTAL_CLAIM_COST) as Average_Cost$
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY Average_Cost$ DESC
--Inpatients cost more as they have to stay overnight, while outpatients cost less as they don't stay overnight


--2. How much of the total claim cost is covered by insurance (payer coverage)?
SELECT p.NAME,
	SUM(e.PAYER_COVERAGE) AS total_covered,
    SUM(e.TOTAL_CLAIM_COST) AS total_claims,
    (SUM(e.PAYER_COVERAGE) * 100.0 / NULLIF(SUM(e.TOTAL_CLAIM_COST), 0)) AS coverage_percentage
FROM encounters e
LEFT JOIN payers p
ON e.PAYER_ID = p.PAYER_ID
GROUP BY p.NAME
ORDER BY coverage_percentage DESC
--Medicaid, Dual Eligible, Medicare and Blue cross blue shield covered more than 65% of the total claim costs.
--They are good insurance companies. Highly recommended
--Whereas, from UnitedHealthcare to Anthem covered less than 0.20% of the total claim costs.


--3. What is the distribution of total claim costs by encounter type?
SELECT ENCOUNTERCLASS, SUM(TOTAL_CLAIM_COST) as total_claims
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY total_claims DESC
--Ambulatory has the highest total claim costs. It may require efficiency improvement



--C. Procedure Analysis

-- 1. What are the most common medical procedures performed in the hospital?
SELECT DESCRIPTION AS procedure_name, COUNT(*) AS total_times_performed
FROM procedures
WHERE DESCRIPTION LIKE '%(procedure)%'
GROUP BY DESCRIPTION
ORDER BY total_times_performed DESC;
--Assessment of health and social care needs


--2. What are the most expensive medical procedures?
SELECT TOP (10) DESCRIPTION AS procedure_name, AVG(BASE_COST) AS avg_cost, COUNT(*) AS total_performed
FROM procedures
WHERE DESCRIPTION LIKE '%(procedure)%'
GROUP BY DESCRIPTION
ORDER BY avg_cost DESC;
--Intensive Care Unit procedures are the most expensive
--Combined Chemotherapy and radiation therapy are performed the most


--3. What are the most common procedures used for specific health conditions?
SELECT TOP(10)
    REASONDESCRIPTION AS condition_treated, 
    DESCRIPTION AS procedure_used, 
    COUNT(*) AS usage_count
FROM procedures
WHERE REASONDESCRIPTION IS NOT NULL
GROUP BY REASONDESCRIPTION, DESCRIPTION
ORDER BY usage_count DESC
--Atrial Fibrilation treatment using Electrical cardioversion was done the most



--4. How many patients undergo multiple procedures? i.e. more than 3
SELECT pr.PATIENT_ID, CONCAT(p.FIRST,' ', P.LAST) AS Full_name, COUNT(*) AS num_procedures
FROM procedures pr
LEFT JOIN patients p
ON pr.PATIENT_ID = p.PATIENT_ID
GROUP BY pr.PATIENT_ID, CONCAT(p.FIRST,' ', P.LAST)
HAVING COUNT(*) > 3
ORDER BY num_procedures DESC;
--672 patients undergo more than 3 procedures
--Kimberly Collier having the most procedures (1783). why?

--a. Why does Kimberly have the most procedures?
SELECT pr.DESCRIPTION, MIN(pr.START) AS first_start_date, MAX(pr.STOP) AS last_stop_date, COUNT(*) AS num_of_occurrence
FROM procedures pr
LEFT JOIN patients pa ON pr.PATIENT_ID = pa.PATIENT_ID
WHERE pa.FIRST = 'Kimberly627'
GROUP BY pr.DESCRIPTION
ORDER BY num_of_occurrence DESC;
--She was a substance and alcohol addict, resulting to kidney failure.
--Renal dialysis 1167 times. started in 2012. Was discharged only once in 2014

--b. At what age did she start the procedure?
SELECT TOP (1) datediff(YEAR, pa.BIRTHDATE, pr.START) AS Age_of_first_procedure
FROM procedures pr
LEFT JOIN patients pa ON pr.PATIENT_ID = pa.PATIENT_ID
where first = 'kimberly627' and pr.DESCRIPTION LIKE 'Renal dialysis%'
--83 years.



--D. Mortality Rate Analysis

--1. What percentage of patients in the database are deceased?
SELECT 
    COUNT(*) AS total_patients,
    SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) AS deceased_patients,
    (SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS mortality_rate
FROM patients;
--15.8% of 974 patients are deceased


--2. What is the average age at which patients pass away?
SELECT AVG(DATEDIFF(YEAR, BIRTHDATE, DEATHDATE)) AS avg_age_at_death
FROM patients
WHERE DEATHDATE IS NOT NULL;
--Most patients die at 79 years


--3. What are the mortality trends over time?
SELECT YEAR(DEATHDATE) AS death_year, COUNT(*) AS deceased_patients
FROM patients
WHERE DEATHDATE IS NOT NULL
GROUP BY YEAR(DEATHDATE)
ORDER BY death_year;
--the rate drastically increased between 2016 and 2021


--4. Which chronic diseases have the highest death rates?
SELECT 
    p.DESCRIPTION AS chronic_condition,
    COUNT(DISTINCT pat.PATIENT_ID) AS total_patients_with_condition,
    COUNT(DISTINCT CASE WHEN pat.DEATHDATE IS NOT NULL THEN pat.PATIENT_ID END) AS deceased_patients,
    (COUNT(DISTINCT CASE WHEN pat.DEATHDATE IS NOT NULL THEN pat.PATIENT_ID END) * 100.0 / COUNT(DISTINCT pat.PATIENT_ID)) AS mortality_rate
FROM procedures p
JOIN patients pat ON p.PATIENT_ID = pat.PATIENT_ID
WHERE p.DESCRIPTION LIKE '%diabetes%' 
   OR p.DESCRIPTION LIKE '%hypertension%' 
   OR p.DESCRIPTION LIKE '%cancer%' 
   OR p.DESCRIPTION LIKE '%asthma%' 
   OR p.DESCRIPTION LIKE '%heart disease%' 
   OR p.DESCRIPTION LIKE '%depression%' 
   OR p.DESCRIPTION LIKE '%anxiety%' 
   OR p.DESCRIPTION LIKE '%renal dialysis%' 
   OR p.DESCRIPTION LIKE '%chemotherapy%' 
   OR p.DESCRIPTION LIKE '%teleradiotherapy%' 
   OR p.DESCRIPTION LIKE '%hemodialysis%' 
   OR p.DESCRIPTION LIKE '%pulmonary rehabilitation%'  
   OR p.DESCRIPTION LIKE '%heart failure%' 
   OR p.DESCRIPTION LIKE '%percutaneous coronary intervention%' 
   OR p.DESCRIPTION LIKE '%coronary artery bypass grafting%' 
GROUP BY p.DESCRIPTION
ORDER BY mortality_rate DESC;
--Hemodialysis, used to treat kidney failure, has the highest mortality rate


