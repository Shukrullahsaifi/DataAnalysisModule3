USE coffeeshop_db;

-- =========================================================
-- BASICS PRACTICE
-- Instructions: Answer each prompt by writing a SELECT query
-- directly below it. Keep your work; you'll submit this file.
-- =========================================================

-- Q1) List all products (show product name and price), sorted by price descending.
select name, price
from products
order by price desc;

-- Q2) Show all customers who live in the city of 'Lihue'.
select *
from customers
where city = 'Lihue';
-- Q3) Return the first 5 orders by earliest order_datetime (order_id, order_datetime).
Select order_id, order_datetime
from orders
order by order_datetime asc
limit 5;
-- Q4) Find all products with the word 'Latte' in the name.
select *
from products
where name like '%latte';
-- Q5) Show distinct payment methods used in the dataset.
SELECT DISTINCT payment_method
FROM orders;
-- Q6) For each store, list its name and city/state (one row per store).
SELECT name, city, state
FROM stores;
-- Q7) From orders, show order_id, status, and a computed column total_items
--     that counts how many items are in each order.
SELECT order_id, status, COUNT(product_id) AS total_items
FROM order_items
JOIN orders USING(order_id)
GROUP BY order_id, status;
-- Q8) Show orders placed on '2025-09-04' (any time that day).
SELECT *
FROM orders
WHERE order_datetime LIKE '2025-09-04%';
-- Q9) Return the top 3 most expensive products (price, name).
SELECT price, name
FROM products
ORDER BY price DESC
LIMIT 3;
-- Q10) Show customer full names as a single column 'customer_name'
--      in the format "Last, First".
SELECT CONCAT(last_name, ', ', first_name) AS customer_name
FROM customers;
