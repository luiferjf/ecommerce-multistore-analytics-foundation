/* =========================================================
   Foundation v1 — DDL (MariaDB / Hostinger)
   Staging + Star Schema (No PII)
   ========================================================= */

-- Optional (safe for fresh builds):
-- SET FOREIGN_KEY_CHECKS = 0;

-- =========================
-- 1) STAGING TABLES
-- =========================

CREATE TABLE IF NOT EXISTS stg_orders (
  store_code VARCHAR(10) NOT NULL,
  src_db VARCHAR(80) NULL,
  loaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  order_id BIGINT UNSIGNED NOT NULL,
  order_created_utc DATETIME NOT NULL,
  order_created_gmt DATETIME NULL,

  status_raw VARCHAR(50) NULL,
  net_revenue DECIMAL(12,2) NOT NULL,

  customer_key VARCHAR(100) NULL, -- optional non-PII identifier if present

  PRIMARY KEY (store_code, order_id),
  KEY idx_stg_orders_store_created (store_code, order_created_utc),
  KEY idx_stg_orders_created (order_created_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS stg_order_items (
  store_code VARCHAR(10) NOT NULL,
  src_db VARCHAR(80) NULL,
  loaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  order_item_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,

  product_id BIGINT UNSIGNED NOT NULL,
  variation_id BIGINT UNSIGNED NULL,
  sku VARCHAR(100) NULL,

  quantity DECIMAL(12,3) NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,

  PRIMARY KEY (store_code, order_item_id),
  KEY idx_stg_items_store_order (store_code, order_id),
  KEY idx_stg_items_store_product (store_code, product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =========================
-- 2) DIMENSIONS
-- =========================

CREATE TABLE IF NOT EXISTS dim_store (
  store_key INT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_code VARCHAR(10) NOT NULL,
  store_name VARCHAR(100) NOT NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  timezone_iana VARCHAR(64) NOT NULL DEFAULT 'UTC',
  src_db VARCHAR(80) NULL,
  notes VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (store_key),
  UNIQUE KEY uq_dim_store_code (store_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_date (
  date_key INT UNSIGNED NOT NULL,            -- YYYYMMDD
  date DATE NOT NULL,

  year SMALLINT NOT NULL,
  quarter TINYINT NOT NULL,
  month TINYINT NOT NULL,
  month_name VARCHAR(12) NOT NULL,
  day TINYINT NOT NULL,

  day_of_week_iso TINYINT NOT NULL,          -- 1=Mon ... 7=Sun
  day_name VARCHAR(12) NOT NULL,
  is_weekend TINYINT(1) NOT NULL,

  iso_year SMALLINT NOT NULL,
  iso_week TINYINT NOT NULL,                 -- 1..53 (ISO)
  iso_yearweek INT UNSIGNED NOT NULL,         -- YEARWEEK(date,3)

  week_start_date DATE NOT NULL,             -- Monday
  week_end_date DATE NOT NULL,               -- Sunday

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (date_key),
  UNIQUE KEY uq_dim_date_date (date),
  KEY idx_dim_date_iso (iso_year, iso_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_product (
  product_key BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_key INT UNSIGNED NOT NULL,
  store_code VARCHAR(10) NOT NULL,

  product_id BIGINT UNSIGNED NOT NULL,
  variation_id BIGINT UNSIGNED NOT NULL DEFAULT 0,   -- 0 = no variation
  sku VARCHAR(100) NOT NULL DEFAULT '',

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (product_key),
  UNIQUE KEY uq_dim_product (store_key, product_id, variation_id, sku),
  KEY idx_dim_product_store (store_key),
  KEY idx_dim_product_store_product (store_key, product_id),
  CONSTRAINT fk_dim_product_store
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =========================
-- 3) FACTS
-- =========================

CREATE TABLE IF NOT EXISTS fact_orders (
  store_key INT UNSIGNED NOT NULL,
  store_code VARCHAR(10) NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,

  order_created_utc DATETIME NOT NULL,
  date_key INT UNSIGNED NOT NULL,          -- FK dim_date

  status_raw VARCHAR(50) NULL,
  status_canonical VARCHAR(20) NOT NULL,   -- paid/pending/cancelled/refunded/other

  net_revenue DECIMAL(12,2) NOT NULL,

  src_db VARCHAR(80) NULL,
  loaded_at TIMESTAMP NULL,

  PRIMARY KEY (store_key, order_id),
  KEY idx_fact_orders_date (date_key),
  KEY idx_fact_orders_store_date (store_key, date_key),
  CONSTRAINT fk_fact_orders_store
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
  CONSTRAINT fk_fact_orders_date
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fact_order_items (
  store_key INT UNSIGNED NOT NULL,
  store_code VARCHAR(10) NOT NULL,

  order_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,

  order_created_utc DATETIME NOT NULL,
  date_key INT UNSIGNED NOT NULL,          -- FK dim_date
  product_key BIGINT UNSIGNED NOT NULL,    -- FK dim_product

  product_id BIGINT UNSIGNED NOT NULL,
  variation_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  sku VARCHAR(100) NOT NULL DEFAULT '',

  quantity DECIMAL(12,3) NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,

  src_db VARCHAR(80) NULL,
  loaded_at TIMESTAMP NULL,

  PRIMARY KEY (store_key, order_item_id),
  KEY idx_fact_items_order (store_key, order_id),
  KEY idx_fact_items_date (date_key),
  KEY idx_fact_items_product (product_key),

  CONSTRAINT fk_items_store
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
  CONSTRAINT fk_items_date
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
  CONSTRAINT fk_items_product
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional:
-- SET FOREIGN_KEY_CHECKS = 1;
