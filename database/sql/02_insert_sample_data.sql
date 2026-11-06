USE inventory_management_db;

INSERT INTO categories (id, category_name, description, created_at, updated_at)
VALUES
    (1, 'Beverages', 'Drinks and bottled beverages', NOW(), NOW()),
    (2, 'Snacks', 'Packaged snacks and treats', NOW(), NOW())
ON DUPLICATE KEY UPDATE category_name = VALUES(category_name);

INSERT INTO suppliers (id, supplier_name, contact_number, email, address, created_at, updated_at)
VALUES
    (1, 'Northstar Wholesale', '+1-555-0101', 'orders@northstar.example', '100 Market Street', NOW(), NOW()),
    (2, 'City Foods Supply', '+1-555-0102', 'sales@cityfoods.example', '25 Warehouse Road', NOW(), NOW())
ON DUPLICATE KEY UPDATE supplier_name = VALUES(supplier_name);

INSERT INTO customers (id, customer_name, email, contact_number, address, created_at, updated_at)
VALUES
    (1, 'Alex Rivera', 'alex.rivera@example.test', '+1-555-0201', '12 Oak Lane', NOW(), NOW()),
    (2, 'Jordan Lee', 'jordan.lee@example.test', '+1-555-0202', '38 Pine Street', NOW(), NOW())
ON DUPLICATE KEY UPDATE customer_name = VALUES(customer_name);

INSERT INTO products
    (id, category_id, supplier_id, sku, product_name, description, price, stock_quantity, minimum_stock, created_at, updated_at)
VALUES
    (1, 1, 1, 'BEV-001', 'Spring Water 500ml', 'Still drinking water', 1.50, 20, 5, NOW(), NOW()),
    (2, 1, 1, 'BEV-002', 'Orange Juice 1L', 'Orange juice carton', 3.25, 12, 4, NOW(), NOW()),
    (3, 2, 2, 'SNK-001', 'Oat Snack Bar', 'Oat and honey snack bar', 2.00, 8, 3, NOW(), NOW())
ON DUPLICATE KEY UPDATE sku = VALUES(sku);

INSERT INTO stock_movements
    (product_id, movement_type, quantity, previous_stock, new_stock, reference_id, remarks, created_at)
SELECT p.id, 'IN', p.stock_quantity, 0, p.stock_quantity, NULL, 'Opening sample inventory', NOW()
FROM products p
WHERE p.id IN (1, 2, 3)
  AND NOT EXISTS (
      SELECT 1 FROM stock_movements sm
      WHERE sm.product_id = p.id AND sm.remarks = 'Opening sample inventory'
  );
