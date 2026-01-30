# SQL Run Order — Foundation v1

Run these scripts in MariaDB (`u298795178_foundation_v1`) using DBeaver.

## 1) Build / rebuild the model
1. `ddl.sql`  
   Creates dimension and fact tables (+ indexes).

2. `views.sql`  
   Creates KPI / metrics views.

> Note: Staging tables (`stg_orders`, `stg_order_items`) are loaded via CSV import (DBeaver) due to Hostinger cross-DB restrictions.

## 2) Validate
3. `tests.sql`  
   Minimal integrity + KPI reconciliation checks.
