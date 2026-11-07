-- Portfolio 2: Business queries for KartHub
-- Run each one BEFORE and AFTER creating indexes (03_indexes.sql).
-- Save the output of each EXPLAIN into execution-plans/ (e.g. q1_before.txt, q1_after.txt).

-- Q1: Order history for one customer (a customer opens "My Orders")
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_date, status, total_amount
FROM orders
WHERE customer_id = 12345
ORDER BY order_date DESC;

-- Q2: Admin dashboard, pending orders from the last 30 days
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, total_amount, order_date
FROM orders
WHERE status = 'PENDING'
  AND order_date >= NOW() - interval '30 days';

-- Q3: Full order details for a customer, found by email (4-table join)
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.order_date, o.status, p.name, oi.quantity, oi.unit_price
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products p     ON p.product_id  = oi.product_id
WHERE c.email = 'user12345@karthub.test'
ORDER BY o.order_date DESC;

-- Q4: Top 10 best-selling products (aggregation across large tables)
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_id, p.name,
       SUM(oi.quantity)                AS units_sold,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.status <> 'CANCELLED'
GROUP BY p.product_id, p.name
ORDER BY units_sold DESC
LIMIT 10;

-- Q5: Monthly revenue from successful payments (last 12 months)
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('month', paid_at) AS month,
       COUNT(*)    AS payments,
       SUM(amount) AS revenue
FROM payments
WHERE status = 'SUCCESSFUL'
  AND paid_at >= NOW() - interval '12 months'
GROUP BY 1
ORDER BY 1;

-- Q6: Product browsing, items in a category within a price range, cheapest first
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, name, price
FROM products
WHERE category_id = 3
  AND price BETWEEN 10000 AND 30000
ORDER BY price
LIMIT 20;

-- Also run each query once WITHOUT "EXPLAIN (ANALYZE, BUFFERS)" and
-- screenshot the actual result rows as evidence of correct output.
