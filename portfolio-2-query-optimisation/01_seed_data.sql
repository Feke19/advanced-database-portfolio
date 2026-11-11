
INSERT INTO customers (first_name, last_name, email, phone, password_hash)
SELECT 'First' || g, 'Last' || g, 'user' || g || '@karthub.test',
       '080' || lpad(g::text, 8, '0'), md5(g::text)
FROM generate_series(1, 50000) g;

INSERT INTO addresses (customer_id, street, city, state, country, postal_code, is_default)
SELECT customer_id,
       (customer_id % 200 + 1) || ' Main Street',
       (ARRAY['Lagos','Abuja','Ibadan','Kano','Port Harcourt'])[customer_id % 5 + 1],
       'State', 'Nigeria', '100001', TRUE
FROM customers;

INSERT INTO categories (name)
SELECT 'Category ' || g FROM generate_series(1, 10) g;

INSERT INTO products (category_id, sku, name, description, price, stock_quantity)
SELECT (g % 10) + 1,
       'SKU-' || lpad(g::text, 6, '0'),
       'Product ' || g,
       'Description for product ' || g,
       round((random() * 95000 + 500)::numeric, 2),
       (random() * 500)::int
FROM generate_series(1, 5000) g;

INSERT INTO orders (customer_id, shipping_address_id, order_date, status, total_amount)
SELECT c, c,
       NOW() - make_interval(days => (random() * 730)::int),
       (ARRAY['PENDING','PAID','SHIPPED','DELIVERED','CANCELLED'])[(floor(random() * 5) + 1)::int],
       0
FROM (SELECT (floor(random() * 50000) + 1)::int AS c FROM generate_series(1, 200000)) s;


INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, (random() * 4)::int + 1, p.price
FROM orders o
CROSS JOIN generate_series(1, 3) k
JOIN products p ON p.product_id = ((o.order_id * 7 + k * 1301) % 5000) + 1;

UPDATE orders o
SET total_amount = t.total
FROM (SELECT order_id, SUM(quantity * unit_price) AS total
      FROM order_items GROUP BY order_id) t
WHERE o.order_id = t.order_id;

INSERT INTO payments (order_id, method, amount, status, paid_at)
SELECT order_id,
       (ARRAY['CARD','BANK_TRANSFER','WALLET','CASH_ON_DELIVERY'])[(floor(random() * 4) + 1)::int],
       total_amount, 'SUCCESSFUL', order_date + interval '5 minutes'
FROM orders
WHERE status IN ('PAID','SHIPPED','DELIVERED');

INSERT INTO deliveries (order_id, courier, tracking_number, status, shipped_at, delivered_at)
SELECT order_id,
       (ARRAY['DHL','GIG Logistics','FedEx'])[(floor(random() * 3) + 1)::int],
       'TRK' || lpad(order_id::text, 9, '0'),
       CASE WHEN status = 'DELIVERED' THEN 'DELIVERED' ELSE 'IN_TRANSIT' END,
       order_date + interval '1 day',
       CASE WHEN status = 'DELIVERED' THEN order_date + interval '4 days' END
FROM orders
WHERE status IN ('SHIPPED','DELIVERED');


ANALYZE;

-- Sanity check
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'deliveries', COUNT(*) FROM deliveries;
