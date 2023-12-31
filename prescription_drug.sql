--Q1,
---a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count)AS total_number
FROM prescription
GROUP BY npi
ORDER BY total_number DESC;
--1881634483

---b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT SUM(total_claim_count) AS total_number,p2.nppes_provider_first_name, p2.nppes_provider_last_org_name, p2.specialty_description
FROM prescription AS p1
INNER JOIN prescriber AS p2 
USING(npi)
GROUP BY p2.nppes_provider_first_name, p2.nppes_provider_last_org_name, p2.specialty_description
ORDER BY total_number DESC;

--Q2
---a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT SUM(total_claim_count) AS total_number,p2.specialty_description
FROM prescription AS p1
INNER JOIN prescriber AS p2 
USING(npi)
GROUP BY p2.specialty_description
ORDER BY total_number DESC;
-- Family Practice:9752347

---b.Which specialty had the most total number of claims for opioids?
SELECT SUM(total_claim_count) AS total_number,p2.specialty_description
FROM prescriber AS p2
INNER JOIN prescription AS p1 
USING(npi)
INNER JOIN drug AS d 
ON d.drug_name=p1.drug_name
WHERE opioid_drug_flag='Y'
GROUP BY p2.specialty_description
ORDER BY total_number DESC;
--Nurse Practitioner : 900845

---c.Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, SUM(total_claim_count)AS total_number
FROM prescriber AS p2
INNER JOIN prescription AS p1
USING (npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL
ORDER BY total_number DESC;
--NO

--d For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT specialty_description,SUM(total_claim_count),
							 SUM (CASE WHEN opioid_drug_flag='Y' THEN total_claim_count END) AS total_number,
							ROUND(SUM (CASE WHEN opioid_drug_flag='Y'THEN total_claim_count END)*100/SUM(total_claim_count),2) AS percentage
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING (npi)
INNER JOIN drug AS d
USING (drug_name)
GROUP BY specialty_description
ORDER BY total_number DESC NULLS LAST;

---Q3,
--a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost)AS total_cost
FROM drug AS d
INNER JOIN prescription AS p
USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC;
--INSULIN GLARGINE,HUM.REC.ANLOG:104264066.35

--b. Which drug (generic_name) has the hightest total cost per day?Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT generic_name, SUM(ROUND(total_drug_cost/total_day_supply,2)) AS drug_cost_daily
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
GROUP BY generic_name
ORDER BY drug_cost_daily DESC;
-- LEDIPASVIR/SOFOSBUVIR: 88270.88

--Q4
---a.For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' 
--for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
--and says 'neither' for all other drugs.

SELECT drug_name,
 CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
 	  WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	  ELSE 'neither' END AS drug_type
FROM drug;

---b.Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.
SELECT 
 SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost::money END)AS opioid,
 	 SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost ::money END) AS antibiotic
FROM drug AS d
INNER JOIN prescription AS p
USING (drug_name);
-- opioid:105,080,626.37

---Q5.
---a.How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT (DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state='TN';
--10

---b.Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsa, SUM(p.population) AS total_population
FROM cbsa
INNER JOIN fips_county 
USING (fipscounty)
INNER JOIN population AS p
USING (fipscounty)
WHERE state='TN'
GROUP BY cbsa
ORDER BY total_population;
--34100 smallest 
--34980 largest

---c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT SUM(population) AS total_pop, county
FROM fips_county
INNER JOIN population AS p
USING (fipscounty)
WHERE state = 'TN'
GROUP BY county
ORDER BY total_pop DESC;
--937847:shelby

---Q6.
--a.Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name,total_claim_count
FROM prescription
WHERE total_claim_count >='3000';

--b.For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT p.drug_name,total_claim_count,opioid_drug_flag
FROM prescription AS p
INNER JOIN drug AS d 
USING (drug_name)
WHERE total_claim_count >='3000';

--c.Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT p.drug_name,total_claim_count,opioid_drug_flag,nppes_provider_first_name,nppes_provider_last_org_name
FROM prescription AS p
INNER JOIN drug AS d 
USING (drug_name)
INNER JOIN prescriber AS p1 
ON p1.npi=p.npi
WHERE total_claim_count >='3000'

---Q7.The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.
SELECT DISTINCT p2.npi, d.drug_name, total_claim_count
FROM prescriber AS p2
CROSS JOIN drug AS d
LEFT JOIN prescription AS p 
ON p2.npi = p.npi
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--a.First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') 
--in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
--Warning: Double-check your query before running it. 
--You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, d.drug_name
FROM prescriber AS P
CROSS JOIN drug AS d
WHERE specialty_description='Pain Management' 
AND nppes_provider_city='NASHVILLE' 
AND opioid_drug_flag='Y';

--b.Next, report the number of claims per drug per prescriber. Be sure to include all combinations,
--whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi, d.drug_name,total_claim_count
FROM prescriber AS P
CROSS JOIN drug AS d
LEFT JOIN prescription AS p1
USING (npi,drug_name)
WHERE specialty_description='Pain Management' 
AND nppes_provider_city='NASHVILLE' 
AND opioid_drug_flag='Y';

--c.Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT npi,d.drug_name, COALESCE(total_claim_count) AS total_claim
FROM prescriber AS P
CROSS JOIN drug AS d
LEFT JOIN prescription AS p1
USING (npi,drug_name)
WHERE specialty_description='Pain Management' 
AND nppes_provider_city='NASHVILLE' 
AND opioid_drug_flag='Y'
ORDER BY total_claim DESC NULLS LAST;
