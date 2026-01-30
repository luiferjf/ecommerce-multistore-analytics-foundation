# How to Rebuild Foundation v1 (From Scratch)

This guide rebuilds the analytics model in MariaDB for `u298795178_foundation_v1`.
It assumes source WooCommerce DBs are **read-only** and exports are handled locally (not committed).

---

## 0) Preconditions
- You can connect in DBeaver to:
  - `u298795178_foundation_v1` (analytics DB)
  - each source store DB (read-only)
- You have local storage for CSV exports (never commit).

---

## 1) Create tables (schema)
Run in analytics DB:

1) `sql/ddl.sql`

This creates:
- staging: `stg_orders`, `stg_order_items`
- dims: `dim_store`, `dim_date`, `dim_product`
- facts: `fact_orders`, `fact_order_items`

---

## 2) Load staging (CSV import)
For each store (RBN/PA/VIC/NEB):
1) Extract from the source DB using DBeaver
2) Export to CSV locally:
   - `orders_<STORE>.csv`
   - `order_items_<STORE>.csv`
3) Import into analytics staging tables:
   - import orders CSV → `stg_orders`
   - import items CSV → `stg_order_items`

---

## 3) Populate conformed layer (dims/facts)
In analytics DB, run your load steps in this order:

1) `dim_store` (upsert 4 stores)
2) `dim_date` (build full coverage range)
3) `fact_orders` (load from `stg_orders` with `store_key`, `date_key`, `status_canonical`)
4) `dim_product` (load distinct products from `stg_order_items`)
5) `fact_order_items` (load from `stg_order_items` with `product_key`, `date_key`)

> The exact load queries depend on your local process, but the grain and keys are enforced by constraints and tests.

---

## 4) Create metrics views
Run:
- `sql/views.sql`

Outputs:
- `vw_kpi_store_summary`
- `vw_kpi_daily_store`
- `vw_revenue_mix_store`

---

## 5) Validate
Run:
- `sql/tests.sql`

Expected:
- all “count of issues” checks return `0`
- date coverage returns `OK`
- KPI diffs = 0 for reconciliation

---

## 6) Publish safely
- Do not commit CSVs or dumps
- Share only aggregated screenshots (KPI summaries / ERD)
- Follow `docs/security_privacy.md`
