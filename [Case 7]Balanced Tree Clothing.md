```sql

 /*
  High Level Sales Analysis
1. What was the total quantity sold for all products?
2. What is the total generated revenue for all products before discounts?
3. What was the total discount amount for all products?
*/
--1. What was the total quantity sold for all products?
select sum(qty) as total_quantity
from sales
--2. What is the total generated revenue for all products before discounts?
select sum( qty * price) as total_revenue_before_discount
from sales

--3. What was the total discount amount for all products?
select sum((qty * price) * (0.01 *discount)) as total_discount_amount
from sales

-- revenue after discount
select sum( qty * price) - sum((qty * price) * (0.01 *discount))  as total_revenue
from sales

-- timerange of the dataset

select max(start_txn_time), min(start_txn_time)
from sales

-->In 3 months the store has sold 45216 products and has generated $1,133,223.86 in revenue 

/*
Transaction Analysis
1. How many unique transactions were there?
2. What is the average unique products purchased in each transaction?
3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
4. What is the average discount value per transaction?
5. What is the percentage split of all transactions for members vs non-members?
6. What is the average revenue for member transactions and non-member transactions?
*/


--1. How many unique transactions were there?
select count(distinct txn_id) as total_unique_transactions
from sales

--2. What is the average unique products purchased in each transaction?
select cast(count(prod_id) as float) / cast(count(distinct txn_id) as float)  as avg_units_purchased_per_transaction
from sales

-- each transaction has 6 product on average

--3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
with cte as(
select txn_id,member,sum((qty * price) - (0.01 * discount)*(qty*price)) as revenue
from sales
group by txn_id,member)
select distinct top 1 percentile_cont(0.25) within group (order by revenue)over() as first_quartile,
percentile_cont(0.50) within group (order by revenue)over() as median,
percentile_cont(0.75) within group (order by revenue)over() third_quartile
from cte

-- mode
with cte as(
select txn_id,member,sum((qty * price) - (0.01 * discount)*(qty*price)) as revenue
from sales
group by txn_id,member)
select top 1 revenue, count(*)
from cte
group by revenue
order by count(*) desc

--mean
with cte as(
select txn_id,member,sum((qty * price) - (0.01 * discount)*(qty*price)) as revenue
from sales
group by txn_id,member)
select sum(revenue) / count(revenue) as mean
from cte

--4. What is the average discount value per transaction?
select  sum((qty * price) * (0.01 *discount)) / count( distinct txn_id)  as average_discount_amount_per_transactions
from sales

--5. What is the percentage split of all transactions for members vs non-members?
select distinct member,sum((qty*price) - (qty*price) * (0.01*discount))over (partition by member) total_revenue_by_category,sum((qty*price) - (qty*price) * (0.01*discount))over () as total_revenue,
concat(left((sum((qty*price) - (qty*price) * (0.01*discount))over (partition by member) / sum((qty*price) - (qty*price) * (0.01*discount))over ())*100,5),'%') as percentage_split
from sales

-- revenue from member take 60.31% of the total revenue and nonmember just take 39.68% of the total revenue

--6. What is the average revenue for member transactions and non-member transactions?
with sum_transaction_total as (
select txn_id,member,sum(qty*price) - sum((qty*price) - (qty*price)*(0.01*discount)) as total_revenue
from sales
group by txn_id,member)
select member,sum(total_revenue) / count(txn_id) as average_revenue_transactions
from sum_transaction_total
group by member

/*
Product Analysis
1. What are the top 3 products by total revenue before discount?
2. What is the total quantity, revenue and discount for each segment?
3. What is the top selling product for each segment?
4. What is the total quantity, revenue and discount for each category?
5. What is the top selling product for each category?
6. What is the percentage split of revenue by product for each segment?
7. What is the percentage split of revenue by segment for each category?
8. What is the percentage split of total revenue by category?
9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
*/

--1. What are the top 3 products by total revenue before discount?
select top 3 prod_id,product_name,sum(qty*sales.price) as total_revenue_before_discount
from sales
left join product_details on sales.prod_id = product_details.product_id
group by prod_id, product_name
order by sum(qty*sales.price) desc

--2. What is the total quantity, revenue and discount for each segment?
select  segment_name,sum(qty) as total_quantity,sum(qty*sales.price) as total_revenue_before_discount,
sum((qty*sales.price) - (qty*sales.price)*(0.01*discount)) as total_discount
from sales
left join product_details on sales.prod_id = product_details.product_id
group by  segment_name

--3. What is the top selling product for each segment?
with rank_top_selling as(
select  product_name,segment_name,sum(qty) as total_quantity,sum(qty*sales.price) as total_revenue_before_discount,
 sum((qty*sales.price)*(0.01*discount)) as total_discount, rank() over(partition by segment_name order by sum(qty) desc) as rank
from sales
left join product_details on sales.prod_id = product_details.product_id
group by  product_name,segment_name)
select *
from rank_top_selling 
where rank = 1

--4. What is the total quantity, revenue and discount for each category?
select category_name, sum(qty) as total_quantity, sum(qty*sales.price) as total_revenue, sum((qty*sales.price)*(0.01*sales.price)) as total_discount
from sales
left join product_details as pr on sales.prod_id = pr.product_id
group by category_name

--5. What is the top selling product for each category?
with category_rank as(
select category_name , prod_id, product_name,sales.price, sum(qty) as total_quantity,  sum(qty*sales.price) as total_revenue, 
sum((qty*sales.price)*(0.01*sales.price)) as total_discount, rank()over(partition by category_name order by sum(qty) desc) as rank
from sales
left join product_details as pr on sales.prod_id = pr.product_id
group by category_name , prod_id, product_name,sales.price)
select *
from category_rank
where rank = 1
--> Top selling product for mens is Blue Polo Shirt with 3819 units sold
--> Top selling product for womens is Grey Fashion Jacket with 3876 units sold

--6. What is the percentage split of revenue by product for each segment?
select distinct product_name,segment_name,sales.price,sum(qty)over(partition by product_name) as total_quantity, sum(qty*sales.price) over ( partition by prod_id ) as product_revenue, 
sum(qty*sales.price)over(partition by segment_name) as segment_revenue, 
concat(left(( cast(sum(qty*sales.price) over ( partition by prod_id ) as float) / cast(sum(qty*sales.price)over(partition by segment_name)as float) ) *100,5),'%')
as product_revenue_percentage_split
from sales
left join product_details as pr on sales.prod_id = pr.product_id
order by segment_name

/*
--> every top product contribute the most to the segment have the highest price in that segment. Balanced Tree Clothing's customer 
must care about the product quality more than the price of the product. We should trade off the lower price to the product quality and 
launch new quality product rather than cheap product.
*/

--7. What is the percentage split of revenue by segment for each category?
select distinct segment_name, category_name, sum(qty*sales.price)over(partition by segment_name) as segment_revenue,
sum(qty*sales.price) over(partition by category_name) as category_revenue,
concat(left( cast(sum(qty*sales.price)over(partition by segment_name) as float) / cast(sum(qty*sales.price) over(partition by category_name) as float) *100,5),'%') 
as percentage_segment_revenue_for_category
from sales
left join product_details as pr on sales.prod_id = pr.product_id
order by category_name

/*
Men customer usually buy shirt product and they prefer quality product. Shirt product take 56.87% of total_revenue for men product
Socks take 43.12% of total revenue for men product. 
Women customer prefer buying Jacket to buying Jeans. Jacket product take up 63.78% of women product. They love buying jacket
and Jeans just take 36.21% of women product, just equal half of jacket.
*/

--8. What is the percentage split of total revenue by category?
select distinct segment_name, sum(qty*sales.price)over(partition by segment_name) as segment_revenue,
sum(qty*sales.price) over() as total_revenue,
concat(left( cast(sum(qty*sales.price)over(partition by segment_name) as float) / cast(sum(qty*sales.price) over( ) as float) *100,5),'%') 
as percentage_segment_revenue
from sales
left join product_details as pr on sales.prod_id = pr.product_id

/*
As i have caculated in the previous question. Jacket and Shirt is the two segment that contribute the most to the brand. 
Jacket product contribute 28.46% for total_revenue , Shirt product contribute 31.49% for total_revenue
men customer take up 55% of total_revenue when women customer take up 45% of total_revenue 
with this brand, men customer has bought more then women customer 10% of total_revenue
*/

--9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
select product_name,count(product_name) as total_transaction_buy, (select count(distinct txn_id)from sales) as total_transaction,
concat(left(cast(count(product_name)as float) / cast((select count(distinct txn_id)from sales) as float) *100 , 5),'%') as penetration
from sales
left join product_details as pr on sales.prod_id = pr.product_id
group by product_name
order by cast(count(product_name)as float) / cast((select count(distinct txn_id)from sales) as float) desc
