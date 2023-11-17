```sql

  /*
  1. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

Convert the week_date to a DATE format

Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

Add a month_number with the calendar month for each week_date value as the 3rd column

Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees

Add a new demographic column using the following mapping for the first letter in the segment values:

segment	demographic
C	Couples
F	Families
Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
*/

  select convert(date,week_date,3) as week_date,datepart(week,convert(date,week_date,3)) - datepart(week,datetrunc(month,convert(date,week_date,3))) as week_number,
  datepart(month,convert(date,week_date,3)) as month_number,datepart(year,convert(date,week_date,3)) as calendar_year,region,platform,segment,
   case when right(segment,1) = '1' then 'Young Adults'
   when right(segment,1) = '2' then 'Middle Aged'
   when right(segment,1) = '3' then 'Retirees'
   when right(segment,1) = '4' then 'Retirees'
   else 'unknown'end as age_band,
   case when left(segment,1) = 'C' then 'Couples'
   when left(segment,1) = 'F' then 'Families'
   else 'unknown' end as demographics,
  customer_type,transactions,sales,round(cast (sales as float)/ cast(transactions as float),2) as avg_transaction into clean_weekly_sales
  from weekly_sales


  /*2. Data Exploration
1. What day of the week is used for each week_date value?
2. What range of week numbers are missing from the dataset?
3. How many total transactions were there for each year in the dataset?
4. What is the total sales for each region for each month?
5. What is the total count of transactions for each platform
6. What is the percentage of sales for Retail vs Shopify for each month?
7. What is the percentage of sales by demographic for each year in the dataset?
8. Which age_band and demographic values contribute the most to Retail sales?
9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
*/

--1. What day of the week is used for each week_date value?
select datename(weekday,week_date) as day_of_week
from clean_weekly_sales
-- Every column show Monday is used for each week_date value

--2. What range of week numbers are missing from the dataset?
--I creatae a temp table that show the datediff of current row and the previous row. Then find which row return value that larger than 7 
with datediff_in_week_sales as (
select week_date, datediff(day,cast(lag(week_date)over(order by week_date) as date),week_date) as gap_in_week_sales
from (select distinct week_date from clean_weekly_sales) as t)
-- Find which column return value larger than 7 so that range of week is missing value
select concat(datepart(week,dateadd(day,-gap_in_week_sales + 7,week_date)),' ','of',' ',datepart(year,week_date)) as week_start_missing_value, 
concat(datepart(week,dateadd(day,-7,week_date )),' ','of',' ',datepart(year,week_date)) as week_end_missing_value
from datediff_in_week_sales
where gap_in_week_sales <> 7

--3. How many total transactions were there for each year in the dataset?
select calendar_year,sum(transactions) as total_transactions
from clean_weekly_sales
group by calendar_year

--4. What is the total sales for each region for each month?
select region,month_number,sum(cast(sales as float)) as total_sales
from clean_weekly_sales
group by region,month_number
order by region,month_number

--5. What is the total count of transactions for each platform
select platform,sum(transactions) as total_transactions
from clean_weekly_sales
group by platform

--6. What is the percentage of sales for Retail vs Shopify for each month?
select month_number,calendar_year,platform,sum(cast (sales as float)) as platform_total_sales,
concat(round(sum(cast (sales as float)) / sum(sum(cast (sales as float)))over(partition by month_number,calendar_year),4) * 100,'%') as percentage
from clean_weekly_sales
group by month_number,calendar_year,platform
order by calendar_year,month_number,platform

--7. What is the percentage of sales by demographic for each year in the dataset?
select demographic, calendar_year, sum(cast(sales as float)) as demographic_total_sales,
concat(round(sum(cast(sales as float)) / sum(sum(cast(sales as float))) over(partition by calendar_year),4) * 100,'%') as total_sales
from clean_weekly_sales
group by demographic, calendar_year

--8. Which age_band and demographic values contribute the most to Retail sales?
select age_band, demographic,platform,sum(cast (sales as float)) as total_sales
from clean_weekly_sales
where platform = 'Retail'
group by age_band,demographic,platform
order by sum(cast (sales as float)) desc
-- If we ignore the unknown value, then the Retirees with Family customers contribute the most to Retail sales

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

 select platform,calendar_year,(sum(cast(sales as float)) / sum(transactions)) as platform_average_each_year
 from clean_weekly_sales
 group by platform,calendar_year

 /*
 We cannot use avg_transaction column to find the average transaction size for each year for Retail vs Shopify because if we use avg_transaction to caculate, we will
 have the formula (sales1/trans1 + sales2/trans2 + sales3/trans3 + ...)/N.
 But the correct formula is(sales1+sales2+sales3+...)/(trans1+trans2+trans3+...)
 these two formula are different because trans1 <> trans2 <> trans3 <> etc
 */

 /*
 3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
*/

--1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with before_and_after_week as(
select week_date,sum(cast(sales as float)) as total_sales,
case when week_date < '2020-06-15' then '4_weeks_before'
when week_date >= '2020-06-15' then '4_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-4,'2020-06-15') and dateadd(week,3,'2020-06-15')
group by week_date)

select before_and_after,sum(total_sales) as total_sales,
case when lag(sum(total_sales))over(order by before_and_after) <> 0 then
concat(sum(total_sales) / lag(sum(total_sales))over(order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after


--2. What about the entire 12 weeks before and after?
with before_and_after_week as(
select week_date,sum(cast(sales as float)) as total_sales,
case when week_date < '2020-06-15' then '12_weeks_before'
when week_date >= '2020-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2020-06-15') and dateadd(week,11,'2020-06-15')
group by week_date)

select before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after

--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

--sale metrics in 2018
with before_and_after_week as(
select week_date,sum(cast(sales as float)) as total_sales,
case when week_date < '2018-06-15' then '12_weeks_before'
when week_date >= '2018-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2018-06-15') and dateadd(week,11,'2018-06-15')
group by week_date)

select before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after

--sale metrics in 2019
with before_and_after_week as(
select week_date,sum(cast(sales as float)) as total_sales,
case when week_date < '2019-06-15' then '12_weeks_before'
when week_date >= '2019-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2019-06-15') and dateadd(week,11,'2019-06-15')
group by week_date)

select before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after

/*
In 2018, this same metrics show that after 2018_06-15, sales have decreased more than 7.5%
In 2019, this number is decreased over 9.5%  
And in 2020, the sales just decreased 2.18%
At the first glance, We might conclude that this change cause negative impact on sales. 
People demand for some particular product may rise in some particular month. So we should include in the seasonal factors in our analysis
after the change, the decreased in sales is lower compare to 2018 and 2019. 
*/

--I create a table that compare sales in 2018,2019 and 2020 from 06-15 to 03-09
with sales_in_years as(
select concat('sales',' ','of',' ',calendar_year) as sales_year_after_06_15, sum(cast (sales as float)) as total_sales
from clean_weekly_sales
where week_date between '2018-06-15' and  dateadd(week,11,'2018-06-15')
group by calendar_year
union
select concat('sales',' ','of',' ',calendar_year) as  sales_year_after_06_15, sum(cast (sales as float)) as total_sales
from clean_weekly_sales
where week_date between '2019-06-15' and  dateadd(week,11,'2019-06-15')
group by calendar_year
union
select concat('sales',' ','of',' ',calendar_year) as  sales_year_after_06_15, sum(cast (sales as float)) as total_sales
from clean_weekly_sales
where week_date between '2020-06-15' and dateadd(week,11,'2020-06-15')
group by calendar_year)
select *,case when lag(total_sales)over(order by sales_year_after_06_15) <> 0 then
concat(total_sales / lag(total_sales)over(order by sales_year_after_06_15)*100-100,'%')
else 'N/A' end as percentage
from sales_in_years

/*
I have compared sales in 2020,2019 and 2018 after 06-15 in percentage
sales in 2019 increased 5.6%
and this number is 11.03% in 2020
rising in sales is a good sign to show that the change has possitive impact on customer behaviors
*/



/*
4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
*/


with before_and_after_week as(
select week_date,region,sum(cast(sales as float)) as total_sales,
case when week_date < '2020-06-15' then '12_weeks_before'
when week_date >= '2020-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2020-06-15') and dateadd(week,11,'2020-06-15')
group by week_date,region)

select region,before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(partition by region order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(partition by region order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after,region
order by region, before_and_after

--ASIA have the highest negative impact in sales metrics performance which is -3.26% but compare with this metrics in 2018 and 2019 which is -7.79% and -9.65%

with before_and_after_week as(
select week_date,region,sum(cast(sales as float)) as total_sales,
case when week_date < '2018-06-15' then '12_weeks_before'
when week_date >= '2018-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2018-06-15') and dateadd(week,11,'2018-06-15')
group by week_date,region)

select region,before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(partition by region order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(partition by region order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after,region
order by region, before_and_after

with before_and_after_week as(
select week_date,region,sum(cast(sales as float)) as total_sales,
case when week_date < '2019-06-15' then '12_weeks_before'
when week_date >= '2019-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2019-06-15') and dateadd(week,11,'2019-06-15')
group by week_date,region)

select region,before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(partition by region order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(partition by region order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after,region
order by region, before_and_after

-- The highest percentage decreased in sales does not mean that the change cause the highest negative impact on this region

-- Affect on platform
with before_and_after_week as(
select week_date,platform,sum(cast(sales as float)) as total_sales,
case when week_date < '2020-06-15' then '12_weeks_before'
when week_date >= '2020-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2020-06-15') and dateadd(week,11,'2020-06-15')
group by week_date,platform)

select platform,before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(partition by platform order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(partition by platform order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after,platform
order by platform, before_and_after

-- The change is related to product package quality. Sustainable packaging must have gained more trusted from Shopify's customer

with before_and_after_week as(
select week_date,age_band,sum(cast(sales as float)) as total_sales,
case when week_date < '2020-06-15' then '12_weeks_before'
when week_date >= '2020-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2020-06-15') and dateadd(week,11,'2020-06-15')
group by week_date,age_band)

select age_band,before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(partition by age_band order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(partition by age_band order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after,age_band
order by age_band, before_and_after

--demographic
with before_and_after_week as(
select week_date,demographic,sum(cast(sales as float)) as total_sales,
case when week_date < '2020-06-15' then '12_weeks_before'
when week_date >= '2020-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2020-06-15') and dateadd(week,11,'2020-06-15')
group by week_date,demographic)

select demographic,before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(partition by demographic order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(partition by demographic order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after,demographic
order by demographic, before_and_after

--customer_type
with before_and_after_week as(
select week_date,customer_type,sum(cast(sales as float)) as total_sales,
case when week_date < '2020-06-15' then '12_weeks_before'
when week_date >= '2020-06-15' then '12_weeks_after' end as before_and_after
from clean_weekly_sales
where week_date between dateadd(week,-12,'2020-06-15') and dateadd(week,11,'2020-06-15')
group by week_date,customer_type)

select customer_type,before_and_after,sum(total_sales) as total_sales,
case when lead(sum(total_sales))over(partition by customer_type order by before_and_after) <> 0 then
concat(sum(total_sales) / lead(sum(total_sales))over(partition by customer_type order by before_and_after) * 100 -100,'%')
else 'N/A' end as percentage
from before_and_after_week
group by before_and_after,customer_type
order by customer_type, before_and_after

-- The change has the highest negative impact on Guest customer_type


-- Compare with sales in 2018 and 2019. In overall, the change in packaging has possitive impact on sales in almost all areas and customer_type
