USE coffeeshop_db;

-- =========================================================
-- Q1) Correlated subquery: Above-average order totals (PAID only)
-- =========================================================
SELECT 
    o.order_id, 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
    s.name AS store_name, 
    o.order_datetime, 
    SUM(oi.quantity * p.price) AS order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN stores s ON o.store_id = s.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'paid'
GROUP BY o.order_id, c.first_name, c.last_name, s.name, o.order_datetime
HAVING order_total > (
    SELECT AVG(sub_total)
    FROM (
        SELECT o2.order_id, SUM(oi2.quantity * p2.price) AS sub_total
        FROM orders o2
        JOIN order_items oi2 ON o2.order_id = oi2.order_id
        JOIN products p2 ON oi2.product_id = p2.product_id
        WHERE o2.status = 'paid' AND o2.store_id = o.store_id
        GROUP BY o2.order_id
    ) AS store_avg
)
ORDER BY store_name, order_total DESC;

-- =========================================================
-- Q2) CTE: Daily revenue and 3-day rolling average (PAID only)
-- =========================================================
WITH DailyRevenue AS (
    SELECT 
        s.name AS store_name,
        s.store_id,
        DATE(o.order_datetime) AS order_date,
        SUM(oi.quantity * p.price) AS revenue_day
    FROM orders o
    JOIN stores s ON o.store_id = s.store_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'paid'
    GROUP BY s.name, s.store_id, DATE(o.order_datetime)
)
SELECT 
    store_name, 
    order_date, 
    revenue_day,
    AVG(revenue_day) OVER (
        PARTITION BY store_id 
        ORDER BY order_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3day_avg
FROM DailyRevenue
ORDER BY store_name, order_date;

-- =========================================================
-- Q3) Window function: Rank customers by lifetime spend (PAID only)
-- =========================================================
SELECT 
    c.customer_id, 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
    SUM(oi.quantity * p.price) AS total_spend,
    DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * p.price) DESC) AS spend_rank,
    SUM(oi.quantity * p.price) / SUM(SUM(oi.quantity * p.price)) OVER () AS percent_of_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spend DESC;

-- =========================================================
-- Q4) CTE + window: Top product per store by revenue (PAID only)
-- =========================================================
WITH ProductRevenue AS (
    SELECT 
        s.name AS store_name, 
        p.name AS product_name, 
        cat.name AS category_name, 
        SUM(oi.quantity * p.price) AS product_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.store_id ORDER BY SUM(oi.quantity * p.price) DESC) as rn
    FROM orders o
    JOIN stores s ON o.store_id = s.store_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    WHERE o.status = 'paid'
    GROUP BY s.store_id, s.name, p.name, cat.name
)
SELECT store_name, product_name, category_name, product_revenue
FROM ProductRevenue
WHERE rn = 1
ORDER BY store_name;

-- =========================================================
-- Q5) Subquery: Customers who have ordered from ALL stores (PAID only)
-- =========================================================
SELECT customer_id, CONCAT(first_name, ' ', last_name) AS customer_name
FROM customers
WHERE customer_id IN (
    SELECT o.customer_id
    FROM orders o
    WHERE o.status = 'paid'
    GROUP BY o.customer_id
    HAVING COUNT(DISTINCT o.store_id) = (SELECT COUNT(*) FROM stores)
);

-- =========================================================
-- Q6) Window function: Time between orders per customer (PAID only)
-- =========================================================
SELECT * FROM (
    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
        o.order_id, 
        o.order_datetime, 
        LAG(o.order_datetime) OVER (PARTITION BY c.customer_id ORDER BY o.order_datetime) AS prev_order_datetime,
        TIMESTAMPDIFF(MINUTE, LAG(o.order_datetime) OVER (PARTITION BY c.customer_id ORDER BY o.order_datetime), o.order_datetime) AS minutes_since_prev
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.status = 'paid'
) temp
WHERE prev_order_datetime IS NOT NULL
ORDER BY customer_name, order_datetime;

-- =========================================================
-- Q7) View: Create a reusable order line view for PAID orders
-- =========================================================
CREATE OR REPLACE VIEW v_paid_order_lines AS
SELECT 
    o.order_id, o.order_datetime, o.store_id, s.name AS store_name,
    o.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.product_id, p.name AS product_name, cat.name AS category_name,
    oi.quantity, p.price AS unit_price,
    (oi.quantity * p.price) AS line_total
FROM orders o
JOIN stores s ON o.store_id = s.store_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE o.status = 'paid';

SELECT store_name, category_name, SUM(line_total) AS revenue
FROM v_paid_order_lines
GROUP BY store_name, category_name
ORDER BY revenue DESC;

-- =========================================================
-- Q8) View + window: Store revenue share by payment method (PAID only)
-- =========================================================
CREATE OR REPLACE VIEW v_paid_store_payments AS
SELECT 
    s.store_id, s.name AS store_name, o.payment_method, 
    SUM(oi.quantity * p.price) AS revenue
FROM orders o
JOIN stores s ON o.store_id = s.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'paid'
GROUP BY s.store_id, s.name, o.payment_method;

SELECT 
    store_name, payment_method, revenue,
    SUM(revenue) OVER (PARTITION BY store_id) AS store_total_revenue,
    revenue / SUM(revenue) OVER (PARTITION BY store_id) AS pct_of_store_revenue
FROM v_paid_store_payments
ORDER BY store_name, revenue DESC;

-- =========================================================
-- Q9) CTE: Inventory risk report (low stock relative to sales)
-- =========================================================
WITH UnitsSold AS (
    SELECT 
        o.store_id, 
        oi.product_id, 
        SUM(oi.quantity) AS total_units_sold
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY o.store_id, oi.product_id
)
SELECT 
    s.name AS store_name, 
    p.name AS product_name, 
    i.on_hand, 
    us.total_units_sold, 
    (us.total_units_sold - i.on_hand) AS units_gap
FROM UnitsSold us
JOIN inventory i ON us.store_id = i.store_id AND us.product_id = i.product_id
JOIN stores s ON us.store_id = s.store_id
JOIN products p ON us.product_id = p.product_id
WHERE i.on_hand < us.total_units_sold
ORDER BY units_gap DESC;