# Foundation v1 — Multi-Store WooCommerce Analytics (Hostinger MariaDB)

## Goal
Build a portfolio-ready analytics foundation for 4 historical WooCommerce stores (RBN, PA, VIC, NEB) hosted in separate MariaDB databases on Hostinger, consolidated into one analytics DB without PII. Output is a conformed/star schema + KPI views ready for BI (Tableau) and reproducible batch refresh.

## Constraints (Hostinger)
- No cross-DB `INSERT...SELECT` (isolated DB users).
- ETL is batch/manual: **DBeaver Extract → CSV export → Import into analytics DB**.
- Source WooCommerce DBs remain **read-only**.
- Repository contains **no PII**.

## Data Model (Star Schema)
**Analytics DB:** `u298795178_foundation_v1`

### Staging (loaded from CSV)
- `stg_orders`  
  Grain: **1 row = 1 order**  
  Key: `(store_code, order_id)`  
  Canonical timestamp: `order_created_utc`

- `stg_order_items`  
  Grain: **1 row = 1 line item**  
  Key: `(store_code, order_item_id)`  
  Product fields available v1: `product_id`, `variation_id`, `sku`

### Dimensions
- `dim_store`  
  Maps `store_code` → store attributes (name, currency, timezone, notes).  
  Primary key: `store_key`

- `dim_date`  
  Calendar dimension covering min/max order dates.  
  Primary key: `date_key` (YYYYMMDD).  
  Includes ISO week fields: `iso_year`, `iso_week`, `iso_yearweek`, `week_start_date`.

- `dim_product` (v1 minimal)  
  Product surrogate key per store using available identifiers only.  
  Natural key: `(store_key, product_id, variation_id, sku)`  
  Primary key: `product_key`

### Facts
- `fact_orders`  
  Grain: **1 row = 1 order**  
  Primary key: `(store_key, order_id)`  
  Links: `store_key → dim_store`, `date_key → dim_date`  
  Measures: `net_revenue`  
  Status: `status_raw` + `status_canonical` (paid/pending/cancelled/refunded/other)

- `fact_order_items`  
  Grain: **1 row = 1 line item**  
  Primary key: `(store_key, order_item_id)`  
  Links: `store_key → dim_store`, `date_key → dim_date`, `product_key → dim_product`  
  Measures: `quantity`, `line_total`

## KPI / Metrics Views
- `vw_kpi_store_summary`  
  Per store: orders, net_revenue, AOV, units, ASP, units/order.

- `vw_kpi_daily_store`  
  Per store per day (joins `dim_date`): same metrics as above, ready for time series.

- `vw_revenue_mix_store`  
  Product mix per store using item-level revenue: `SUM(line_total)` and share of store totals.
  Note: item_revenue != order net_revenue if net_revenue includes shipping/tax/fees not present in line totals.

## KPI Definitions
- **Net Revenue (Order-level):** `SUM(fact_orders.net_revenue)`
- **Orders:** `COUNT(*)` from `fact_orders`
- **AOV:** `net_revenue / orders`
- **Units:** `SUM(fact_order_items.quantity)`
- **ASP (Avg Selling Price):** `net_revenue / units`
- **Units per Order:** `units / orders`
- **Item Revenue (Product-level):** `SUM(fact_order_items.line_total)` (used for mix)

## Refresh Process (Batch)
1) **Extract** from each source store DB (DBeaver):
   - Orders extract → CSV
   - Order items extract → CSV
2) **Import** CSVs into analytics DB tables:
   - `stg_orders`
   - `stg_order_items`
3) **Rebuild conformed layer** (idempotent reload order):
   - `dim_store` (upsert)
   - `dim_date` (truncate + rebuild)
   - `fact_orders` (truncate + load from staging)
   - `dim_product` (truncate + load from staging items)
   - `fact_order_items` (truncate + load with joins)
4) **Recreate views** (or use CREATE OR REPLACE):
   - `vw_kpi_store_summary`, `vw_kpi_daily_store`, `vw_revenue_mix_store`
5) **Run tests** (see `docs/tests_sql.md`).

## Design Notes
- Multi-store keying is enforced via `store_key` (surrogate), while `store_code` is kept for usability.
- Date is standardized to `order_created_utc`.
- PII is intentionally excluded (no customer emails, addresses, names).
- Joins avoid double-counting revenue (orders vs items aggregated separately).

## Store Codes / Sources
- RBN → `u298795178_rbn` (prefix `ohf_`)
- PA  → `u298795178_pasion` (multisite store in `wp_3_*`)
- VIC → `u298795178_victus` (prefix `wp_`)
- NEB → `u298795178_nebula` (prefix `wp_`)
