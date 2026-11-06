# REST API

Base URL: `http://127.0.0.1:8000`. Send `Accept: application/json`. JSON endpoints accept `Content-Type: application/json`. Validation errors are HTTP 422 with a `message` and field-specific `errors`; SQL business rule errors are HTTP 422; missing resources are 404; database conflicts are 409; unexpected database failures are logged and returned as HTTP 500.

## Resource endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/products` | List products with category and supplier names |
| GET | `/api/products/{id}` | Product detail |
| POST | `/api/products` | Create a product with initial stock of zero |
| PUT | `/api/products/{id}` | Update product details (inventory is changed only by procedures) |
| DELETE | `/api/products/{id}` | Delete an unreferenced product |
| GET / POST | `/api/categories` | List/create categories |
| GET / POST | `/api/suppliers` | List/create suppliers |
| GET / POST | `/api/customers` | List/create customers |

Product creation JSON:

```json
{
  "category_id": 1,
  "supplier_id": 1,
  "sku": "BEV-003",
  "product_name": "Sparkling Water 500ml",
  "description": "Carbonated drinking water",
  "price": 1.75,
  "minimum_stock": 4
}
```

## SQL function endpoints

- `GET /api/functions/calculate-sale-total?product_id=1&quantity=2` calls `SELECT fn_calculate_sale_total(?, ?)`.
- `GET /api/functions/product-stock-status/1` calls `SELECT fn_get_product_stock_status(?)`.

## Procedure endpoints

- `POST /api/procedures/create-sale`: `{"customer_id":1,"product_id":1,"quantity":2}`; invokes `CALL sp_create_sale(?, ?, ?)`. Success is 201.
- `POST /api/procedures/add-stock`: `{"product_id":1,"quantity":5,"remarks":"Restock"}`; invokes `CALL sp_add_product_stock(?, ?, ?)`.
- `POST /api/procedures/cancel-sale`: `{"sale_id":1}`; invokes `CALL sp_cancel_sale(?)`.

Every query parameter and procedure argument is bound, not interpolated into SQL. Stored procedure business rules are repeated at the database boundary so direct SQL callers receive the same protections.

## Reports

- `GET /api/reports/stock-movements`: inventory movement audit with product labels.
- `GET /api/reports/sales`: sale summaries and item line counts.
- `GET /api/reports/inventory`: product inventory plus the MySQL stock-status function result.

Import `postman/Inventory_Management_API.postman_collection.json` and run successful sale before cancellation; the collection test captures the returned sale ID automatically.
