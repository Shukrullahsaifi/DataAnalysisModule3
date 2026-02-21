-- ==================================
-- FILTERS & AGGREGATION
-- ==================================

USE coffeeshop_db;


-- Q1) Compute total items per order.
-- Return (order_id, total_items) from order_items.
SELECT order_id, COUNT(product_id) AS total_items
FROM order_items
GROUP BY order_id;

-- Q2) Compute total items per order for PAID orders only.
-- Return (order_id, total_items). 
SELECT order_id, COUNT(product_id) AS total_items
FROM order_items
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'paid')
GROUP BY order_id;

-- Q3) How many orders were placed per day (all statuses)?
-- Return (order_date, orders_count) from orders.
-- Note: DATE() extracts just the YYYY-MM-DD from a datetime.
SELECT DATE(order_datetime) AS order_date, COUNT(order_id) AS orders_count
FROM orders
GROUP BY order_date;

-- Q4) What is the average number of items per PAID order?
-- Use a subquery or CTE.
WITH PaidOrderCounts AS (
    SELECT order_id, COUNT(product_id) AS item_count
    FROM order_items
    WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'paid')
    GROUP BY order_id
)
SELECT AVG(item_count) AS avg_items_per_paid_order
FROM PaidOrderCounts;

-- Q5) Which products (by product_id) have sold the most units overall across all stores?
SELECT product_id, COUNT(*) AS total_units
FROM order_items
GROUP BY product_id
ORDER BY total_units DESC;

-- Q6) Among PAID orders only, which product_ids have the most units sold?
SELECT product_id, COUNT(*) AS total_units_paid
FROM order_items
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'paid')
GROUP BY product_id
ORDER BY total_units_paid DESC;

-- Q7) For each store, how many UNIQUE customers have placed a PAID order?
-- Return (store_id, unique_customers) using only the orders table.
SELECT store_id, COUNT(DISTINCT customer_id) AS unique_customers
FROM orders
WHERE status = 'paid'
GROUP BY store_id;

-- Q8) Which day of week has the highest number of PAID orders?
SELECT DAYNAME(order_datetime) AS day_name, COUNT(*) AS orders_count
FROM orders
WHERE status = 'paid'
GROUP BY day_name
ORDER BY orders_count DESC;

-- Q9) Show the calendar days whose total orders (any status) exceed 3.
-- Use HAVING.
SELECT DATE(order_datetime) AS order_date, COUNT(*) AS orders_count
FROM orders
GROUP BY order_date
HAVING orders_count > 3;

-- Q10) Per store, list payment_method and the number of PAID orders.
SELECT store_id, payment_method, COUNT(*) AS paid_orders_count
FROM orders
WHERE status = 'paid'
GROUP BY store_id, payment_method;

-- Q11) Among PAID orders, what percent used 'app' as the payment_method?
-- Return a single row with pct_app_paid_orders (0–100).
-- Note: We use 100.0 to ensure the division results in a decimal/float.
SELECT 
    (COUNT(CASE WHEN payment_method = 'app' THEN 1 END) * 100.0 / COUNT(*)) AS pct_app_paid_orders
FROM orders
WHERE status = 'paid';

-- Q12) Busiest hour: for PAID orders, show (hour_of_day, orders_count) sorted desc.
-- Note: HOUR() extracts the 0-23 value from the datetime.
SELECT 
    HOUR(order_datetime) AS hour_of_day, 
    COUNT(*) AS orders_count
FROM orders
WHERE status = 'paid'
GROUP BY hour_of_day
ORDER BY orders_count DESC;
