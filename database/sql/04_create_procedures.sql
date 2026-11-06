USE inventory_management_db;

DROP PROCEDURE IF EXISTS sp_create_sale;
DROP PROCEDURE IF EXISTS sp_add_product_stock;
DROP PROCEDURE IF EXISTS sp_cancel_sale;

DELIMITER $$

CREATE PROCEDURE sp_create_sale(
    IN p_customer_id BIGINT UNSIGNED,
    IN p_product_id BIGINT UNSIGNED,
    IN p_quantity INT
)
BEGIN
    DECLARE v_price DECIMAL(12, 2);
    DECLARE v_stock INT UNSIGNED;
    DECLARE v_subtotal DECIMAL(12, 2);
    DECLARE v_sale_id BIGINT UNSIGNED;
    DECLARE v_now TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_price = NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than zero';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM customers WHERE id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer does not exist';
    END IF;

    SELECT price, stock_quantity
    INTO v_price, v_stock
    FROM products
    WHERE id = p_product_id
    FOR UPDATE;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product does not exist';
    END IF;

    IF v_price <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product price must be greater than zero';
    END IF;

    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    SET v_subtotal = fn_calculate_sale_total(p_product_id, p_quantity);

    INSERT INTO sales (customer_id, total_amount, sale_status, sale_date, created_at, updated_at)
    VALUES (p_customer_id, v_subtotal, 'COMPLETED', v_now, v_now, v_now);
    SET v_sale_id = LAST_INSERT_ID();

    INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
    VALUES (v_sale_id, p_product_id, p_quantity, v_price, v_subtotal);

    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity, updated_at = v_now
    WHERE id = p_product_id;

    INSERT INTO stock_movements
        (product_id, movement_type, quantity, previous_stock, new_stock, reference_id, remarks, created_at)
    VALUES
        (p_product_id, 'OUT', p_quantity, v_stock, v_stock - p_quantity, v_sale_id, 'Sale completed', v_now);

    COMMIT;

    SELECT v_sale_id AS sale_id, v_subtotal AS total_amount, 'COMPLETED' AS sale_status;
END$$

CREATE PROCEDURE sp_add_product_stock(
    IN p_product_id BIGINT UNSIGNED,
    IN p_quantity INT,
    IN p_remarks VARCHAR(500)
)
BEGIN
    DECLARE v_stock INT UNSIGNED;
    DECLARE v_new_stock INT UNSIGNED;
    DECLARE v_now TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_stock = NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than zero';
    END IF;

    SELECT stock_quantity INTO v_stock
    FROM products
    WHERE id = p_product_id
    FOR UPDATE;

    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product does not exist';
    END IF;

    SET v_new_stock = v_stock + p_quantity;

    UPDATE products
    SET stock_quantity = v_new_stock, updated_at = v_now
    WHERE id = p_product_id;

    INSERT INTO stock_movements
        (product_id, movement_type, quantity, previous_stock, new_stock, reference_id, remarks, created_at)
    VALUES
        (p_product_id, 'IN', p_quantity, v_stock, v_new_stock, NULL,
         COALESCE(NULLIF(TRIM(p_remarks), ''), 'Stock replenishment'), v_now);

    COMMIT;

    SELECT p_product_id AS product_id, v_stock AS previous_stock, v_new_stock AS stock_quantity;
END$$

CREATE PROCEDURE sp_cancel_sale(IN p_sale_id BIGINT UNSIGNED)
BEGIN
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    DECLARE v_status VARCHAR(20);
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_quantity INT UNSIGNED;
    DECLARE v_stock INT UNSIGNED;
    DECLARE v_now TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

    DECLARE sale_items_cursor CURSOR FOR
        SELECT product_id, quantity
        FROM sale_items
        WHERE sale_id = p_sale_id
        ORDER BY product_id
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT sale_status INTO v_status
    FROM sales
    WHERE id = p_sale_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sale does not exist';
    END IF;

    IF v_status = 'CANCELLED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sale is already cancelled';
    END IF;

    OPEN sale_items_cursor;

    restore_items: LOOP
        FETCH sale_items_cursor INTO v_product_id, v_quantity;

        IF v_done THEN
            LEAVE restore_items;
        END IF;

        SELECT stock_quantity INTO v_stock
        FROM products
        WHERE id = v_product_id
        FOR UPDATE;

        UPDATE products
        SET stock_quantity = stock_quantity + v_quantity, updated_at = v_now
        WHERE id = v_product_id;

        INSERT INTO stock_movements
            (product_id, movement_type, quantity, previous_stock, new_stock, reference_id, remarks, created_at)
        VALUES
            (v_product_id, 'IN', v_quantity, v_stock, v_stock + v_quantity, p_sale_id, 'Sale cancelled; stock restored', v_now);
    END LOOP;

    CLOSE sale_items_cursor;

    UPDATE sales
    SET sale_status = 'CANCELLED', updated_at = v_now
    WHERE id = p_sale_id;

    COMMIT;

    SELECT p_sale_id AS sale_id, 'CANCELLED' AS sale_status;
END$$

DELIMITER ;
