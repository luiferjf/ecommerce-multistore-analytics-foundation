# SQL Tests — Foundation v1

Minimal SQL checks to validate the **conformed layer (dims/facts)** and the **metrics views** for a multi-store WooCommerce analytics model.

**Database:** `u298795178_foundation_v1`  
**Run tool:** DBeaver (MariaDB)

---

## How to run
1. Open DBeaver connected to `u298795178_foundation_v1`
2. Run the SQL file: `sql/tests.sql` (top-to-bottom)
3. Compare outputs to the expectations below

> Source of truth for executable queries: **`sql/tests.sql`**  
> This document explains what each test means and what “OK” looks like.

---

## T1 — Uniqueness (Expected = 0)

Ensures keys are unique and stable.

- `dim_store`: no duplicate `store_code`
- `dim_date`: no duplicate `date_key`
- `fact_orders`: no duplicate `(store_key, order_id)`
- `fact_order_items`: no duplicate `(store_key, order_item_id)`

✅ Expected: all queries return `0`

---

## T2 — Orphans / FK integrity (Expected = 0)

Ensures facts do not reference missing dimension rows.

- `fact_orders` → `dim_store`
- `fact_orders` → `dim_date`
- `fact_order_items` → `dim_store`
- `fact_order_items` → `dim_date`
- `fact_order_items` → `dim_product`

✅ Expected: all queries return `0`

---

## T3 — Sanity checks (Expected = 0)

Ensures measures used by KPIs are not broken.

- `fact_orders.net_revenue`: not NULL, not negative
- `fact_order_items.quantity`: not NULL, not negative
- `fact_order_items.line_total`: not NULL, not negative

✅ Expected: all queries return `0`

---

## T4 — Date coverage (Expected = OK)

Ensures `dim_date` covers the full date range of `fact_orders`.

✅ Expected: `coverage_status = 'OK'`

---

## T5 — KPI reconciliation (Expected diffs = 0)

Ensures store totals from facts match the KPI view `vw_kpi_store_summary`.

✅ Expected:
- `diff_orders = 0`
- `diff_net_revenue = 0.00`

---

## Notes
- Order KPIs must be validated at **order grain** (`fact_orders`) to avoid double counting.
- Product mix uses **item-level revenue** (`fact_order_items.line_total`) and may not match order net revenue totals if shipping/tax/fees exist.
- This project stores **no PII** (no names/emails/addresses/phones).
