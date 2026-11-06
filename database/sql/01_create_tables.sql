CREATE DATABASE IF NOT EXISTS inventory_management_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE inventory_management_db;

CREATE TABLE IF NOT EXISTS categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(120) NOT NULL UNIQUE,
    description TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(160) NOT NULL,
    contact_number VARCHAR(40) NULL,
    email VARCHAR(255) NULL UNIQUE,
    address TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED NOT NULL,
    supplier_id BIGINT UNSIGNED NULL,
    sku VARCHAR(80) NOT NULL UNIQUE,
    product_name VARCHAR(180) NOT NULL,
    description TEXT NULL,
    price DECIMAL(12, 2) NOT NULL,
    stock_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    minimum_stock INT UNSIGNED NOT NULL DEFAULT 0,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT chk_products_price CHECK (price > 0),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id)
        REFERENCES categories (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers (id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_products_category (category_id),
    INDEX idx_products_supplier (supplier_id),
    INDEX idx_products_name (product_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(180) NOT NULL,
    email VARCHAR(255) NULL UNIQUE,
    contact_number VARCHAR(40) NULL,
    address TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sales (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    sale_status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    sale_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT chk_sales_total CHECK (total_amount >= 0),
    CONSTRAINT chk_sales_status CHECK (sale_status IN ('COMPLETED', 'CANCELLED')),
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id)
        REFERENCES customers (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_sales_date (sale_date),
    INDEX idx_sales_status (sale_status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sale_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sale_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL,
    CONSTRAINT chk_sale_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_sale_items_price CHECK (unit_price > 0 AND subtotal >= 0),
    CONSTRAINT fk_sale_items_sale FOREIGN KEY (sale_id)
        REFERENCES sales (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_sale_items_product FOREIGN KEY (product_id)
        REFERENCES products (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_sale_items_product (product_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stock_movements (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    movement_type VARCHAR(20) NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    previous_stock INT UNSIGNED NOT NULL,
    new_stock INT UNSIGNED NOT NULL,
    reference_id BIGINT UNSIGNED NULL,
    remarks VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_stock_movement_type CHECK (movement_type IN ('IN', 'OUT')),
    CONSTRAINT chk_stock_movement_quantity CHECK (quantity > 0),
    CONSTRAINT fk_stock_movements_product FOREIGN KEY (product_id)
        REFERENCES products (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_stock_movements_product_date (product_id, created_at),
    INDEX idx_stock_movements_reference (reference_id)
) ENGINE=InnoDB;
