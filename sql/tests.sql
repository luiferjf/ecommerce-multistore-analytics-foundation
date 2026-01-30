-- Minimal tests for Foundation v1

-- T1 Uniqueness
SELECT COUNT(*) - COUNT(DISTINCT store_code) AS dup_store_code FROM dim_store;
SELECT COUNT(*) - COUNT(DISTINCT date_key) AS dup_date_key FROM dim_date;
SELECT COUNT(*) - COUNT(DISTINCT CONCAT(store_key,'-',order_id)) AS dup_fact_orders FROM fact_orders;
SELECT COUNT(*) - COUNT(DISTINCT CONCAT(store_key,'-',order_item_id)) AS dup_fact_items FROM fact_order_items;

-- T2 Orphans
SELECT COUNT(*) AS orphan_fact_orders_store
FROM fact_orders fo LEFT JOIN dim_store s ON s.store_key = fo.store_key
WHERE s.store_key IS NULL;

SELECT COUNT(*) AS orphan_fact_orders_date
FROM fact_orders fo LEFT JOIN dim_date d ON d.date_key = fo.date_key
WHERE d.date_key IS NULL;

SELECT COUNT(*) AS orphan_fact_items_store
FROM fact_order_items fi LEFT JOIN dim_store s ON s.store_key = fi.store_key
WHERE s.store_key IS NULL;

SELECT COUNT(*) AS orphan_fact_items_date
FROM fact_order_items fi LEFT JOIN dim_date d ON d.date_key = fi.date_key
WHERE d.date_key IS NULL;

SELECT COUNT(*) AS orphan_fact_items_product
FROM fact_order_items fi LEFT JOIN dim_product p ON p.product_key = fi.product_key
WHERE p.product_key IS NULL;

-- T3 Sanity
SELECT SUM(net_revenue IS NULL) AS null_net_revenue, SUM(net_revenue < 0) AS neg_net_revenue
FROM fact_orders;

SELECT
  SUM(quantity IS NULL) AS null_qty,
  SUM(quantity < 0)     AS neg_qty,
  SUM(line_total IS NULL) AS null_line_total,
  SUM(line_total < 0)     AS neg_line_total
FROM fact_order_items;

-- T4 Coverage
SELECT
  MIN(d.date) AS dim_min_date,
  MAX(d.date) AS dim_max_date,
  MIN(DATE(fo.order_created_utc)) AS fact_min_date,
  MAX(DATE(fo.order_created_utc)) AS fact_max_date,
  CASE
    WHEN MIN(d.date) <= MIN(DATE(fo.order_created_utc))
     AND MAX(d.date) >= MAX(DATE(fo.order_created_utc))
    THEN 'OK' ELSE 'FAIL'
  END AS coverage_status
FROM dim_date d
CROSS JOIN fact_orders fo;

-- T5 Reconciliation
SELECT
  s.store_code,
  SUMX.orders_fact,
  SUMX.net_revenue_fact,
  V.orders_view,
  V.net_revenue_view,
  (SUMX.orders_fact - V.orders_view) AS diff_orders,
  ROUND(SUMX.net_revenue_fact - V.net_revenue_view, 2) AS diff_net_revenue
FROM (
  SELECT store_key, COUNT(*) AS orders_fact, SUM(net_revenue) AS net_revenue_fact
  FROM fact_orders
  GROUP BY store_key
) SUMX
JOIN dim_store s ON s.store_key = SUMX.store_key
JOIN (
  SELECT store_code, orders AS orders_view, net_revenue AS net_revenue_view
  FROM vw_kpi_store_summary
) V ON V.store_code = s.store_code
ORDER BY s.store_code;
