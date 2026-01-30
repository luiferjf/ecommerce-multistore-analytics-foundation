# Refresh Process — Foundation v1 (Manual Batch)

This project uses a manual batch refresh due to Hostinger MariaDB restrictions (no cross-DB `INSERT...SELECT`).

## Goal
Refresh staging tables from 4 WooCommerce sources and rebuild the analytics model safely (read-only from sources, no PII in repo).

---

## Step 0 — Preconditions
- DBeaver connected to:
  - Source DBs (read-only): RBN, PA (wp_3_*), VIC, NEB
  - Analytics DB: `u298795178_foundation_v1`
- Confirm target staging tables exist:
  - `stg_orders`
  - `stg_order_items`

---

## Step 1 — Extract (per store DB)
For each store (RBN / PA / VIC / NEB):
1. Run the store extract SQL in the **source DB**
2. Export results to CSV:
   - `orders_<STORE>.csv`
   - `order_items_<STORE>.csv`

> Keep exports local only (do not commit).

---

## Step 2 — Load (foundation DB)
In `u298795178_foundation_v1`:
1. TRUNCATE staging tables (or load into temp then swap if preferred)
2. Import CSVs via DBeaver:
   - Import `orders_<STORE>.csv` into `stg_orders`
   - Import `order_items_<STORE>.csv` into `stg_order_items`

---

## Step 3 — Rebuild model (dims/facts/views)
Run in this order (from `sql/`):
1. `ddl.sql`
2. `views.sql`

---

## Step 4 — Validate
Run:
- `sql/tests.sql`

Expected: all tests return `0` or `OK`.

---

## Step 5 — Publish
- Update any summary notes in `docs/foundation_v1.md` if totals/ranges changed.
- Push commits (docs/sql only; never data).
