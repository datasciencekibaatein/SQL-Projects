create database pizzaSaleAnalysis;
use pizzasaleanalysis;


create table orders(
	order_id int,
    date date,
    time time
    );
    
create table order_details(
	order_details_id int,
    order_id int,
    pizza_id text,
    quantity int
    );
    
-- total records 
select count(*) from order_details;


-- Retrieve the total number of orders placed.
select
	count(*) total_orders
from orders;
-- Calculate the total revenue generated from pizza sales.
select
	round(sum(od.quantity * p.price),2) as revenue
from order_details od
join pizzas p
on od.pizza_id = p.pizza_id;


-- Identify the highest-priced pizza.

select
	pt.name,
	round(sum(p.price * od.quantity),2) as revenue
from order_details od
join pizzas p 
on od.pizza_id = p.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.name
order by revenue desc
limit 1;

-- Identify the most common pizza size ordered.
SELECT 
    p.size, COUNT(od.order_details_id) AS pizza_count
FROM
    order_details od
        JOIN
    pizzas p ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY pizza_count DESC
LIMIT 1;
-- List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pt.name, SUM(od.quantity) AS pizza_quantity
FROM
    order_details od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY pizza_quantity DESC
LIMIT 5;


-- Join the necessary tables to find the total quantity of each pizza category ordered.
-- Determine the distribution of orders by hour of the day.
select
	hour(o.time),
    count(od.order_details_id) as orders
from orders o 
join order_details od
on o.order_id = od.order_id
group by hour(o.time);

select
	hour(time),
    count(order_id)
from orders
group by hour(time);

select
	quarter(date),
    count(order_id)
from orders
group by quarter(date);
-- Join relevant tables to find the category-wise distribution of pizzas.
select 
	category,
    count(name) pizzas
from pizza_types
group by category;
 
-- Group the orders by date and calculate the average number of pizzas ordered per day.
select
	avg(orders_d)
from
	(select 
		count(order_id) orders_d,
		date
	from orders
	group by date)t;
-- Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pt.pizza_type_id,
    pt.name,
    SUM(od.quantity * p.price) revenue
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.pizza_type_id , pt.name
ORDER BY revenue DESC
LIMIT 3;



-- Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
    pt.name,
    concat(ROUND(SUM(od.quantity * p.price) / (SELECT 
            ROUND(SUM(od.quantity * p.price), 2)
        FROM
            order_details od
                JOIN
            pizzas p ON p.pizza_id = od.pizza_id)*100,2),"%") percentage
FROM
    order_details od
        JOIN
    pizzas p ON p.pizza_id = od.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name;


-- Analyze the cumulative revenue generated over time.
select
	order_date,
    sum(revenue) over(order by order_date) as cum_sum
from
	(SELECT 
		o.date order_date, 
        SUM(od.quantity * p.price) revenue
	FROM
		orders o
			JOIN
		order_details od ON od.order_id = o.order_id
			JOIN
		pizzas p ON od.pizza_id = p.pizza_id
	GROUP BY o.date
	ORDER BY o.date)t;
-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select
	name,
    category,
    round(revenue,2) revenue,
    rnk
from
	(select
		category,
		name,
		revenue,
		rank() over(partition by category order by revenue) as rnk
	from
		(SELECT 
			pt.category,
			pt.name,
			SUM(od.quantity * p.price) revenue
		FROM
			pizza_types pt
				JOIN
			pizzas p ON pt.pizza_type_id = p.pizza_type_id
				JOIN
			order_details od ON od.pizza_id = p.pizza_id
		GROUP BY pt.category , pt.name)temp
        ) lst_table
	where rnk<=3;