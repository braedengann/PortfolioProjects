
	--Selecting core data
SELECT TOP 10000 
Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY Location, Date

	--Finding Total Cases vs Total Deaths
	--Shows the estimated Likelihood of dying if you contract COVID-19
SELECT TOP 10000 
	Location, Date, Total_Cases, Total_Deaths,
	FORMAT((Total_Deaths/Total_Cases),'P') as DeathToCase_Ratio
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location = 'United States'
ORDER BY Location, Date 

/*ALTER TABLE PortfolioProject.dbo.CovidVaccinations
ALTER COLUMN new_vaccinations NUMERIC(18, 0)*/

	--Looking at Total Cases vs Population
	--Shows what percentage of population that tested positive for COVID-19
SELECT TOP 10000 
	Location, Date, Population, Total_Cases, 
	FORMAT((Total_Cases/Population),'P') as CasesToPop_Ratio
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location = 'United States'
ORDER BY Location, Date 

	--Looking at Countries with Highest Infection Rate compared to population
SELECT TOP 10000 
	Location, Population, 
	MAX(Total_Cases) as HighestInfectionCount, 
	FORMAT(MAX((Total_Cases/Population)),'P') as PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY Location, Population
ORDER BY Location


	--Showing countries with highest death count per Population
SELECT TOP 10000 
	Location, 
	MAX(Total_Deaths) as TotalDeathCount 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount desc

	--Highest death count broken down by continent
SELECT TOP 10000 
	Location, 
	MAX(Total_Deaths) as TotalDeathCount 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NULL
	AND Location not in ('World','European Union','High income','Upper middle income','Lower middle income','Low income')
GROUP BY Location
ORDER BY TotalDeathCount desc


	--Global Death to Cases Ratio
SELECT TOP 10000 
	Date, 
	MAX(Total_Cases) as Cases, 
	MAX(Total_Deaths) as Deaths,
	FORMAT((SUM(Total_Deaths)/SUM(Total_Cases)),'P') as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE New_Cases <> 0
	AND New_Deaths <> 0
GROUP BY Date
HAVING SUM(Total_Deaths) / NULLIF(SUM(Total_Cases), 0) < 1
ORDER BY Date 


	--Showing Total Population vs Vaccinations
SELECT TOP 10000 
	CD.continent,
	CD.location,
	CD.date,
	CD.population,
	CV.new_vaccinations,
	SUM(CAST(CV.new_vaccinations as INT)) 
		OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as RollingVaccinations
FROM PortfolioProject.dbo.CovidDeaths CD
	JOIN PortfolioProject.dbo.CovidVaccinations CV
		ON CD.location = CV.location
		AND CD.date = CV.date
WHERE CD.continent is not NULL
ORDER BY CD.location, CD.date


	--Using CTE to show rolling vaccinations to demonstrate vaccinations / population over time
WITH PVC (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations) 
as (
	SELECT  
		CD.continent,
		CD.location,
		CD.date,
		CD.population,
		CV.new_vaccinations,
		SUM(CV.new_vaccinations) 
			OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as RollingVaccinations
	FROM PortfolioProject.dbo.CovidDeaths CD
		JOIN PortfolioProject.dbo.CovidVaccinations CV
			ON CD.location = CV.location
			AND CD.date = CV.date
	WHERE CD.continent is not NULL
		AND New_Vaccinations is not NULL
	)
SELECT *, 
	FORMAT((RollingVaccinations/Population),'P') AS VaccinestoPopulation
FROM PVC
ORDER BY location, date


	--AS TEMP TABLE INSTEAD:
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinations numeric)

INSERT INTO #PercentPopulationVaccinated
	SELECT  
		CD.continent,
		CD.location,
		CD.date,
		CD.population,
		CV.new_vaccinations,
		SUM(CV.new_vaccinations) 
			OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as RollingVaccinations
	FROM PortfolioProject.dbo.CovidDeaths CD
		JOIN PortfolioProject.dbo.CovidVaccinations CV
			ON CD.location = CV.location
			AND CD.date = CV.date
	WHERE CD.continent is not NULL
		AND New_Vaccinations is not NULL
		--AND CD.location = 'United States'

SELECT *, 
	FORMAT((RollingVaccinations/Population),'P') AS VaccinestoPopulation
FROM #PercentPopulationVaccinated
ORDER BY location, date


	--Creating view to store data for visuals
CREATE VIEW RollingVaccinationView as
SELECT  
		CD.continent,
		CD.location,
		CD.date,
		CD.population,
		CV.new_vaccinations,
		SUM(CV.new_vaccinations) 
			OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as RollingVaccinations
	FROM PortfolioProject.dbo.CovidDeaths CD
		JOIN PortfolioProject.dbo.CovidVaccinations CV
			ON CD.location = CV.location
			AND CD.date = CV.date
	WHERE CD.continent is not NULL
		AND New_Vaccinations is not NULL