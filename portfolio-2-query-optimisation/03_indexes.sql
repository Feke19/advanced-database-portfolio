
CREATE INDEX idx_orders_customer ON orders (customer_id, order_date DESC);

CREATE INDEX idx_orders_status_date ON orders (status, order_date);

CREATE INDEX idx_order_items_product ON order_items (product_id);

CREATE INDEX idx_payments_success_paid_at ON payments (paid_at) WHERE status = 'SUCCESSFUL';

CREATE INDEX idx_products_category_price ON products (category_id, price);

ANALYZE;

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

SELECT relname AS index_name, pg_size_pretty(pg_relation_size(oid)) AS size
FROM pg_class
WHERE relname LIKE 'idx_%'
ORDER BY pg_relation_size(oid) DESC;

