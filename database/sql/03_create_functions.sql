USE inventory_management_db;

DROP FUNCTION IF EXISTS fn_calculate_sale_total;
DROP FUNCTION IF EXISTS fn_get_product_stock_status;

DELIMITER $$

CREATE FUNCTION fn_calculate_sale_total(
    p_product_id BIGINT UNSIGNED,
    p_quantity INT
)
RETURNS DECIMAL(12, 2)
READS SQL DATA
BEGIN
    DECLARE v_price DECIMAL(12, 2);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_price = NULL;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than zero';
    END IF;

    SELECT price INTO v_price
    FROM products
    WHERE id = p_product_id;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product does not exist';
    END IF;

    IF v_price <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product price must be greater than zero';
    END IF;

    RETURN v_price * p_quantity;
END$$

CREATE FUNCTION fn_get_product_stock_status(p_product_id BIGINT UNSIGNED)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE v_stock INT UNSIGNED;
    DECLARE v_minimum INT UNSIGNED;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_stock = NULL;

    SELECT stock_quantity, minimum_stock
    INTO v_stock, v_minimum
    FROM products
    WHERE id = p_product_id;

    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product does not exist';
    END IF;

    IF v_stock = 0 THEN
        RETURN 'OUT OF STOCK';
    ELSEIF v_stock <= v_minimum THEN
        RETURN 'LOW STOCK';
    END IF;

    RETURN 'IN STOCK';
END$$

DELIMITER ;
