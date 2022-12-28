UPDATE portfolio..CovidDeath SET continent = NULL WHERE continent NOT LIKE '%[a-z, 0,9]%'
UPDATE portfolio..CovidDeath SET location = NULL WHERE location NOT LIKE '%[a-z, 0,9]%'


SELECT * FROM portfolio..CovidDeath
WHERE continent IS NOT NULL ORDER BY 3, 4

--select the data that is going to be used

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM portfolio..CovidDeath WHERE continent IS NOT NULL ORDER BY 1, 2

--looking at total cases vs total deaths
--query below shows the likelihood of dying if a person gets infected with covid in UK

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM portfolio..CovidDeath WHERE location like '%united king%'
ORDER BY 1, 2

--looking at total cases vs population in UK over time

SELECT location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage 
FROM portfolio..CovidDeath WHERE location like '%united king%'
ORDER BY 1, 2

--which countries have the highest infection rate vs population?

SELECT location, population, MAX(total_cases) as HighestCasesCount, MAX((total_cases/population))*100 as CasesPercentage 
FROM portfolio..CovidDeath 
WHERE continent IS NOT NULL GROUP BY location, population 
ORDER BY CasesPercentage desc

--which countries have the highest death rate vs population?

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount, MAX((total_deaths/population))*100 as DeathPercentage 
FROM portfolio..CovidDeath 
WHERE continent IS NOT NULL GROUP BY location
ORDER BY DeathPercentage desc

--Breaking things down by continent

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM portfolio..CovidDeath 
WHERE continent IS NOT NULL GROUP BY continent
ORDER BY TotalDeathCount desc

--below query is the accurate one

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM portfolio..CovidDeath 
WHERE continent IS NULL GROUP BY location
ORDER BY TotalDeathCount desc

--daily global numbers

SELECT date, SUM(new_cases) as total_cases_on_that_day, SUM(cast(new_deaths as int)) as total_deaths_on_that_day, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM portfolio..CovidDeath
WHERE continent IS NOT NULL GROUP BY date
ORDER BY 1, 2

--aggregate global numbers

SELECT SUM(new_cases) as total_cases_on_that_day, SUM(cast(new_deaths as int)) as total_deaths_on_that_day, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM portfolio..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1, 2


UPDATE portfolio..CovidVaccinations SET people_vaccinated = NULL WHERE people_vaccinated NOT LIKE '%[a-z, 0,9]%'
UPDATE portfolio..CovidVaccinations SET total_vaccinations = NULL WHERE total_vaccinations NOT LIKE '%[a-z, 0,9]%'
UPDATE portfolio..CovidVaccinations SET new_vaccinations = NULL WHERE new_vaccinations NOT LIKE '%[a-z, 0,9]%'


--merging two tables and looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM portfolio..CovidDeath dea JOIN portfolio..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--using CTE

WITH PopsVac (continent, location, date, population, new_vaccinations, PeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM portfolio..CovidDeath dea JOIN portfolio..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (PeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM PopsVac

--creating VIEW to store data for visualization

CREATE VIEW PercentagePopView AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM portfolio..CovidDeath dea JOIN portfolio..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM PercentagePopView