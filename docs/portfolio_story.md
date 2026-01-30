# Portfolio Story — Ecommerce Multistore Analytics Foundation (v1)

## Problem
I operated multiple WooCommerce stores over several years. Data lived in separate databases, making it hard to answer basic business questions consistently (revenue trends, AOV, units, product mix, store performance).

## What I built
A multi-store analytics foundation on Hostinger MariaDB:
- **Staging layer**: consolidated orders and line items from 4 stores into standardized tables.
- **Conformed layer (star schema)**: `dim_store`, `dim_date`, `dim_product` + `fact_orders`, `fact_order_items`.
- **Metrics layer**: KPI views for store summary, daily performance, and product mix.

## Data quality & correctness
I added SQL tests to validate:
- primary key uniqueness (dims/facts)
- no orphan records across facts → dims
- revenue sanity checks (no null/negative)
- KPI reconciliation (fact totals match KPI views)

## Outcome
A reusable structure that supports fast, reliable reporting across stores (store-level KPIs, daily trends, and product mix), with a batch refresh workflow and no PII committed to the repo.

## Next iteration (v2)
Add customer-level modeling (hashed identifiers), channel attribution (if available), and incremental refresh automation.
