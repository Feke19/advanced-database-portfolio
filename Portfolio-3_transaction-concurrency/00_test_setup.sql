-- Portfolio 3: Test setup
-- Requires customer_id 1 and address_id 1 (created by portfolio-2/01_seed_data.sql).
-- If you skipped Portfolio 2, first run:
--   INSERT INTO customers (first_name,last_name,email,password_hash) VALUES ('Test','User','test@karthub.test','x');
--   INSERT INTO addresses (customer_id,street,city,country) VALUES (1,'1 Test St','Lagos','Nigeria');

INSERT INTO products (category_id, sku, name, description, price, stock_quantity)
VALUES
  (1, 'SKU-TEST-001', 'Limited Edition Sneakers', 'Transaction test item', 25000, 5),
  (1, 'SKU-TEST-002', 'Out-of-stock Jacket',      'Transaction test item', 40000, 0);

SELECT product_id, sku, name, price, stock_quantity
FROM products WHERE sku LIKE 'SKU-TEST-%';

-- RESET (run this between demos to restore the starting state)
-- UPDATE products SET stock_quantity = 5, price = 25000 WHERE sku = 'SKU-TEST-001';
-- UPDATE products SET stock_quantity = 0 WHERE sku = 'SKU-TEST-002';
