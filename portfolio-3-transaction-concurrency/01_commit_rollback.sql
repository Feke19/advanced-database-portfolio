
-- TEST 1: Successful order, all steps COMMIT together

SELECT COUNT(*) AS orders_before FROM orders;
SELECT stock_quantity AS stock_before FROM products WHERE sku = 'SKU-TEST-001';

BEGIN;

INSERT INTO orders (customer_id, shipping_address_id) VALUES (1, 1);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT currval(pg_get_serial_sequence('orders','order_id')), product_id, 2, price
FROM products WHERE sku = 'SKU-TEST-001';

UPDATE products SET stock_quantity = stock_quantity - 2 WHERE sku = 'SKU-TEST-001';

UPDATE orders
SET total_amount = (SELECT SUM(quantity * unit_price) FROM order_items
                    WHERE order_id = currval(pg_get_serial_sequence('orders','order_id')))
WHERE order_id = currval(pg_get_serial_sequence('orders','order_id'));

INSERT INTO payments (order_id, method, amount, status, paid_at)
SELECT order_id, 'CARD', total_amount, 'SUCCESSFUL', NOW()
FROM orders WHERE order_id = currval(pg_get_serial_sequence('orders','order_id'));

UPDATE orders SET status = 'PAID'
WHERE order_id = currval(pg_get_serial_sequence('orders','order_id'));

COMMIT;

-- Verify: order exists, stock is 3, payment recorded
SELECT o.order_id, o.status, o.total_amount, p.status AS payment_status
FROM orders o JOIN payments p USING (order_id)
ORDER BY o.order_id DESC LIMIT 1;
SELECT stock_quantity AS stock_after FROM products WHERE sku = 'SKU-TEST-001';


-- TEST 2: Failed order, constraint violation triggers ROLLBACK

SELECT COUNT(*) AS orders_before FROM orders;

BEGIN;

INSERT INTO orders (customer_id, shipping_address_id) VALUES (1, 1);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT currval(pg_get_serial_sequence('orders','order_id')), product_id, 10, price
FROM products WHERE sku = 'SKU-TEST-001';

UPDATE products SET stock_quantity = stock_quantity - 10 WHERE sku = 'SKU-TEST-001';

ROLLBACK;

SELECT COUNT(*) AS orders_after FROM orders;  
SELECT stock_quantity FROM products WHERE sku = 'SKU-TEST-001';


-- TEST 3: Manual ROLLBACK (customer abandons checkout)

BEGIN;
INSERT INTO orders (customer_id, shipping_address_id) VALUES (1, 1);
SELECT COUNT(*) AS visible_inside_transaction FROM orders WHERE status = 'PENDING' AND customer_id = 1;
ROLLBACK;

SELECT COUNT(*) AS after_rollback FROM orders WHERE status = 'PENDING' AND customer_id = 1;


-- TEST 4: SAVEPOINT, partial rollback inside one transaction

BEGIN;

INSERT INTO orders (customer_id, shipping_address_id) VALUES (1, 1);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT currval(pg_get_serial_sequence('orders','order_id')), product_id, 1, price
FROM products WHERE sku = 'SKU-TEST-001';
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE sku = 'SKU-TEST-001';

SAVEPOINT before_jacket;

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT currval(pg_get_serial_sequence('orders','order_id')), product_id, 1, price
FROM products WHERE sku = 'SKU-TEST-002';
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE sku = 'SKU-TEST-002';

ROLLBACK TO SAVEPOINT before_jacket;   

UPDATE orders
SET total_amount = (SELECT SUM(quantity * unit_price) FROM order_items
                    WHERE order_id = currval(pg_get_serial_sequence('orders','order_id')))
WHERE order_id = currval(pg_get_serial_sequence('orders','order_id'));

COMMIT;

-- Verify: the order contains only the sneakers
SELECT oi.order_id, p.name, oi.quantity
FROM order_items oi JOIN products p USING (product_id)
WHERE oi.order_id = (SELECT MAX(order_id) FROM orders WHERE customer_id = 1);
