# Database design

The canonical MySQL setup is in `database/sql`. Run scripts in numerical order against a MySQL 8+ or compatible MariaDB database. All business tables use InnoDB so procedure transactions can roll back all changes.

## Tables and relationships

- `categories`: unique category names; one category is required for every product.
- `suppliers`: supplier contact information; a deleted supplier leaves products intact with a null supplier reference.
- `products`: unique SKU, positive decimal price, non-negative integer inventory, and minimum-stock threshold. Category deletion is restricted.
- `customers`: customer details; customer records referenced by sales cannot be deleted.
- `sales`: customer, transaction total, status (`COMPLETED` or `CANCELLED`), and sale date.
- `sale_items`: immutable item/price snapshot for each sale. Product references are retained for audit history.
- `stock_movements`: append-only inventory audit including movement direction, quantity, before/after stock, and optional sale reference.

Foreign keys, unique constraints, checks, and indexes enforce referential integrity and common lookup paths. Monetary values use `DECIMAL(12,2)`.

## Functions

- `fn_calculate_sale_total(product_id, quantity)` reads the current product price and returns price multiplied by a positive quantity. Missing products, invalid quantities, and invalid prices raise SQLSTATE `45000`.
- `fn_get_product_stock_status(product_id)` returns `OUT OF STOCK` at zero, `LOW STOCK` at or below the product threshold, otherwise `IN STOCK`.

Both functions can be called in SQL and are used by the API, reports, and sale procedure.

## Procedures and atomicity

- `sp_create_sale(customer_id, product_id, quantity)` locks the product, checks customer/product/quantity/available stock, calls the total function, then inserts the sale and its item, reduces stock, and writes the movement. An `EXIT HANDLER FOR SQLEXCEPTION` rolls back and re-signals any error.
- `sp_add_product_stock(product_id, quantity, remarks)` locks the product, validates positive quantity, adjusts stock, and records the `IN` movement in the same transaction.
- `sp_cancel_sale(sale_id)` locks and validates the sale, restores each item’s stock, records each restoration, and marks the sale cancelled atomically. A second cancellation is rejected before changing stock.

The stored procedures own their transactions; Laravel intentionally does not wrap calls to them in an outer transaction.
