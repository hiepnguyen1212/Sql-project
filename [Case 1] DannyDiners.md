# Analysis question

```sql

 -- 1. What is the total amount each customer spent at the restaurant?
 
 select customer_id,sum(m.price) as total_amount
  from sales 
  left join menu as m on sales.product_id = m.product_id
  group by customer_id
  
-- 2. How many days has each customer visited the restaurant?

 SELECT customer_id,count(order_date) as day_visited
 from sales
 group by customer_id
 
-- 3. What was the first item from the menu purchased by each customer?

select distinct customer_id,first_value(m.product_name)over(partition by customer_id order by order_date)
from sales as s
left join menu as m on s.product_id = m.product_id
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 menu.product_name,count(customer_id) as order_time
from sales
left join menu on sales.product_id = menu.product_id
group by product_name
order by count(customer_id) desc


-- 5. Which item was the most popular for each customer?

with rank_table (customer_id,product_name,rank,order_time) as (
select  customer_id,menu.product_name, rank()over(partition by customer_id order by count(customer_id) desc) as rank,count(customer_id) as order_time
from sales
left join menu on sales.product_id = menu.product_id
group by customer_id,product_name )

select customer_id,product_name,order_time
from rank_table
where rank = 1



-- 6. Which item was purchased first by the customer after they became a member?

with date_rank (customer_id,order_date,product_name,rankday) as(
select sales.customer_id,order_date,product_name,rank()over(partition by sales.customer_id order by order_date) as rank
from sales
left join members on sales.customer_id = members.customer_id
left join menu on sales.product_id=menu.product_id
where order_date > join_date)

select customer_id,product_name
from date_rank
where rankday = 1

-- 7. Which item was purchased just before the customer became a member?

with date_rank (customer_id,order_date,product_name,rankday) as(
select sales.customer_id,order_date,product_name,rank()over(partition by sales.customer_id order by order_date desc) as rank
from sales
left join members on sales.customer_id = members.customer_id
left join menu on sales.product_id=menu.product_id
where order_date < join_date)

select customer_id,product_name,order_date
from date_rank
where rankday = 1

-- 8. What is the total items and amount spent for each member before they became a member?

select sales.customer_id,sum(price) as total_amount
from sales
left join members on sales.customer_id = members.customer_id
left join menu on sales.product_id=menu.product_id
where order_date < join_date
group by sales.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with points_table (customer_id,product_name,points) as(
select sales.customer_id,product_name,
case when product_name = 'ramen' then 10*price
when product_name='curry' then 10*price 
when product_name ='sushi' then 20*price end as points
from sales
left join members on sales.customer_id = members.customer_id
left join menu on sales.product_id=menu.product_id
)
select customer_id,sum(points) as total_points
from points_table
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?

with points_table (customer_id,product_name,order_date,points) as (
select sales.customer_id,product_name,order_date,
case when order_date > join_date then 20*price
when product_name = 'ramen' then 10*price
when product_name='curry' then 10*price 
when product_name ='sushi' then 20*price
end as points
from sales
left join members on sales.customer_id = members.customer_id
left join menu on sales.product_id=menu.product_id
where order_date < '2021-02-01')

select customer_id, sum(points) as total_points
from points_table
where customer_id <> 'C'
GROUP BY customer_id


--Join all the table to quickly derive insight without nedding to join the underlying table

select sales.customer_id,order_date,product_name,price,
case when order_date < join_date then 'N' 
WHEN order_date >= join_date then 'Y' else 'N' end as member into join_table
from sales
left join members on sales.customer_id = members.customer_id
left join menu on sales.product_id=menu.product_id


--Rank the product_name order by order_date before customers become members

/* 
I create a temp table to rank the order after customers become members. 
And the value is distinct because i believe in real case data, 
order_date should be recorded to every second
*/

select distinct sales.customer_id,order_date,product_name,rank()over(partition by sales.customer_id order by order_date) as ranking into members_order
from sales
left join members on sales.customer_id = members.customer_id
left join menu on sales.product_id=menu.product_id
where order_date >= join_date

-- I join the join_table with members_order table to highlight order that include in the loyalty program
select join_table.customer_id,join_table.order_date,join_table.product_name,price,member,ranking
from join_table
left join members_order on join_table.customer_id = members_order.customer_id 
and  join_table.order_date = members_order.order_date 
and join_table.product_name = members_order.product_name
```
