```sql

/*
  A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
*/

/*
B. Data Analysis Questions
*/
--1. How many customers has Foodie-Fi ever had?
select count(distinct customer_id) as total_customer
from subscriptions
--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select datename(month,start_date) as month,count(customer_id) as total_customer
from subscriptions
where plan_id = 0
group by datename(month,start_date)
order by datename(month,start_date)

--3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select su.plan_id,plan_name,count(customer_id) as count_of_events
from subscriptions as su
left join plans on su.plan_id = plans.plan_id
where start_date > '2020-12-31'
group by plan_name,su.plan_id
order by su.plan_id

--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select plan_id,count(customer_id) as churned_number,
round((cast(count(customer_id) as decimal) /(select count(distinct customer_id ) from subscriptions )),2) as percentage
from subscriptions
where plan_id = 4
group by plan_id

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

select customer_id,plan_id, start_date into churned_customer
from subscriptions
where plan_id = 4

select count(ch.customer_id) as number_of_customer_churned_after_trial --into number_customer_churned
from churned_customer as ch 
left join (select customer_id,start_date from subscriptions where plan_id = 0)
as su on ch.customer_id = su.customer_id
where datediff(day,su.start_date,ch.start_date) < 8

--6. What is the number and percentage of customer plans after their initial free trial?

with plan_id_rank as (
select customer_id,plan_id,start_date,dense_rank()over(partition by customer_id order by start_date) as rank
from subscriptions)

select plan_name, count(customer_id) as total_customer,left( cast(count(customer_id) as decimal)/(select count(distinct customer_id) from subscriptions)*100,4) as percentage
from plan_id_rank as pl
left join plans on pl.plan_id = plans.plan_id
where rank = 2 and pl.plan_id <> 4
group by plan_name



--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with plan_rank_descending_order as (
select customer_id,plan_id,start_date,dense_rank()over(partition by customer_id order by start_date desc) as rank
from subscriptions
where start_date <= '2020-12-31')

select plan_name, count(customer_id) as total_number
from plan_rank_descending_order as pl
left join plans on pl.plan_id = plans.plan_id
where rank = 1 
group by plan_name


--8. How many customers have upgraded to an annual plan in 2020?

select * into pro_annual_customer
from subscriptions 
where plan_id =3

-- number of customer upgraded to annual plan after using other plans

select count(pr.customer_id) as total_customer_upgraded_to_annual_plan
from pro_annual_customer as pr
left join (select * from subscriptions where plan_id = 0) as su on pr.customer_id = su.customer_id
where pr.start_date <= '2020-12-31' and datediff(day,su.start_date,pr.start_date) > 7

-- total number of people buy annual plan
select count(*)
from subscriptions
where plan_id = 3 and start_date < '2020-12-31'

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

select avg(datediff(day,su.start_date,pr.start_date)) as average_day_to_annual_plan
from pro_annual_customer as pr
left join (select * from subscriptions where plan_id = 0) as su on pr.customer_id = su.customer_id
 
--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with value_breakdown as (
select pr.customer_id,datediff(day,su.start_date,pr.start_date) as average_day_to_annual_plan,
case when datediff(day,su.start_date,pr.start_date) <=30  then '0-30 days'
when datediff(day,su.start_date,pr.start_date) <= 60 then '31-60 days'
when datediff(day,su.start_date,pr.start_date) <= 90  then '61-90 days'
when datediff(day,su.start_date,pr.start_date) <= 120  then '91-120 days'
when datediff(day,su.start_date,pr.start_date) <= 150 then '121-150 days'
when datediff(day,su.start_date,pr.start_date) <= 180  then '151-180 days'
when datediff(day,su.start_date,pr.start_date) <= 210  then '181-210 days'
when datediff(day,su.start_date,pr.start_date) <= 240 then '211-240 days'
when datediff(day,su.start_date,pr.start_date) <=  270  then '241-270 days'
when datediff(day,su.start_date,pr.start_date) <=  300  then '271-300 days'
when datediff(day,su.start_date,pr.start_date) <=  330  then '301-330 days'
when datediff(day,su.start_date,pr.start_date) <=  360  then '331-360 days' end as value_break_down
from pro_annual_customer as pr
left join (select * from subscriptions where plan_id = 0) as su on pr.customer_id = su.customer_id)

select value_break_down, count(customer_id) as total_number, ceiling(avg(average_day_to_annual_plan))as average
from value_breakdown
group by value_break_down
order by 3

--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
-- create a temp table include all pro monthy customer

select * into pro_monthly_customer
from subscriptions
where plan_id = 2

--join two table with pro monthy and basic monthy, 
--if difference between pro monthly and basic monthy is possitive then customer downgraded to basic monthly from pro monthly

select count(pr.customer_id) as total_number
from pro_monthly_customer as pr
left join (select * from subscriptions where plan_id = 1) as su on pr.customer_id = su.customer_id
where datediff(day, pr.start_date, su.start_date) > 0



/*
C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments
*/
drop table cte
select  su.customer_id, su.plan_id,plan_name, start_date as payment_date, price as amount,
coalesce(lead(su.plan_id) over (partition by customer_id order by start_date) , 5)  as lead_plans,
lead(start_date)over(partition by customer_id order by start_date) as lead_date,
lead(price)over(partition by customer_id order by start_date) as lead_price into cte
from subscriptions as su 
left join plans on su.plan_id = plans.plan_id
order by su.customer_id,su.plan_id,start_date

CREATE FUNCTION generate_date_series
(
    @start_date DATE,
    @end_date DATE
)
RETURNS TABLE
AS
RETURN
(
    WITH DateSeries (DateValue) AS
    (
        SELECT @start_date AS DateValue
        UNION ALL
        SELECT DATEADD(month, 1, DateValue)
        FROM DateSeries
        WHERE DateValue <= dateadd(month,-1,@end_date)
    )
    SELECT DateValue
    FROM DateSeries
);

select *, case when datediff(month,payment_date,lead_date) < 1 and lead(amount)over(partition by customer_id order by lead_date) > amount 
 then lead(amount)over(partition by customer_id order by lead_date) - amount else amount end as actual_amount into generate_series_table
from cte
cross apply generate_date_series(payment_date, case when (lead_plans = 1 or lead_plans = 2) and lead_date < '2021-01-01' then lead_date
when plan_id = 3 then payment_date when lead_plans = 3 and lead_date < '2021-01-01' then lead_date
when lead_plans = 5 and lead_date < '2021-01-01' then '2020-12-31' when lead_plans = 4 and lead_date < '2021-01-01' then lead_date else'2020-12-31'
 end)
 where plan_id <>0 and plan_id <>4 and payment_date < '2021-01-01' 
 option (maxrecursion 365)

 select customer_id,plan_id,plan_name,DateValue as payment_date, 
 case when datediff(month,lag(DateValue)over(partition by customer_id order by DateValue),DateValue)< 1  
 then (amount - lag(amount)over(partition by customer_id order by DateValue)) else amount end as amount, 
 dense_rank()over(partition by customer_id order by DateValue) as payment_order --into final_table_payment
 from generate_series_table
 order by customer_id, DateValue

/*
D. Outside The Box Questions
The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, 
but answers that make sense from both a technical and a business perspective make an amazing impression!

How would you calculate the rate of growth for Foodie-Fi?

Different industry requires other method to caculate the rate of growth. For Foodie_Fi, I will caculate the total revenue divided by quarter, and compare
this quarter's revenue to this quarter last year. We should not compare with the previous quarter since seasonal can be a factor that affect total revenue. 
By comparing with last year quarter, we can evaluate the growth rate more accurately.

*/

select customer_id,plan_id,plan_name,DateValue as payment_date, 
 case when datediff(month,lag(DateValue)over(partition by customer_id order by DateValue),DateValue)< 1  
 then (amount - lag(amount)over(partition by customer_id order by DateValue)) else amount end as amount, 
 dense_rank()over(partition by customer_id order by DateValue) as payment_order --into final_table_payment
 from generate_series_table
 order by customer_id, DateValue

 
 select datepart(month,payment_date) as month, count( distinct customer_id) as total_customer, sum(amount) as total_revenue --into growth_rate_measure
 from final_table_payment
 group by datepart(month,payment_date) 

 select month,total_customer,left(cast(total_customer as decimal) / cast((lag(total_customer) over(order by month)) as decimal)*100 - 100,5) as customer_percentage_rate
 ,total_revenue, left((total_revenue / lag(total_revenue) over(order by month)) * 100 -100,5) as revenue_percentage_rate
 from growth_rate_measure

 --> because the dataset of Foodie-Fi is not enough to compare between year, so I compare recent month with the previous month
 -- the growth_rate of Foodie-fi is high during the beginning of the year and slowdown at the end of the year, it has 61 customers on January and 
 -- at the end of the year, this number is rising to 577 customers. Total revenue comes from 1272.10 to 12794.30, ten times. increasing ten times in sales 
 --is a very good sign. Foodie-fi is a good chance to invest money in 

-- What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

--I will track some key metrics as revenue and revenue growth over time, churn rate and customer lifetime value

-- churn rate
select  su.month, total_customer_churn,total_customer,left((cast(total_customer_churn as decimal)/cast(total_customer as decimal))*100,4) as percentage,total_revenue
from (select datepart(month,start_date) as month, count(customer_id) as total_customer_churn
from subscriptions as su
where plan_id = 4
group by datepart(month,start_date)) as su
left join growth_rate_measure as gr on su.month = gr.month

-- customer lifetime value

 select customer_id, case when  plan_id = 3 then 365 else datediff(day, first_value(payment_date) over (partition by customer_id order by payment_date), 
 last_value(payment_date) over (partition by customer_id order by payment_date)) end  as total_day --into lifetime_of_customer
 from final_table_payment

with rank_day as(
 select *,rank()over(partition by customer_id order by total_day desc) as rank
 from lifetime_of_customer)

 select avg(total_day) as average_lifetime_customer --into avg_customer_lifetime
 from rank_day
 where rank = 1

 --> Average lifetime of customer is 179 days

 select sum(total_revenue)/1000/365 as average_total_revenue --into average_total_revenue 
 from growth_rate_measure 

 select average_total_revenue, average_lifetime_customer, (average_total_revenue * average_lifetime_customer) as Customer_lifetime_value
 from average_total_revenue, avg_customer_lifetime
 
 --> customer lifetime value is about 50$, we should monitor and evaluate this metrics usually. If the metrics is rising, that could mean you should keep invest in recent marketing strategy and product development
 --If this metrics is on decline, then maybe recent marketing team and customer support is having some trouble


-- What are some key customer journeys or experiences that you would analyse further to improve customer retention?
--customer_retention = (Customer at the end of the period - New Customer) / Customer at the start of the period

-- Analyze customer who churn after any plans
-- Analyze customer who downgrade their plans
-- Analyze customer who churn right after trial
-- Analyze customer who upgrade their plans


--If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

-- Do you satisfied with our service?
-- If not, what characteristics are you not satisfied with our service ?
-- What factors can we upgrade that will make you change your decision ?
-- Why did you sign up our plans ?
-- Have you tried any similar service ? What is that service better than our ?

--What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

-- Use machine learning and some model to evaluate your customers and predict at-risk customer. 
-- Offer discount for this group of customer
-- Stay competitive and provide excellent customer service

-- We can use A/B testing to evaluate the process and focus on some key metrics like churn rate and customer retention. 
-- If churn rate is on decline and customer retention is rising, so your plasn must be effective
