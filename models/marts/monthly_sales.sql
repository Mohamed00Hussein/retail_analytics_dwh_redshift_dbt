WITH sales_by_month AS (
   SELECT
       EXTRACT(YEAR FROM order_date) AS year,
       EXTRACT(MONTH FROM order_date) AS month,
       SUM(total_order_amount) AS total_sales,
       COUNT(DISTINCT order_id) AS total_transactions
   FROM {{ ref('stg_fact_sales') }}
   GROUP BY year,month
)


SELECT
   year,
   month,
   total_sales,
   total_transactions,
   total_sales / total_transactions AS avg_sales_per_transaction
FROM sales_by_month
ORDER BY month