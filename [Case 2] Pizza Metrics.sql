``` sql


CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');
  



CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" DATETIME
);


INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');



CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');



CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" nvarchar(36)
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" nvarchar(36)
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');



  -- cleaning exclusions and extras column
  with cte as(
  select order_id,customer_id,pizza_id, case when exclusions = 'null' then '' else exclusions end as exclusions,
  case when extras ='null' then '' else extras end as extras,order_time
  from customer_orders)

  select order_id,customer_id,cast (pizza_id as integer) as pizza_id,exclusions,coalesce(extras,'') as extras, order_time into cleaned_customer_orders
  from cte

  

--1.  How many pizzas were ordered?

select count(*)
from cleaned_customer_orders

--2. How many unique customer orders were made?

select count(distinct customer_id)
from cleaned_customer_orders

--3. How many successful orders were delivered by each runner?

select  runner_id , count(c.order_id) as order_delivered
from cleaned_customer_orders as c
left join runner_orders on c.order_id = runner_orders.order_id
where c.order_id not in (select order_id from runner_orders where pickup_time = 'null')
group by runner_id

--4. How many of each type of pizza was delivered?

select pizza_id, count(c.order_id) as order_delivered
from cleaned_customer_orders as c
left join runner_orders on c.order_id = runner_orders.order_id
where c.order_id not in (select order_id from runner_orders where pickup_time = 'null')
group by pizza_id

--5. How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id,case when pizza_id = 1 then 'Meat Lovers' when pizza_id = 2 then 'Vegeterians' end as pizza_name,count(customer_id) as total_ordered
from cleaned_customer_orders as c
group by customer_id,case when pizza_id = 1 then 'Meat Lovers' when pizza_id = 2 then 'Vegeterians' end 

--6. What was the maximum number of pizzas delivered in a single order?

select top 1  count(customer_id) as number_pizza_ordered
from cleaned_customer_orders
group by order_id
order by count(customer_id) desc

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select customer_id, count(order_id)
from cleaned_customer_orders
where len(exclusions) > 0 or len(extras) > 0
group by customer_id

--8. How many pizzas were delivered that had both exclusions and extras?

select count(order_id)
from cleaned_customer_orders
where len(exclusions) > 0 and len(extras) > 0

--9. What was the total volume of pizzas ordered for each hour of the day?

-- hour for each day
select day(order_time) as day,datepart(hour,order_time) as hour, count(order_id) as order_each_hour
from cleaned_customer_orders
group by day(order_time),datepart(hour,order_time)

-- hour of the day
select datepart(hour,order_time) as hour, count(order_id) as order_each_hour
from cleaned_customer_orders
group by datepart(hour,order_time)

-- highest volume usually happen at 13,18,21 and 23. At this time of the day, people order pizza for lunch, dinner and late dinner

--10. What was the volume of orders for each day of the week?

select datename(weekday,order_time) as day_of_week, count(order_id) as order_each_day
from cleaned_customer_orders
group by datename(weekday,order_time)

--> customer prefer order pizza on Saturday and Wednesday, Danny can incearse sales on these day by offering discount and voucher for Saturday and Wednesday


--[B] Runner and Customer Experience

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select  (datediff(week,'2021-01-01',registration_date) + 1)  as registration_week, count(runner_id) as runner_signed_up
from runners
group by (datediff(week,'2021-01-01',registration_date) + 1)

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select runner_id, right(convert(char(8),dateadd(second,avg(datediff(second,order_time,pickup_time)),0),108),5) as time_moving_to_headquarter
from runner_orders as r
left join customer_orders as c on r.order_id = c.order_id
where pickup_time <> 'null'
group by runner_id

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

with cte2  as(
select c.order_id as order_id,count(runner_id) as number_pizza_ordered, avg(datediff(second,order_time,pickup_time)) as time_moving_to_headquarter
from runner_orders as r
left join customer_orders as c on r.order_id = c.order_id
where pickup_time <> 'null'
group by c.order_id )
select number_pizza_ordered,avg(time_moving_to_headquarter)
from cte2
group by number_pizza_ordered

--> number of pizza do affect the time store take to prepare the order

--4. What was the average distance travelled for each customer?

select  r2.customer_id,  avg(cast(replace(( distance),'km','') as float))
from (select distinct c.order_id,c.customer_id,distance,pickup_time from runner_orders as r
left join customer_orders as c on r.order_id = c.order_id) as r2
where pickup_time <> 'null'
group by r2.customer_id


--5. What was the difference between the longest and shortest delivery times for all orders?

select cast(max(left(duration,2)) as numeric) - cast(min(left(duration,2))as numeric) as difference_between_longest_and_shortest
from runner_orders
where pickup_time <> 'null'

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

select runner_id,
left(round(avg((cast(replace(replace(replace(duration,'minutes',''),'mins',''),'minute','') as numeric)/ cast(replace(distance,'km','') as numeric)) ),3),4)
as average_speed
from runner_orders
where pickup_time <> 'null'
group by runner_id

--7. What is the successful delivery percentage for each runner?

with total_orders as(
select runner_id,count(order_id) as total_orders
from runner_orders
group by runner_id)

select r2.runner_id,r2.order_delivered,total_orders,concat((cast(order_delivered as float)/cast(total_orders as float))*100 ,'%') as successful_percentage
from(select r.runner_id, count(order_id) as order_delivered
from runner_orders as r
left join total_orders as t on r.runner_id = t.runner_id
where pickup_time <> 'null'
group by r.runner_id) as r2
left join total_orders as t on r2.runner_id = t.runner_id


-------C. Ingredient Optimisation

--1. What are the standard ingredients for each pizza?


select pizza_id,trim(value ) as topping_id into pizza_topping
from pizza_recipes
cross apply string_split(cast(toppings as nvarchar(32)),',')

select pizza_id,topping_name into topping_in_pizza
from pizza_topping 
left join pizza_toppings as id on pizza_topping.topping_id = id.topping_id

select pizza_id,string_agg(cast(topping_name as nvarchar(max)),',') as standard_ingredients
from topping_in_pizza
group by pizza_id


--2. What was the most commonly added extra?
with added_cte as(
select  top 1 trim(value) as extra_split, count(order_id) as number_added
from cleaned_customer_orders as cl
cross apply string_split(extras,',')
where len(extras) > 0
group by trim(value))

select topping_name,number_added
from added_cte
left join pizza_toppings on added_cte.extra_split = pizza_toppings.topping_id


--3. What was the most common exclusion?

with excluded_cte as(
select trim(value) as excluded_split, count(order_id) as number_excluded
from cleaned_customer_orders as cl
cross apply string_split(exclusions,',')
where len(exclusions) > 0
group by trim(value) )


select topping_name,number_excluded,rank()over(order by number_excluded desc) as rank into rank_excluded_table
from excluded_cte
left join pizza_toppings on excluded_cte.excluded_split = pizza_toppings.topping_id

select topping_name,number_excluded
from rank_excluded_table
where rank = 1


--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

select order_id,extras,trim(value) as c,len(trim(value)) as len into test_table
from cleaned_customer_orders
cross apply string_split(extras,',')

drop table test_table

select order_id,extras, concat(' - ','Extra','  ',string_agg(cast(coalesce(topping_name,'') as nvarchar(16)),', ') ) as Extra_column into extra_table
from test_table
left join pizza_toppings on test_table.c = pizza_toppings.topping_id
where len(c) > 0
group by order_id,extras


select order_id,exclusions,trim(value) as c,len(trim(value)) as len into raw_exclusion_table
from cleaned_customer_orders
cross apply string_split(exclusions,',')


select order_id,exclusions, concat(' - ','Exclusion','  ',string_agg(cast(coalesce(topping_name,'') as nvarchar(16)),', ') ) as Exclusion_column into exclusions_table
from (select distinct order_id,exclusions,c from raw_exclusion_table) as raw_exclusion_table2
left join pizza_toppings on raw_exclusion_table2.c = pizza_toppings.topping_id
where len(c) > 0
group by order_id,exclusions

drop table exclusions_table

select cl.order_id,customer_id,order_time,concat(pizza_name,coalesce(exclusion_column,''),coalesce(extra_column,'')) as order_item
from cleaned_customer_orders as cl
left join exclusions_table on cl.exclusions = exclusions_table.exclusions and cl.order_id = exclusions_table.order_id
left join extra_table on cl.extras = extra_table.extras and cl.order_id = extra_table.order_id
left join pizza_names on cl.pizza_id = pizza_names.pizza_id 

--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- I create a distinct temp table for adding topping
select order_id,cl.pizza_id,exclusions,extras,case when len(extras) > 0 then concat(toppings,', ',extras) else toppings end as topping_added into added_table
from
(select distinct order_id,pizza_id,exclusions,extras
from cleaned_customer_orders ) as cl
left join pizza_recipes on cl.pizza_id = pizza_recipes.pizza_id

-- Create a temp table that excluded all the exclusions

with excluded_cte as(
select order_id,cl.pizza_id,exclusions,extras,cast(toppings as nvarchar(30)) as toppings,trim(value) as value_split
from (select distinct order_id,exclusions,extras,pizza_id from cleaned_customer_orders) as cl
left join pizza_recipes on cl.pizza_id = pizza_recipes.pizza_id
cross apply string_split(cast(toppings as nvarchar(max)),',')

except

select order_id,cl.pizza_id,exclusions,extras,cast(toppings as nvarchar(30))as toppings,trim(value) as value_split
from (select distinct order_id,exclusions,extras,pizza_id from cleaned_customer_orders) as cl
left join pizza_recipes on cl.pizza_id = pizza_recipes.pizza_id
cross apply string_split(cast(exclusions as nvarchar(max)),','))

--create excluded_topping_table 
select * into excluded_topping_table
from excluded_cte
-- add topping extras to the order
with extra_cte as(
select *
from excluded_topping_table

union all

select order_id,cl.pizza_id,exclusions,extras,cast(toppings as nvarchar(30)) as toppings,trim(value) as value_split
from (select distinct order_id,exclusions,extras,pizza_id from cleaned_customer_orders) as cl
left join pizza_recipes on cl.pizza_id = pizza_recipes.pizza_id
cross apply string_split(cast(extras as nvarchar(max)),',')
where len(trim(value)) > 0)

select * into extra_topping_table
from extra_cte

with cte_final as(
select order_id,pizza_id,exclusions,extras,topping_name,
case when count(topping_id) > 1 then concat(count(topping_id),'x',topping_name) 
else topping_name end as topping_in_order
from (
select cast(order_id as nvarchar(30)) as order_id,cast(pizza_id as nvarchar(30)) as pizza_id,cast(exclusions as nvarchar(30)) as exclusions,
cast(extras as nvarchar(30)) as extras,cast(topping_name as nvarchar(30)) as topping_name, topping_id
from extra_topping_table as ex
left join pizza_toppings on ex.value_split = pizza_toppings.topping_id) as cl
group by order_id,pizza_id,exclusions,extras,topping_name )


select order_id,pizza_id,exclusions,extras, string_agg(topping_in_order,', ') as topping_final into the_final_table
from cte_final
group by order_id,pizza_id,exclusions,extras


select cl.order_id,cl.pizza_id,concat(pizza_name,': ',topping_final) alphabetical_order
from cleaned_customer_orders as cl
left join the_final_table as t on  cl.order_id = t.order_id and cl.pizza_id = t.pizza_id and cl.exclusions = t.exclusions and cl.extras = t.extras
left join pizza_names on cl.pizza_id = pizza_names.pizza_id

--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

select cast(topping_name as nvarchar(30)) as topping_name,count(order_id) as order_time 
from extra_topping_table as ex
left join pizza_toppings on ex.value_split = pizza_toppings.topping_id
group by cast(topping_name as nvarchar(30))
order by count(order_id) desc


--D. Pricing and Ratings


    /* 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
	how much money has Pizza Runner made so far if there are no delivery fees? */

	select cast(pizza_name as nvarchar(16)) as pizza_name, sum(case when cl.pizza_id = 1 then 12 when cl.pizza_id = 2 then 10 end) as total_profit
	from cleaned_customer_orders as cl
	left join pizza_names on cl.pizza_id = pizza_names.pizza_id
	left join runner_orders on cl.order_id = runner_orders.order_id
	where pickup_time <> 'null'
	group by cast(pizza_name as nvarchar(16))

	/* 2. What if there was an additional $1 charge for any pizza extras?
	Add cheese is $1 extra */

	select cast(pizza_name as nvarchar(16)) as pizza_name, sum((case when len(extras) > 0 then (len(extras)+1)/2 else 0 end) +
	(case when cl.pizza_id = 1 then 12 when cl.pizza_id = 2 then 10 end)) as total_profit
	from cleaned_customer_orders as cl
	left join pizza_names on cl.pizza_id = pizza_names.pizza_id
	left join runner_orders on cl.order_id = runner_orders.order_id
	where pickup_time <> 'null'
	group by cast(pizza_name as nvarchar(16)),cl.pizza_id

	/* 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
	how would you design an additional table for this new dataset - generate a schema for this new table and insert 
	your own data for ratings for each successful customer order between 1 to 5. */

	/* 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
	customer_id
	order_id
	runner_id
	rating
	order_time
	pickup_time
	Time between order and pickup
	Delivery duration
	Average speed
	Total number of pizzas */


	/* 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - 
	  how much money does Pizza Runner have left over after these deliveries? */

	  select cast(pizza_name as nvarchar(16)) as pizza_name,cast(replace(distance,'km','') as float) * 0.3 as delivery_fees,
	  case when cl.pizza_id = 1 then 12 when cl.pizza_id = 2 then 10 end as total_revenue,
	  (case when cl.pizza_id = 1 then 12 when cl.pizza_id = 2 then 10 end) - (cast(replace(distance,'km','') as float) * 0.3)  as total_profit into total_profit_table
	from cleaned_customer_orders as cl
	left join pizza_names on cl.pizza_id = pizza_names.pizza_id
	left join runner_orders on cl.order_id = runner_orders.order_id
	where pickup_time <> 'null'
	
	select pizza_name,sum(total_revenue) as total_revenue,
	sum(delivery_fees) as total_delivery_fees ,concat(round((sum(delivery_fees)/sum(total_revenue)),3)*100,'%')  as devilery_percentage, 
	sum(total_profit) as total_profit,concat(round((sum(total_profit)/sum(total_revenue)),3)*100 , '%') as profit_percentage
	from total_profit_table
	group by pizza_name
	
