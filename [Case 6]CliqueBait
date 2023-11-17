```sql

/*
2. Digital Analysis
Using the available datasets - answer the following questions using a single query for each one:

1. How many users are there?
2. How many cookies does each user have on average?
3. What is the unique number of visits by all users per month?
4. What is the number of events for each event type?
5. What is the percentage of visits which have a purchase event?
6. What is the percentage of visits which view the checkout page but do not have a purchase event?
7. What are the top 3 pages by number of views?
8. What is the number of views and cart adds for each product category?
9. What are the top 3 products by purchases?
*/

-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) as total_users
from users

--2. How many cookies does each user have on average?
select cast(count( cookie_id)as float) / cast(count(distinct user_id) as float) as cookie_each_users_have_on_average
from users 

--3. What is the unique number of visits by all users per month?
select month, count(visit_id) as total_visit
from (select distinct visit_id, cookie_id,datepart(month,event_time) as month from events ) as event
group by month
order by month

--4. What is the number of events for each event type?
select ev.event_name, count(event_time) as number_events
from events
left join event_identifier as ev on events.event_type = ev.event_type
group by event_name

--5. What is the percentage of visits which have a purchase event?
select concat(cast(count( distinct visit_id) as float )/ cast((select count(distinct visit_id ) from events) as float) * 100,'%')
as percentage_visits_have_purchased
from events
where event_type = 3

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
select concat(cast(count( distinct visit_id) as float) / cast((select count( distinct visit_id)
from events) as float) * 100,'%') as percentage_view_checkout_but_not_purchase
from events
where visit_id in ( select visit_id from events where page_id = 12)
and visit_id not in ( select visit_id from events where page_id = 13)

-- 7. What are the top 3 pages by number of views? 
select top 3 page_name,count(event_type) as total_view
from events
left join page_hierarchy as pa on events.page_id = pa.page_id
where event_type = 1
group by page_name
order by count(event_type) desc

--8. What is the number of views and cart adds for each product category?

select product_category, sum(case when event_type = 1 then 1 else 0 end) as total_views, 
sum(case when event_type = 2 then 1 else 0 end) as total_cart_adds,
concat((cast(sum(case when event_type = 2 then 1 else 0 end) as float) / cast(sum(case when event_type = 1 then 1 else 0 end)as float))* 100,'%')
as cart_add_percentage
from events
left join page_hierarchy as pa on events.page_id = pa.page_id
group by product_category

--9. What are the top 3 products by purchases?
select top 3 product_id, count(event_type) as total_purchases
from events
left join page_hierarchy as pa on events.page_id = pa.page_id
where visit_id in ( select visit_id from events where event_type = 3) and event_type = 2
group by product_id
order by count(event_type) desc


/*
3. Product Funnel Analysis
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

Use your 2 new output tables - answer the following questions:

1. Which product had the most views, cart adds and purchases?
2. Which product was most likely to be abandoned?
3. Which product had the highest view to purchase percentage?
4. What is the average conversion rate from view to cart add?
5. What is the average conversion rate from cart add to purchase?
*/


select  product_id ,
sum(case when event_type = 1 then 1 else 0 end) as total_viewed
, sum(case when event_type = 2 then 1 else 0 end) as total_added
, sum(case when purchased_decision <> 3 and event_type = 2 then 1 else 0 end) as total_added_but_do_not_buy
, sum(case when purchased_decision = 3 and event_type = 2 then 1 else 0 end) as total_purchased into new_output_table
from (select *,last_value(event_type) over (partition by visit_id order by event_time rows between current row and unbounded following) as purchased_decision from events ) as ev
left join page_hierarchy as pa on ev.page_id = pa.page_id
where product_id is not null
group by product_id
order by product_id

select product_category, sum(total_viewed) as total_viewed ,sum(total_added) as total_added,
sum(total_added_but_do_not_buy) as total_added_but_do_not_buy,sum(total_purchased) as total_purchased --into output_product_category
from new_output_table as ne
left join page_hierarchy as pa on ne.product_id = pa.product_id
group by product_category

--1. Which product had the most views, cart adds and purchases?
select *
from new_output_table
order by total_viewed desc
--> product 9 has the most views

select *
from new_output_table
order by total_added desc
--> product 7 has the most added

select *
from new_output_table
order by total_purchased desc
--> product 7 has the most purchased and product 9 has the second most purchased, the more product added in cart, the more product will be purchased


--2. Which product was most likely to be abandoned?
/* Overall, every product share the same number of purchased amount. Fluctuate from 697 to 754 with the second highest is 726, so it is hard to tell which product is likely to be abandoned.
Recently, product 3 was most likely to be abandoned. Although it has the same purchased number as product 4 but it has less viewed than product 4. Maybe people do not like that kind of Fish
product 7,8,9 has the most viewed and purchased, So maybe the company should run marketing campaign on shellfish product and apply sales off for others
*/

--3. Which product had the highest view to purchase percentage?
select *,  concat(round(cast(total_purchased as float) / cast(total_viewed as float),4) * 100,'%') as percentage
from new_output_table 
order by cast(total_purchased as float) / cast(total_viewed as float) desc
-- product 7 has the highest view to purchase percentage

--4. What is the average conversion rate from view to cart add?
select concat(cast(sum(total_added) as float) / cast(sum(total_viewed) as float) * 100,' ','%') as average_conversion_rate_added
from new_output_table

--5. What is the average conversion rate from cart add to purchase?
select concat(cast(sum(total_purchased) as float) / cast(sum(total_added) as float) * 100,' ','%') as average_conversion_rate_purchased
from new_output_table


/*
3. Campaigns Analysis
Generate a table that has 1 single row for every unique visit_id record and has the following columns:

user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

Some ideas you might want to investigate further include:

1. Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
2. Does clicking on an impression lead to higher purchase rates?
3. What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
4. What metrics can you use to quantify the success or failure of each campaign compared to eachother?
*/


select user_id,visit_id, visit_start_time, 
sum(case when event_type = 2 then 1 else 0 end ) as cart_adds ,
case when last_value = 3 then 1 else 0 end as purchase,
case when visit_start_time between '2020-01-01 00:00:00' and '2020-01-14 00:00:00' then 'BOGOF_Fishing_For_Compliments'
when visit_start_time between '2020-01-15 00:00:00' and '2020-01-28 00:00:00' then '25%_Off_Living_The_Lux_Life'
when visit_start_time between '2020-02-01 00:00:00' and '2020-03-31 00:00:00' then 'Half_Off_Treat_Your_Shellf(ish)' else 'No_campaign' end as campaign_name,
sum(case when event_type = 4 then 1 else 0 end ) as ad_impression,
sum(case when event_type = 5 then 1 else 0 end ) as ad_click  into unique_visit_id_analyze
from (select *,cast(left(first_value(event_time) over(partition by visit_id order by event_time),19) as datetime) as visit_start_time,
        last_value(event_type)over(partition by visit_id order by event_time rows between current row and unbounded following) as last_value from events) as ev
left join users on ev.cookie_id = users.cookie_id
group by user_id,visit_id,visit_start_time,last_value


select campaign_name, sum( case when purchase = 1 then cart_adds else 0 end ) as total_purchase
from unique_visit_id_analyze
group by campaign_name


select campaign_name,sum(ad_impression) as total_customer_have_ad_impression, 
sum(case when ad_impression = 1 then cart_adds else 0 end) as ad_impression_total_cart_add,
sum(case when ad_impression = 1 and purchase = 1 then cart_adds else 0 end) as ad_impression_total_purchase,
cast(sum(case when ad_impression = 1 and purchase = 1 then cart_adds else 0 end) as float) / cast(sum(ad_impression) as float) as ad_impression_average_purchased_per_customer,
sum(case when ad_impression = 0 then 1 else 0 end ) as total_customer_do_not_have_ad_impression,
sum(case when ad_impression = 0 then cart_adds else 0 end) as not_ad_impression_total_cart_add,
sum(case when ad_impression = 0 and purchase = 1 then cart_adds else 0 end) as not_ad_impression_total_purchase,
cast(sum(case when ad_impression = 0 and purchase = 1 then cart_adds else 0 end) as float) / cast(sum(case when ad_impression = 0 then 1 else 0 end )as float) as no_ad_impression_average_purchased_per_customer,
sum( case when ad_impression = 1 and ad_click = 0 then 1 else 0 end) as customer_have_ad_impression_but_do_not_click,
sum( case when ad_impression = 1 and ad_click = 0 then cart_adds else 0 end) as not_ad_click_cart_add,
sum( case when ad_impression = 1 and ad_click = 0 and purchase = 1 then cart_adds else 0 end) as not_ad_click_purchase
from unique_visit_id_analyze
group by campaign_name


-- The amount of customer who have ad impression is much smaller than the amount of customer who do not have ad impression. So compare the total purchase amount or total_cart_added will not give the correct result.
-- Instead, I caculate the amount each customer buy on average. each customer who have ad impression buy more than 4 product in average and customer who do not have ad impression just buy 1 product on average. 
--> Ad impression is very important for seafood industry. Danny should invest in their designing team to create more impress ad and they should apply ad impression to every customer.


select campaign_name, count(visit_id) as total_visit, sum(cart_adds) as total_cart_added, sum( case when purchase = 1 then cart_adds else 0 end) as total_purchase,
(cast( sum( case when purchase = 1 then cart_adds else 0 end) as float) / cast ( count(visit_id)  as float)) as average_purchase_per_customer,
case when campaign_name =  'BOGOF_Fishing_For_Compliments' then datediff(day,'2020-01-01','2020-01-14')
when campaign_name =  '25%_Off_Living_The_Lux_Life' then datediff(day,'2020-01-15','2020-01-28')
when campaign_name =  'Half_Off_Treat_Your_Shellf(ish)' then datediff(day,'2020-02-01','2020-03-31')
else null end as campaign_days,
count(visit_id) / case when campaign_name =  'BOGOF_Fishing_For_Compliments' then datediff(day,'2020-01-01','2020-01-14')
when campaign_name =  '25%_Off_Living_The_Lux_Life' then datediff(day,'2020-01-15','2020-01-28')
when campaign_name =  'Half_Off_Treat_Your_Shellf(ish)' then datediff(day,'2020-02-01','2020-03-31')
else null end  as average_customer_visit_per_day,
sum( case when purchase = 1 then cart_adds else 0 end) / case when campaign_name =  'BOGOF_Fishing_For_Compliments' then datediff(day,'2020-01-01','2020-01-14')
when campaign_name =  '25%_Off_Living_The_Lux_Life' then datediff(day,'2020-01-15','2020-01-28')
when campaign_name =  'Half_Off_Treat_Your_Shellf(ish)' then datediff(day,'2020-02-01','2020-03-31')
else null end  as average_purchase_per_day
from unique_visit_id_analyze
group by campaign_name


--because the percentage people purchased is quite similar. So the metrics i use to compare the success or failure to eachother is total_visit and profit each campaign gain to my business
--> so the campaign related to shellfish is the most success with very high number of visit time and number of purchase every day.
