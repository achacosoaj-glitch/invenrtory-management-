# Project explanation

This classwork project demonstrates a small retail stock and sales workflow using Laravel as an HTTP layer and MySQL as the source of truth for inventory transactions.

Laravel performs request-shape validation, binds parameters, and presents JSON responses. It does not calculate sale totals, check available stock, decrement inventory, or restore stock in PHP. Those business operations run in MySQL Functions and Stored Procedures.

The sale procedure locks the product row before checking stock. It saves the header, detail, stock update, and movement under one InnoDB transaction. If an SQL statement fails or a business rule uses `SIGNAL SQLSTATE '45000'`, its exception handler rolls the transaction back and rethrows the error. The API maps SQL business errors into a client-safe 422 response. This means a rejected sale cannot leave a sale header or partial stock change behind.

The stock replenishment procedure likewise couples the quantity update with its audit movement. Cancellation restores quantities and marks the sale cancelled in one transaction. It rejects already-cancelled sales so a repeated API request cannot replenish stock twice.

Products are created with zero stock; this forces nonzero inventory changes through the replenishment procedure, which records an audit row. The sample data records opening balances as `IN` movements.
