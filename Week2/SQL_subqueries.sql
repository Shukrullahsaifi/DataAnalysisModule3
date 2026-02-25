USE coffeeshop_db;

-- =========================================================
-- Q1) Scalar subquery (AVG benchmark):
-- =========================================================
SELECT product_id, name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- =========================================================
-- Q2) Scalar subquery (MAX within category):
-- =========================================================
SELECT product_id, name, price
FROM products
WHERE price = (
    SELECT MAX(p.price)
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    WHERE c.name = 'Beans'
)
AND category_id = (SELECT category_id FROM categories WHERE name = 'Beans');

-- =========================================================
-- Q3) List subquery (IN with nested lookup):
-- =========================================================
SELECT customer_id, first_name, last_name
FROM customers
WHERE customer_id IN (
    SELECT o.customer_id
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE oi.product_id IN (
        SELECT product_id 
        FROM products 
        WHERE category_id = (SELECT category_id FROM categories WHERE name = 'Merch')
    )
);

-- =========================================================
-- Q4) List subquery (NOT IN / anti-join logic):
-- =========================================================
SELECT product_id, name, price
FROM products
WHERE product_id NOT IN (
    SELECT DISTINCT product_id 
    FROM order_items
);

-- =========================================================
-- Q5) Table subquery (derived table + compare to overall average):
-- =========================================================
SELECT product_id, product_name, total_units_sold
FROM (
    -- Derived table: Sales totals per product
    SELECT 
        p.product_id, 
        p.name AS product_name, 
        SUM(oi.quantity) AS total_units_sold
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.name
) AS ProductSales
WHERE total_units_sold > (
    -- Subquery: Average units sold across all products
    SELECT AVG(total_units)
    FROM (
        SELECT SUM(IFNULL(quantity, 0)) AS total_units
        FROM products p
        LEFT JOIN order_items oi ON p.product_id = oi.product_id
        GROUP BY p.product_id
    ) AS AvgSales
);