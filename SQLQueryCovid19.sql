
-- Check data content in covid_deaths
SELECT TOP 100
	*
FROM
	covid19..covid_deaths;

-- Check data content in covid_vaccinations
SELECT TOP 100
	*
FROM
	covid19..covid_vaccinations;

-- Check location and continent names
-- NULL Continent with these locations: 
--		Africa, Asia, Europe, European Union (27), High-income countries, Lower-middle-income countries, 
--		Low-income countries, North America, Oceania, South America, Upper-middle-income countries, and World
SELECT 
	DISTINCT location,
	continent
FROM
	covid19..covid_deaths
ORDER BY location;

-- TABLE 1 : Death Percentage Overview
SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths, 
	(SUM(new_deaths) / SUM(new_cases))*100 AS death_percentage
FROM
	covid19..covid_deaths
WHERE
	continent IS NOT NULL;

-- TABLE 2: Total Death Count per Continent
SELECT
	continent,
	COALESCE(SUM(new_deaths), 0) AS total_death_count
FROM
	covid19..covid_deaths
WHERE
	continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	total_death_count DESC;

-- TABLE 3: Percentage of Population Infected per Country
SELECT
	location AS country,
	population,
	MAX(total_cases) AS infected,
	MAX(total_cases / population) * 100 AS percent_population_infected
FROM
	covid19..covid_deaths
WHERE
	continent IS NOT NULL
GROUP BY
	location, population
ORDER BY
	percent_population_infected DESC;

-- TABLE 4: Percentage of Population Infected per Country and date
-- TABLE 3: Percentage of Population Infected per Country
SELECT
	location AS country,
	population,
	date,
	MAX(total_cases) AS infected,
	MAX(total_cases / population) * 100 AS percent_population_infected
FROM
	covid19..covid_deaths
WHERE
	continent IS NOT NULL
GROUP BY
	location, population, date
ORDER BY
	percent_population_infected DESC;