# Enhancing Hospital Performance and Patient Outcomes Through SQL-Based Exploratory Data Analysis

## Overview
This repository leverages SQL-based analytics to address operational challenges at Massachusetts General Hospital, using synthetic data from 2011–2022. The project analyzes patient demographics, insurance coverage, and medical procedures to uncover actionable insights.

## Key Highlights
- **Dataset:** ~1,000 patient records including demographics, insurance coverage, and encounter details.
- **Challenges Addressed:** High medical costs, disparities in insurance coverage, and inconsistent hospital performance.
- **Approach:** SQL-based exploratory data analysis (EDA) focused on patient trends, financial optimization, and procedures.

## Descriptive Information
For a detailed description of the dataset, please refer to the data dictionary in the zip file in this repository.
For more information about the analysis conducted, insights generated, and recommendations, please refer to the Word document included in this repository.
To view all the SQL queries, please refer to the SQL file included in this repository.

---

### **A. Exploratory Data Analysis (EDA)**  
Exploring patient data, length of stay, encounters, and health trends.  
#### Sample Queries:  
1. **Number of patients visiting per year (2011–2022):**  
   ```sql
   SELECT YEAR(START) AS Encounter_Year, COUNT(DISTINCT PATIENT_ID) AS Total_Patients
   FROM encounters 
   WHERE YEAR(START) BETWEEN 2011 AND 2022
   GROUP BY YEAR(START)
   ORDER BY Total_Patients DESC;
   ```  
   - *Insight*: 2021 had the highest patient visits (649 patients).  

2. **Average length of stay per encounter:**  
   ```sql
   SELECT Description, AVG(DATEDIFF(DAY, START, STOP)) AS avg_length_of_stay_in_days
   FROM encounters
   GROUP BY DESCRIPTION
   ORDER BY avg_length_of_stay_in_days DESC;
   ```
    - *Insight*: Periodic reevaluation procedures require longer hospital stays.  
3. **Busiest days of the week for patient encounters:**
   ```sql
    SELECT DATENAME(WEEKDAY, START) AS day_of_week, COUNT(*) AS total_encounters 
    FROM encounters
    GROUP BY DATENAME(WEEKDAY, START)  
    ORDER BY total_encounters DESC;
   ```
   - *Insight*: Mondays are the busiest days in the hospital despire it being the first working day.  
4. **Distribution of patient encounters by age group:**
   ```sql
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
   ```
   - *Insight*: Patients above 65 tend to come to the hospital more.
     
#### Recommendations:  
- Increase resources on Mondays to address peak patient demand.  
- Prioritize programs for patients aged 65+ due to frequent hospital visits.  

---

### **B. Cost & Payer (Insurance) Coverage Analysis**  
Analyzing claims, costs, and insurance coverage.  
#### Sample Queries:  
1. **Average total claim cost per encounter type:**  
   ```sql
   SELECT ENCOUNTERCLASS, AVG(TOTAL_CLAIM_COST) AS Average_Cost$
   FROM encounters
   GROUP BY ENCOUNTERCLASS
   ORDER BY Average_Cost$ DESC;
   ```  
   - *Insight*: Inpatients incur higher costs than outpatients due to overnight stays.  

2. **Insurance coverage percentage:**  
   ```sql
   SELECT p.NAME, SUM(e.PAYER_COVERAGE) AS total_covered, SUM(e.TOTAL_CLAIM_COST) AS total_claims,
          (SUM(e.PAYER_COVERAGE) * 100.0 / NULLIF(SUM(e.TOTAL_CLAIM_COST), 0)) AS coverage_percentage
   FROM encounters e
   LEFT JOIN payers p ON e.PAYER_ID = p.PAYER_ID
   GROUP BY p.NAME
   ORDER BY coverage_percentage DESC;
   ```  
   - *Insight*: Medicaid, Dual Eligible, Medicare and Blue Cross Blue Shield cover more than 65% of claim costs, while other payers cover less than 0.20%.  

#### Recommendations:  
- Build partnerships with top-performing insurance companies (e.g., Medicaid, Medicare).  
- Audit ambulatory care for cost-efficiency improvements.  

---

### **C. Procedure Analysis**  
Investigating procedure frequency, costs, and patient-specific trends.  
#### Sample Queries:  
1. **Most common medical procedures performed:**  
   ```sql
   SELECT DESCRIPTION AS procedure_name, COUNT(*) AS total_times_performed
   FROM procedures
   WHERE DESCRIPTION LIKE '%(procedure)%'
   GROUP BY DESCRIPTION
   ORDER BY total_times_performed DESC;
   ```  
   - *Insight*: Assessment of health and social care needs is the most common procedure.  

2. **Patients undergoing multiple procedures (more than 3):**  
   ```sql
   SELECT pr.PATIENT_ID, CONCAT(p.FIRST, ' ', p.LAST) AS Full_name, COUNT(*) AS num_procedures
   FROM procedures pr
   LEFT JOIN patients p ON pr.PATIENT_ID = p.PATIENT_ID
   GROUP BY pr.PATIENT_ID, CONCAT(p.FIRST, ' ', p.LAST)
   HAVING COUNT(*) > 3
   ORDER BY num_procedures DESC;
   ```  
   - *Insight*: Kimberly Collier underwent 1,783 procedures due to substance and alcohol addiction leading to kidney failure.  

#### Recommendations:  
- Strengthen support programs for addiction prevention.  
  - Establish peer-support communities where patients can share experiences and advice, reducing feelings of isolation. 

---

### **D. Mortality Rate Analysis**  
Evaluating mortality rates, trends, and associated conditions.  
#### Sample Queries:  
1. **Percentage of deceased patients:**  
   ```sql
   SELECT COUNT(*) AS total_patients, 
          SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) AS deceased_patients,
          (SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS mortality_rate
   FROM patients;
   ```  
   - *Insight*: 15.8% of patients are deceased.  

2. **Mortality trends over time:**  
   ```sql
   SELECT YEAR(DEATHDATE) AS death_year, COUNT(*) AS deceased_patients
   FROM patients
   WHERE DEATHDATE IS NOT NULL
   GROUP BY YEAR(DEATHDATE)
   ORDER BY death_year;
   ```  
   - *Insight*: Mortality rates increased drastically between 2016 and 2021.  

#### Recommendations:  
- Develop specialized care for chronic diseases with high mortality rates (e.g., kidney failure).  
- Strengthen palliative care services for elderly patients.  

---

## Usage
Clone the repository and access the Word document for detailed insights:
```bash
git clone https://github.com/karen-ambrose/Hospital-Analysis.git
