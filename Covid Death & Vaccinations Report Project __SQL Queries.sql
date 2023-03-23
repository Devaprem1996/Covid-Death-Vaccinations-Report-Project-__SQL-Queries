--select *
--     from dbo.CovidD
--	 order by 3,4
--select *
--     from dbo.CovidV
--	 order by 3,4

-- Select Data that we are going to be using 

Select Location, date, total_cases, new_cases,Total_deaths, population
	From CovidProject..CovidDeaths
	where continent is not null
	order by 1, 2

-- Looking at Total cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths,(Convert(decimal,total_deaths)/Convert(decimal,total_cases))*100 as DeathsPercentage
	From CovidProject..CovidDeaths
	where location like'%Zim%'
	and continent is not null
	order by 1, 2


-- Looking at Total cases  vs population

select Location, date, population, total_cases, (convert(decimal, total_cases)/convert(decimal,population))*100 as PercentOfpopulation
From CovidProject..CovidDeaths
	--where location like'%Zim%'
	where  continent is not null
	order by 1, 2
	

-- looking at counries with Highest Infection Rate compared to population

select Location, population, MAX(total_cases) as HighestInfectionCount , MAX(convert(decimal, total_cases)/convert(decimal,population))*100 as PercentOfInfection
From CovidProject..CovidDeaths
	--where location like'%State%'
	where continent is not null
	Group by Location,population
	order by PercentOfInfection desc

-- Showing Countries with Highesh Death Count per Population

select Location, MAX(Cast(total_deaths as int)) as HighestDeathCount 
    From CovidProject..CovidDeaths
	--where location like'%State%'
	where continent is null
	Group by Location
	order by HighestDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing Contintents with the highest death count per population

select continent, MAX(Cast(total_deaths as int)) as HighestDeathCount 
    From CovidProject..CovidDeaths
	--where location like'%State%'
	where continent is not null
	Group by continent
	order by HighestDeathCount desc


-- GLOBAL NUMBERS

SELECT 
       SUM(new_cases) AS newcases,
       SUM(CAST(new_deaths AS INT)) AS sumofnewdeaths,
	   CASE WHEN SUM(new_cases) = 0 THEN 0
			ELSE SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 
			END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Looking at Total Population VS Vaccinations

select dea.continent,
       dea.location, 
       dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(decimal,vac.new_vaccinations)) over (partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated 
from CovidProject..CovidD as dea
    join CovidProject..CovidV as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null
order by 2,3


-- USE CTE 

With PopvsVac (continent,location, Date,population , new_vaccinations,  RollingPeopleVaccinated)
as 
(
select dea.continent,
       dea.location, 
       dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(decimal,vac.new_vaccinations)) 
	   over (partition by dea.location Order by dea.location,dea.date) 
	   as RollingPeopleVaccinated
from CovidProject..CovidD as dea
    join CovidProject..CovidV as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/population)*100
from PopvsVac



-- Temp Table

DROP TABLE IF exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated

select dea.continent,
       dea.location, 
       dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(decimal,vac.new_vaccinations)) 
	   over (partition by dea.location Order by dea.location,dea.date) 
	   as RollingPeopleVaccinated
from CovidProject..CovidD as dea
    join CovidProject..CovidV as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as 
select dea.continent,
       dea.location, 
       dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(decimal,vac.new_vaccinations)) 
	   over (partition by dea.location Order by dea.location,dea.date) 
	   as RollingPeopleVaccinated
from CovidProject..CovidD as dea
    join CovidProject..CovidV as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null
--order by 2,3