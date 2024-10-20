
-- SQL Data Cleaning

-- Check all values in the table to start off

select * 
from layoffs;

-- Goals for this project:
-- 1. Remove duplicates
-- 2. Standardize the Data
-- 3. Null values or blank values
-- 4. Remove any columns


-- 1. Remove duplicates

-- Create a duplicate table called table_staging to work on
create table layoffs_staging
like layoffs;

-- Copy all data from layoffs into layoffs_staging
insert layoffs_staging
select *
from layoffs;

-- Check for duplicates by creatinf row_num and check if any row > 1
with duplicate_cte as
(select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select * 
from duplicate_cte
where row_num > 1;

-- Choosing a random company to see if there are any possible duplicates
select * 
from layoffs_staging
where company = 'SiriusXM';

-- Attempting to delete directly from a CTE is not allowed in SQL.
-- CTEs are temporary result sets and cannot be targeted for DELETE operations
with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off,
'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
delete 
from duplicate_cte
where row_num > 1; -- This part will cause an error because you can't delete from a CTE.


-- Create a second duplicate table to remove the duplicates

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data from layoffs_staging to layoffs_staging2 adding a row_num column
-- row_num is created to check if there are any tables that have duplicate values

insert into layoffs_staging2 
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off,
'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging;

-- Deletion of the duplicates
delete
from layoffs_staging2
where row_num > 1;


-- 2. Stardardizing data

-- Check to observe the difference between trimmed and untrimmed data
select company, (trim(company))
from layoffs_staging2;

-- Update company table by trimming white spaces
update layoffs_staging2
set company = trim(company);

-- Update 'Crypto' and 'Cryto Currency' into one common industry
update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- Update 'United States' and 'United States.' into one common country
-- Use of trim(trailing '.' from country) to get rid of '.' using the trim function
select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%';

-- Update the data type of 'date' from text to date and also change its conventional format
update layoffs_staging2 
set date = str_to_date(`date`, '%m/%d/%Y'); 

alter table layoffs_staging2 
modify column  `date` DATE;

-- 3. Null values or blank values


select * 
from layoffs_staging2
where total_laid_off IS NULL
and percentage_laid_off IS NULL;

select * 
from layoffs_staging2
where industry IS NULL OR industry = '';

-- Update all blank values in industry to null to simplify the process
update layoffs_staging2
set industry = null
where industry = '';

-- Update the null values to their respective industry
UPDATE layoffs_staging2 
set industry = 'Travel'
where industry IS NULL and company = 'Airbnb';

UPDATE layoffs_staging2 
set industry = 'Travel'
where industry IS NULL and company = 'Bally''s Interactive';

-- Delete rows having NULL values for total_laid_off and percentage_laid_off
select *  
from layoffs_staging2
where total_laid_off IS NULL
and percentage_laid_off IS NULL;

delete 
from layoffs_staging2
where total_laid_off IS NULL
and percentage_laid_off IS NULL;

-- 4. Remove any columns

-- Remove the row_num column, which was initially used to check duplicate values
alter table layoffs_staging2
drop column row_num;

select * from layoffs_staging2; -- A final check 






