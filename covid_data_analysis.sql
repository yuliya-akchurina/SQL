/* 
 Covid data exploration using SQL 
 Skills used:  Joins, CTE’s, Temp Tables, Window Functions, Aggregate Functions, Creating Views
 */

show tables;

-- Test created tables 

select * from covid_deaths
order by 3, 4;

select distinct continent
from covid_deaths;

SELECT * FROM covid_deaths 
WHERE continent = '';

select * from covid_deaths
where continent is null
order by 3, 4;


-- Replace empty strings in column "continent" with null value 

select NULLIF(continent,'') from covid_deaths;

select * from covid_deaths
where continent is not null
order by 3, 4;

select * from covid_vaccinations
order by 3, 4;


-- Select data that we are going to be using 

select location, date, total_cases, new_cases, total_deaths, population 
from covid_deaths
order by location, date; 


-- Review total cases vs total deaths per country
-- Show the likelihood of dying if a person contracts covid in their country 

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from covid_deaths
/*where location like '%states' */
order by location, date; 

-- Review total cases vs total deaths per country
-- Show what percentage of population got covid 

select location, date, total_cases, population, (total_cases/population)*100 as case_percentage
from covid_deaths
order by location, date; 


-- Countries with the highest infection rate compared to population 

select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as case_percentage
from covid_deaths
group by location, population
order by case_percentage desc; 


-- Countries with the highest mortality rate per population 

select location, MAX(total_deaths) as total_death_count
from covid_deaths
where continent !=''
group by location
order by total_death_count desc; 


-- Check numbers by continent
-- Showing continents with the highest death count 

select continent, MAX(total_deaths) as total_death_count
from covid_deaths
where continent !=''   # to show only continents 
group by continent
order by total_death_count desc; 


-- Global numbers per day 

select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases) *100 as death_percentage
from covid_deaths
where continent !=''
group by date
order by location, date; 


-- Global numbers total

select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases) *100 as death_percentage
from covid_deaths
where continent !=''
order by location, date; 


-- Looking a total population vs vaccinations

-- Join vaccinations and death tables 

select * 
from covid_deaths dea
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date; 


-- New vaccinations per day 

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from covid_deaths dea
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent !=''
order by location, date; 


-- Rolling count of new vaccinations per day 

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) over (
partition by dea.location 
order by dea.location, dea.date) as rolling_people_vaccinated
from covid_deaths dea
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent !='' -- and dea.location = 'Canada'
order by dea.location, dea.date; 


-- Using CTE to perform calculation on partition by in previous query 

with pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as (
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) over (
partition by dea.location 
order by dea.location, dea.date) as rolling_people_vaccinated
from covid_deaths dea
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent !='' 
order by dea.location, dea.date
)
select *, (rolling_people_vaccinated/population)*100
from pop_vs_vac;


-- Using Temp Table tp perform calculation on partition by in previous query 

drop table if exists percent_population_vaccinated

CREATE TEMPORARY TABLE percent_population_vaccinated
(continent VARCHAR(100), 
location VARCHAR(100), 
date DATE, 
population BIGINT(20), 
new_vaccinations BIGINT(20), 
rolling_people_vaccinated BIGINT(20));

INSERT INTO percent_population_vaccinated
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) over (
partition by dea.location 
order by dea.location, dea.date) as rolling_people_vaccinated
from covid_deaths dea  
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent !='' 
order by dea.location, dea.date);

select *, (rolling_people_vaccinated/population)*100
from percent_population_vaccinated;


-- Create VIEW to store data for later visualization 

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) over (
partition by dea.location 
order by dea.location, dea.date) as rolling_people_vaccinated
from covid_deaths dea  
join covid_vaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent !='' 
-- order by dea.location, dea.date


