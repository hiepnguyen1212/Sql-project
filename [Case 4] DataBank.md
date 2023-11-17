```sql

/*
  A. Customer Nodes Exploration
1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
*/
--1. How many unique nodes are there on the Data Bank system?
select count(distinct node_id) as total_nodes
from customer_nodes

--2. What is the number of nodes per region?
select region_name,count(node_id) total_node
from customer_nodes
left join regions on customer_nodes.region_id = regions.region_id
group by region_name
order by count(node_id) desc

--3. How many customers are allocated to each region?
select region_name,count(distinct customer_id) total_customer
from customer_nodes
left join regions on customer_nodes.region_id = regions.region_id
group by region_name
order by count(customer_id) desc

--4. How many days on average are customers reallocated to a different node?
--count how many time a customer have been allocated till now
with point_table as(
select *,case when lag(node_id)over(partition by customer_id order by start_date) = node_id then 0 
when lag(node_id)over(partition by customer_id order by start_date) <> node_id then 1 end as point
from customer_nodes)
select customer_id, sum(point)+1 as allocated_time into allocated_time -- plus 1 because the point column did not count the first node of every customer
from point_table 
group by customer_id

--create table contain lastvalue, first value using windown function and rank it
with first_last as(
select *,first_value(start_date)over(partition by customer_id order by start_date ) as first_value,
last_value(start_date)over(partition by customer_id order by start_date ) as last_value
from customer_nodes)
select *,rank()over(partition by customer_id order by last_value desc) as rank into rank_lastvalue
from first_last 

--I caculate the average_time_to_allocated for each customer first then i take the average of that column
with average_time_customer as (
select rank_lastvalue.customer_id,region_id,datediff(day,first_value,last_value) as total_day,allocated_time,
round(cast(datediff(day,first_value,last_value) as float)/ cast(allocated_time as float),2) as average_time
from rank_lastvalue
left join allocated_time on rank_lastvalue.customer_id = allocated_time.customer_id
where rank = 1 )
select avg(average_time) as average_time_to_allocated
from average_time_customer

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- I create a table that include the different between each reallocation
with lag_date as(
select *,case when lag(node_id)over(partition by customer_id order by start_date) <> node_id
then lag(start_date)over(partition by customer_id order by start_date) else null end as previous_start_date
from customer_nodes)
select *,datediff(day,previous_start_date,start_date) as reallocation_days into reallocation_days
from lag_date
order by region_id

-- caculate median, 80th, 95th using percentile_cont
select distinct region_name, 
percentile_cont(0.5)within group (order by reallocation_days) over (partition by region_name)  as Median,
percentile_cont(0.8)within group (order by reallocation_days) over (partition by region_name) as eighty_percentile,
percentile_cont(0.95)within group (order by reallocation_days) over(partition by region_name) as ninety_five_percentile
from reallocation_days
left join regions on reallocation_days.region_id = regions.region_id


/*
B. Customer Transactions
1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?
*/


--1. What is the unique count and total amount for each transaction type?
select txn_type,count(customer_id) as unique_count, sum(txn_amount) as total_amount
from customer_transactions
group by txn_type

--2. What is the average total historical deposit counts and amounts for all customers?
select txn_type, round(cast(count(customer_id) as float)/cast(count(distinct customer_id) as float),2) as average_deposit_counts, 
round(cast(sum(txn_amount) as float) / cast(count(distinct customer_id) as float),2) as average_deposit_amounts
from customer_transactions
where txn_type = 'deposit'
group by txn_type

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with number_transactions as (
select customer_id,datepart(month,txn_date) as month, 
sum(case when txn_type = 'deposit' then 1 else 0 end) as number_deposit,
sum(case when txn_type = 'purchase' then 1 else 0 end) as number_purchase,
sum(case when txn_type = 'withdrawal' then 1 else 0 end) as number_withdrawal
from customer_transactions 
group by  customer_id,datepart(month,txn_date) )
select month,sum(case when number_deposit > 1 and number_purchase >= 1 or number_deposit > 1 and number_withdrawal >= 1 then 1 else 0 end) as total
from number_transactions
group by month 

--4. What is the closing balance for each customer at the end of the month?
-- I created a table that make deposit transaction possitive transaction while purchase and withdrawal negative transactions
with balance_affected as (
select customer_id,txn_date, datepart(month,txn_date) as month,txn_type,txn_amount,
case when txn_type ='deposit' then txn_amount 
when txn_type ='purchase' then -txn_amount 
when txn_type ='withdrawal' then -txn_amount end as amount
from customer_transactions)

-- Caculated ending_balance after every transaction
,ending_balance_after_transaction as(
select customer_id,txn_date,month,txn_type,amount,
sum(amount)over(partition by customer_id order by txn_date range between UNBOUNDED PRECEDING and current row) as ending_balance_after_transaction
from balance_affected )

-- select the last_value at the end of the month
select distinct customer_id,datepart(month,txn_date) as month_id, datename(month,txn_date) as month
,last_value(ending_balance_after_transaction)over(partition by customer_id,month order by month) as closing_balance_at_the_end_of_the_month  into monthly_closing_balance
from ending_balance_after_transaction

--5. What is the percentage of customers who increase their closing balance by more than 5%?
with percentage as(
select customer_id,month,closing_balance_at_the_end_of_the_month,
case when lag(closing_balance_at_the_end_of_the_month)over(partition by customer_id order by month_id ) > 0 then
cast(closing_balance_at_the_end_of_the_month as float) / cast(lag(closing_balance_at_the_end_of_the_month)over(partition by customer_id order by month_id ) as float)*100 
when lag(closing_balance_at_the_end_of_the_month)over(partition by customer_id order by month_id ) < 0 then 
cast(closing_balance_at_the_end_of_the_month as float) / cast(lag(closing_balance_at_the_end_of_the_month)over(partition by customer_id order by month_id ) as float)*-100
else null end as percentage
from monthly_closing_balance)
select count(distinct customer_id) as total_customer_increase_their_closing_balance_more_than_5_percent
from percentage
where percentage >=105


/*
C. Data Allocation Challenge
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

running customer balance column that includes the impact each transaction
customer balance at the end of each month
minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis?
*/
 --Option 1
 -- I have already create a table that show the closing balance at the end of the month
 select customer_id,month,closing_balance_at_the_end_of_the_month
 from monthly_closing_balance 

--Option 2
with balance_affected as (
select customer_id,txn_date, datepart(month,txn_date) as month,txn_type,txn_amount,
case when txn_type ='deposit' then txn_amount 
when txn_type ='purchase' then -txn_amount 
when txn_type ='withdrawal' then -txn_amount end as amount
from customer_transactions)
-- Caculated ending_balance after every transaction
,ending_balance_after_transaction as(
select customer_id,txn_date,month,txn_type,amount,
sum(amount)over(partition by customer_id order by txn_date range between UNBOUNDED PRECEDING and current row) as ending_balance_after_transaction
from balance_affected )
,previous_30_days as(
select customer_id,txn_date,ending_balance_after_transaction,
dateadd(day,-30,last_value(txn_date)over(partition by customer_id order by txn_date rows between current row and unbounded following) ) as previous_30_days
from ending_balance_after_transaction)

select distinct customer_id,avg(ending_balance_after_transaction) over (partition by customer_id) as average_in_previous_30_days
from previous_30_days
where txn_date >= previous_30_days

 --Option 3
-- I created a table that make deposit transaction possitive transaction while purchase and withdrawal negative transactions
 with balance_affected as (
select customer_id,txn_date, datepart(month,txn_date) as month,txn_type,txn_amount,
case when txn_type ='deposit' then txn_amount 
when txn_type ='purchase' then -txn_amount 
when txn_type ='withdrawal' then -txn_amount end as amount
from customer_transactions)
-- Caculated ending_balance after every transaction
select customer_id,txn_date,
sum(amount)over(partition by customer_id order by txn_date range between UNBOUNDED PRECEDING and current row) as ending_balance_after_transaction
from balance_affected
