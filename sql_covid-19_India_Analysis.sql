---Looking how the tables look like.
use [covid-19_India_Analysis]
select * from district
select * from state
select * from timeseries
select * from vaccination

--- Maximum Deseased State
SELECT state_name, population, total_confirmed, total_recovered, total_deceased, total_tested, total_vaccinated1+total_vaccinated2 as total_Vac
FROM state
WHERE total_deceased = (
    SELECT MAX(total_deceased)
    FROM state
)


--- Maximum Populated State
SELECT state_name, population, total_confirmed, total_recovered, total_deceased, total_tested, total_vaccinated1+total_vaccinated2 as total_Vac
FROM state
WHERE population = (
    SELECT MAX(population)
    FROM state
)



--- Maximum Covid Confirmed State
SELECT state_name, population, total_confirmed, total_recovered, total_deceased, total_tested, total_vaccinated1+total_vaccinated2 as total_Vac
FROM state
WHERE total_confirmed = (
    SELECT MAX(total_confirmed)
    FROM state
)



--- Maximum Covid Recovered State
SELECT state_name, population, total_confirmed, total_recovered, total_deceased, total_tested, total_vaccinated1+total_vaccinated2 as total_Vac
FROM state
WHERE total_recovered = (
    SELECT MAX(total_recovered)
    FROM state
)



--- Maximum Vaccinated State 
SELECT state_name, population, total_confirmed, total_recovered, total_deceased, total_tested, total_vaccinated1+total_vaccinated2 as total_Vac
FROM state
WHERE total_vaccinated1+total_vaccinated2 = (
    SELECT MAX(total_vaccinated1+total_vaccinated2)
    FROM state
)



--- Maximum tested State 
SELECT state_name, population, total_confirmed, total_recovered, total_deceased, total_tested, total_vaccinated1+total_vaccinated2 as total_Vac
FROM state
WHERE total_tested = (
    SELECT MAX(total_tested)
    FROM state
)



----Weekly Evoluation of Covid Cases
SELECT state_name, 
       DATEADD(week, DATEDIFF(week, 0, CAST(date AS DATE)), 0) AS week_start_date,
       SUM(confirmed) AS confirmed_cases, 
       SUM(recovered) AS recovered_cases, 
       SUM(deceased) AS death_cases, 
       SUM(tested) AS tested_cases
FROM timeseries
GROUP BY state_name, DATEADD(week, DATEDIFF(week, 0, CAST(date AS DATE)), 0), DATENAME(WEEK,date)
ORDER BY state_name, week_start_date




--- Finding the Testing Ratio
WITH testing_ratio_table AS (
  SELECT district_name,
         population,
         tested,
         CASE
            WHEN population > 0 AND convert(Decimal(5,2),(convert(float,Tested)/convert(float,population))) BETWEEN 0.05 AND 0.1 THEN 'Category A'
            WHEN population > 0 AND convert(Decimal(5,2),(convert(float,Tested)/convert(float,population))) BETWEEN 0.1 AND 0.3 THEN 'Category B'
            WHEN population > 0 AND convert(Decimal(5,2),(convert(float,Tested)/convert(float,population))) BETWEEN 0.3 AND 0.5 THEN 'Category C'
            WHEN population > 0 AND convert(Decimal(5,2),(convert(float,Tested)/convert(float,population))) BETWEEN 0.5 AND 0.75 THEN 'Category D'
            WHEN population > 0 AND convert(Decimal(5,2),(convert(float,Tested)/convert(float,population))) BETWEEN 0.75 AND 1.0 THEN 'Category E'
            ELSE 'Low Testing'
         END AS category
  FROM District
),
deaths_by_category AS (
  SELECT category,
         SUM(deceased) AS total_deaths,
         100 * SUM(deceased) / SUM(SUM(deceased)) OVER () AS percent_of_total_deaths
  FROM District
  JOIN testing_ratio_table ON District.district_name = testing_ratio_table.district_name
  GROUP BY category
)
SELECT category,
       total_deaths,
       percent_of_total_deaths
FROM deaths_by_category
ORDER BY category


---Categorise total number of confirmed cases in a state by Months and come up with that one month which was worst for India in terms of number of cases

SELECT 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
    SUM(confirmed) AS total_confirmed 
FROM 
    timeseries 
GROUP BY 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)
HAVING 
    SUM(confirmed) = (
        SELECT 
            MAX(sum_confirmed) 
        FROM 
            (SELECT 
                DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
                SUM(confirmed) AS sum_confirmed 
            FROM 
                timeseries 
            GROUP BY 
                DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)) a
    )



---Categorise total number of deaths cases in a state by Months and come up with that one month which was worst for India in terms of number of cases

SELECT 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
    SUM(deceased) AS total_deceased 
FROM 
    timeseries 
GROUP BY 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)
HAVING 
    SUM(deceased) = (
        SELECT 
            MAX(sum_deceased) 
        FROM 
            (SELECT 
                DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
                SUM(deceased) AS sum_deceased 
            FROM 
                timeseries 
            GROUP BY 
                DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)) t
    )



---Categorise total number of recovered cases in a state by Months and come up with that one month which was worst for India in terms of number of cases

SELECT 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
    SUM(recovered) AS total_recovered
FROM 
    timeseries 
GROUP BY 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)
HAVING 
    SUM(recovered) = (
        SELECT 
            MAX(sum_recovered) 
        FROM 
            (SELECT 
                DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
                SUM(recovered) AS sum_recovered 
            FROM 
                timeseries 
            GROUP BY 
                DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)) t
    )



--- Total cases Vs Total deaths

SELECT state_name, district_name, confirmed, deceased,
CASE 
    WHEN confirmed = 0 THEN 0
    ELSE ROUND((convert(float,deceased) / convert(float,confirmed) * 100),2)
END as Death_Percentage
FROM district ORDER BY Death_Percentage DESC;



--- Total cases Vs Total population
SELECT state_name, district_name, confirmed, population,
CASE 
    WHEN confirmed = 0 THEN 0
    ELSE ROUND((convert(float,confirmed) / convert(float,population) * 100),2)
END as Positive_Cases_Percentage
FROM district ORDER BY Positive_Cases_Percentage DESC;



--- Highest infection rated district from every state

with cte as 
(
select state_name, district_name, confirmed,
DENSE_RANK() OVER(PARTITION BY state_name ORDER BY confirmed DESC) as rnk from district
) 
select state_name, district_name, confirmed from cte where rnk = 1 and confirmed != 0




---- Max vaccinated state wrt to population
select * from state
select state_name, population,  total_vaccinated1, 
round((convert(float, total_vaccinated1)/convert(float, population)) *100,2) 
as vaccination1_percentage 
from state order by vaccination1_percentage desc

select state_name, population,  total_vaccinated2, 
round((convert(float, total_vaccinated2)/convert(float, population)) *100,2) 
as vaccination2_percentage 
from state order by vaccination2_percentage desc



---- Max recoverd state wrt to confirmed_cases
select state_name, total_confirmed,  total_recovered, 
round((convert(float, total_recovered)/convert(float, total_confirmed)) *100,2) 
as total_recovered_percentage 
from state order by total_recovered_percentage desc



---- Max deceased state wrt to confirmed_cases
select state_name, total_confirmed,  total_deceased, 
round((convert(float, total_deceased)/convert(float, total_confirmed)) *100,2) 
as total_deceased_percentage 
from state order by total_deceased_percentage desc

