
INSERT INTO products (category_id, sku, name, description, price, stock_quantity)
VALUES
  (1, 'SKU-TEST-001', 'Limited Edition Sneakers', 'Transaction test item', 25000, 5),
  (1, 'SKU-TEST-002', 'Out-of-stock Jacket',      'Transaction test item', 40000, 0);

SELECT product_id, sku, name, price, stock_quantity
FROM products WHERE sku LIKE 'SKU-TEST-%';
