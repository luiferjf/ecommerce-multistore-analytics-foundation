-- Views

CREATE OR REPLACE VIEW vw_kpi_store_summary AS
WITH
o AS (
  SELECT store_key, COUNT(*) AS orders, SUM(net_revenue) AS net_revenue
  FROM fact_orders
  GROUP BY store_key
),
i AS (
  SELECT store_key, SUM(quantity) AS units
  FROM fact_order_items
  GROUP BY store_key
)
SELECT
  s.store_code,
  s.store_name,
  o.orders,
  o.net_revenue,
  ROUND(o.net_revenue / NULLIF(o.orders, 0), 2) AS aov,
  i.units,
  ROUND(o.net_revenue / NULLIF(i.units, 0), 2) AS asp,
  ROUND(i.units / NULLIF(o.orders, 0), 2) AS units_per_order,
  NOW() AS refreshed_at
FROM dim_store s
LEFT JOIN o ON o.store_key = s.store_key
LEFT JOIN i ON i.store_key = s.store_key
ORDER BY s.store_code;

CREATE OR REPLACE VIEW vw_kpi_daily_store AS
WITH
o AS (
  SELECT store_key, date_key, COUNT(*) AS orders, SUM(net_revenue) AS net_revenue
  FROM fact_orders
  GROUP BY store_key, date_key
),
i AS (
  SELECT store_key, date_key, SUM(quantity) AS units
  FROM fact_order_items
  GROUP BY store_key, date_key
)
SELECT
  s.store_code,
  s.store_name,
  d.date_key,
  d.date,
  d.year,
  d.month,
  d.month_name,
  d.iso_year,
  d.iso_week,
  d.iso_yearweek,
  d.week_start_date,
  COALESCE(o.orders, 0) AS orders,
  COALESCE(o.net_revenue, 0) AS net_revenue,
  ROUND(COALESCE(o.net_revenue, 0) / NULLIF(o.orders, 0), 2) AS aov,
  COALESCE(i.units, 0) AS units,
  ROUND(COALESCE(o.net_revenue, 0) / NULLIF(i.units, 0), 2) AS asp,
  ROUND(COALESCE(i.units, 0) / NULLIF(o.orders, 0), 2) AS units_per_order
FROM dim_store s
JOIN dim_date d
LEFT JOIN o ON o.store_key = s.store_key AND o.date_key = d.date_key
LEFT JOIN i ON i.store_key = s.store_key AND i.date_key = d.date_key;

CREATE OR REPLACE VIEW vw_revenue_mix_store AS
SELECT
  s.store_code,
  s.store_name,
  dp.product_id,
  dp.variation_id,
  dp.sku,
  SUM(foi.quantity) AS units,
  SUM(foi.line_total) AS item_revenue,
  ROUND(SUM(foi.line_total) / NULLIF(t.total_item_revenue, 0), 4) AS pct_store_item_revenue,
  ROUND(SUM(foi.quantity) / NULLIF(t.total_units, 0), 4) AS pct_store_units
FROM fact_order_items foi
JOIN dim_store s ON s.store_key = foi.store_key
JOIN dim_product dp ON dp.product_key = foi.product_key
JOIN (
  SELECT store_key, SUM(line_total) AS total_item_revenue, SUM(quantity) AS total_units
  FROM fact_order_items
  GROUP BY store_key
) t ON t.store_key = foi.store_key
GROUP BY
  s.store_code, s.store_name,
  dp.product_id, dp.variation_id, dp.sku;
