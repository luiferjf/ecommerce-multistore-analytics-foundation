# Data Dictionary — Foundation v1 (No PII)

This document describes the analytics tables and views in `u298795178_foundation_v1`.
Grains, keys, and KPI-related fields are included. No customer PII is stored or documented.

---

## Conventions
- **store_code**: store identifier (RBN, PA, VIC, NEB)
- **store_key**: surrogate key in `dim_store` used by all facts
- **date_key**: integer date key in YYYYMMDD format (e.g., 20230131)
- **UTC timestamps** are preferred for consistent time-series analytics

---

## Staging Tables (CSV-loaded)

### `stg_orders` (grain: 1 row = 1 order)
**Primary key (logical):** `(store_code, order_id)`

| Column | Type | Description |
|---|---|---|
| store_code | varchar | Store code (RBN/PA/VIC/NEB) |
| src_db | varchar | Source DB identifier (traceability) |
| loaded_at | timestamp | Load timestamp into analytics DB |
| order_id | bigint | WooCommerce order id |
| order_created_utc | datetime | Order created timestamp (UTC) |
| order_created_gmt | datetime | Original Woo field (may be null depending on store) |
| status_raw | varchar | Raw Woo status (e.g., wc-completed) |
| net_revenue | decimal | Net revenue per order (order-level measure) |
| customer_key | varchar | Non-PII customer identifier (if present) |

> Notes: `order_created_utc` is the canonical timestamp for `dim_date` joins.

---

### `stg_order_items` (grain: 1 row = 1 line item)
**Primary key (logical):** `(store_code, order_item_id)`

| Column | Type | Description |
|---|---|---|
| store_code | varchar | Store code |
| src_db | varchar | Source DB identifier |
| loaded_at | timestamp | Load timestamp |
| order_id | bigint | Parent order id |
| order_item_id | bigint | WooCommerce order item id |
| product_id | bigint | Product id |
| variation_id | bigint | Variation id (0 if not a variation) |
| sku | varchar | SKU (if available) |
| quantity | int | Units for the line item |
| line_total | decimal | Line item revenue (item-level measure) |

> Notes: item revenue is used for product mix and units-based KPIs.

---

## Dimensions

### `dim_store`
**Primary key:** `store_key`  
**Natural key:** `store_code`

| Column | Type | Description |
|---|---|---|
| store_key | int | Surrogate key |
| store_code | varchar | Store code |
| store_name | varchar | Friendly name |
| currency | varchar | Currency code (e.g., USD) |
| timezone | varchar | Reporting timezone (for reference) |
| notes | varchar | Free-form notes |

---

### `dim_date`
**Primary key:** `date_key` (YYYYMMDD)

| Column | Type | Description |
|---|---|---|
| date_key | int | YYYYMMDD date key |
| date | date | Calendar date |
| year | int | Calendar year |
| quarter | int | Calendar quarter (1–4) |
| month | int | Month number (1–12) |
| month_name | varchar | Month name |
| day | int | Day of month |
| day_of_week_iso | int | ISO day of week (1=Mon … 7=Sun) |
| day_name | varchar | Day name |
| is_weekend | tinyint | 1 if Sat/Sun |
| iso_year | int | ISO week-numbering year |
| iso_week | int | ISO week number |
| iso_yearweek | int | ISO year*100 + ISO week |
| week_start_date | date | Monday of the ISO week |

---

### `dim_product` (v1 minimal)
**Primary key:** `product_key`  
**Natural key:** `(store_key, product_id, variation_id, sku)`

| Column | Type | Description |
|---|---|---|
| product_key | bigint | Surrogate product key |
| store_key | int | Store FK |
| store_code | varchar | Store code (denormalized helper) |
| product_id | bigint | Product id |
| variation_id | bigint | Variation id |
| sku | varchar | SKU (if present) |

> Notes: v1 intentionally avoids category/attributes until a clean source is defined.

---

## Facts

### `fact_orders` (grain: 1 row = 1 order)
**Primary key:** `(store_key, order_id)`  
**Foreign keys:** `store_key → dim_store`, `date_key → dim_date`

| Column | Type | Description |
|---|---|---|
| store_key | int | Store FK |
| store_code | varchar | Store code (denormalized helper) |
| order_id | bigint | Order id |
| order_created_utc | datetime | Canonical order timestamp (UTC) |
| date_key | int | FK to `dim_date` (YYYYMMDD) |
| status_raw | varchar | Raw status |
| status_canonical | varchar | Canonical status bucket (paid/pending/cancelled/refunded/other) |
| net_revenue | decimal | Net revenue per order |

---

### `fact_order_items` (grain: 1 row = 1 line item)
**Primary key:** `(store_key, order_item_id)`  
**Foreign keys:** `store_key → dim_store`, `date_key → dim_date`, `product_key → dim_product`

| Column | Type | Description |
|---|---|---|
| store_key | int | Store FK |
| store_code | varchar | Store code (helper) |
| order_id | bigint | Parent order id |
| order_item_id | bigint | Order item id |
| order_created_utc | datetime | Timestamp inherited from order (UTC) |
| date_key | int | FK to `dim_date` |
| product_key | bigint | FK to `dim_product` |
| quantity | int | Units |
| line_total | decimal | Line revenue |

---

## Views (Metrics Layer)

### `vw_kpi_store_summary` (grain: 1 row = 1 store)
| Column | Description |
|---|---|
| store_code, store_name | Store identifiers |
| orders | Count of orders |
| net_revenue | Sum of order net revenue |
| aov | net_revenue / orders |
| units | Sum of item quantities |
| asp | net_revenue / units |
| units_per_order | units / orders |
| refreshed_at | View refresh timestamp |

---

### `vw_kpi_daily_store` (grain: 1 row = 1 store x 1 day)
Includes `dim_date` fields for reporting plus daily KPIs:
- orders, net_revenue, aov, units, asp, units_per_order

---

### `vw_revenue_mix_store` (grain: 1 row = 1 store x 1 product)
| Column | Description |
|---|---|
| product_id, variation_id, sku | Product identifiers |
| units | Units sold for the product |
| item_revenue | SUM(line_total) |
| pct_store_item_revenue | item_revenue / total store item revenue |
| pct_store_units | units / total store units |

> Note: `item_revenue` is item-level and may not equal `net_revenue` totals if orders include shipping/tax/fees.
