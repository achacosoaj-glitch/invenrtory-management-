# Inventory Management System

A backend-only retail inventory REST API for Database Management Systems classwork. Laravel handles HTTP validation and JSON responses; MySQL Functions and Stored Procedures perform the required business calculations and inventory transactions. All demonstrations are run through Postman or SQL—there is no frontend.

## Objectives and technology

- Manage categories, suppliers, products, customers, sales, sale items, and stock movement history.
- Demonstrate actual MySQL stored functions, transactional stored procedures, SQL exception handling, and a Laravel REST API.
- PHP 8.2+, Laravel 12, MySQL 8+ (or compatible MariaDB), Composer, and Postman.

## Business rules

1. Product SKUs are unique and products require a category.
2. Prices are positive decimal amounts; stock and minimum-stock levels cannot be negative.
3. New products start at zero stock. Stock changes happen through the stock procedure.
4. A sale requires a valid customer, product, positive quantity, and sufficient stock.
5. A completed sale updates the sale, sale item, product inventory, and movement log atomically.
6. Cancellation restores each sold quantity once and records each movement.
7. SQL business-rule failures roll back and become meaningful JSON errors.

## Database design and SQL operations

The schema and required routines are under [`database/sql`](./database/sql):

1. `01_create_tables.sql` creates `inventory_management_db` and all seven InnoDB tables, constraints, and indexes.
2. `02_insert_sample_data.sql` inserts sample categories, suppliers, customers, products, and opening-stock movements.
3. `03_create_functions.sql` creates `fn_calculate_sale_total` and `fn_get_product_stock_status`.
4. `04_create_procedures.sql` creates `sp_create_sale`, `sp_add_product_stock`, and `sp_cancel_sale`.

The functions are also used by the Laravel API. The procedures contain the actual sale, stock adjustment, rollback, and cancellation business logic. See [`docs/DATABASE_DESIGN.md`](./docs/DATABASE_DESIGN.md) for relationships, behavior, and transaction details.

## Installation on Windows / PowerShell

The Laravel project is already created in this folder. If creating it separately from the parent folder, the exact Composer command is:

```powershell
composer create-project laravel/laravel inventory-management-system
```

In the project directory, install PHP dependencies and generate an application key:

```powershell
Set-Location C:\Users\Administrator\Documents\chuy\inventory-management-system
composer install
Copy-Item .env.example .env -ErrorAction SilentlyContinue
php artisan key:generate
```

Edit `.env` if your MySQL host, port, user, or password differs. The included defaults target a local XAMPP MySQL installation (`127.0.0.1:3306`, database `inventory_management_db`, user `root`, empty password). Start MySQL from the XAMPP Control Panel or your normal MySQL service manager.

Create the schema, sample records, functions, and procedures in order. With the XAMPP MySQL command-line client and no root password:

```powershell
& $env:ComSpec /c 'C:\xampp\mysql\bin\mysql.exe -u root < database\sql\01_create_tables.sql'
& $env:ComSpec /c 'C:\xampp\mysql\bin\mysql.exe -u root < database\sql\02_insert_sample_data.sql'
& $env:ComSpec /c 'C:\xampp\mysql\bin\mysql.exe -u root < database\sql\03_create_functions.sql'
& $env:ComSpec /c 'C:\xampp\mysql\bin\mysql.exe -u root < database\sql\04_create_procedures.sql'
```

If MySQL requires a password, add `-p` to each command and enter it when prompted. These SQL scripts create and use `inventory_management_db`; they do not drop existing tables or records.

Start Laravel:

```powershell
php artisan serve
```

The API base URL is `http://127.0.0.1:8000`. Laravel's `/up` health route is available for a basic application check.

## API endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET, POST | `/api/products` | List or create products |
| GET, PUT, DELETE | `/api/products/{id}` | Read, update, or delete an unreferenced product |
| GET, POST | `/api/categories` | List or create categories |
| GET, POST | `/api/suppliers` | List or create suppliers |
| GET, POST | `/api/customers` | List or create customers |
| GET | `/api/functions/calculate-sale-total?product_id=1&quantity=2` | Call `fn_calculate_sale_total` |
| GET | `/api/functions/product-stock-status/{id}` | Call `fn_get_product_stock_status` |
| POST | `/api/procedures/create-sale` | Call `sp_create_sale` |
| POST | `/api/procedures/add-stock` | Call `sp_add_product_stock` |
| POST | `/api/procedures/cancel-sale` | Call `sp_cancel_sale` |
| GET | `/api/reports/stock-movements` | Review inventory audit records |
| GET | `/api/reports/sales` | Review sale history |
| GET | `/api/reports/inventory` | Review inventory and SQL stock status |

Use `Accept: application/json`; POST/PUT requests use JSON. Input validation returns 422, missing resources 404, database conflicts 409, and unexpected database errors 500. Detailed requests and JSON shapes are in [`docs/API_DOCUMENTATION.md`](./docs/API_DOCUMENTATION.md).

## Postman demonstration

Import [`postman/Inventory_Management_API.postman_collection.json`](./postman/Inventory_Management_API.postman_collection.json) into Postman. The `baseUrl` collection variable defaults to `http://127.0.0.1:8000`; seeded IDs are product 1 and customer 1.

Suggested demonstration:

1. Run the function total and stock-status requests.
2. Create a successful sale. The collection test saves the returned `sale_id`.
3. Run add stock and inventory/movement/sales reports.
4. Run insufficient-stock and negative-quantity requests and verify their 422 responses.
5. Cancel the successful sale, confirm inventory was restored, and run cancellation again to verify duplicate cancellation is rejected.
6. Compare sale, sale item, product stock, and stock movement reports before and after each operation.

The expected success and failure payloads are described in each collection request. Postman test scripts verify the most important status codes and returned values.

## Running verification

Syntax-check the PHP files from the project directory:

```powershell
Get-ChildItem app,routes,bootstrap -Recurse -Filter *.php | ForEach-Object { php -l $_.FullName }
```

Laravel's test runner is:

```powershell
php artisan test
```

For database integration verification, MySQL must be running and all four SQL scripts must have been applied. `php artisan test` by itself does not substitute for the Postman/MySQL transaction demonstrations.
