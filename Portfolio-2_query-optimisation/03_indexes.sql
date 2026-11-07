-- Portfolio 2: Indexes for KartHub
-- Run AFTER capturing the "before" plans for 02_queries.sql

-- Q1, Q3: foreign key lookups. PostgreSQL does NOT auto-index foreign keys.
CREATE INDEX idx_orders_customer ON orders (customer_id, order_date DESC);

-- Q2: composite index, equality column first (status), range column second (order_date)
CREATE INDEX idx_orders_status_date ON orders (status, order_date);

-- Q4: supports joins/aggregation by product (the PK only covers order_id first)
CREATE INDEX idx_order_items_product ON order_items (product_id);

-- Q5: partial index covering only successful payments
CREATE INDEX idx_payments_success_paid_at ON payments (paid_at) WHERE status = 'SUCCESSFUL';

-- Q6: composite index; also returns rows already sorted by price
CREATE INDEX idx_products_category_price ON products (category_id, price);

ANALYZE;

-- Review what exists
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Compare index sizes (cost of indexing = storage + slower writes)
SELECT relname AS index_name, pg_size_pretty(pg_relation_size(oid)) AS size
FROM pg_class
WHERE relname LIKE 'idx_%'
ORDER BY pg_relation_size(oid) DESC;

-- To re-run a "before" test later:  DROP INDEX idx_orders_customer;  (etc.)
