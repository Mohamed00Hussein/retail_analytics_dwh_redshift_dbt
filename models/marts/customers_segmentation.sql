WITH customer_sales AS (
   SELECT
       s.customer_id,
       count(distinct s.order_id) AS total_orders,
       SUM(s.total_order_amount) AS total_spend,
       max(s.order_date)::date AS last_order_date
   FROM {{ ref('stg_fact_sales') }} s
   GROUP BY s.customer_id
)


SELECT
   cs.customer_id,
   cs.total_orders,
   cs.total_spend,
   cs.last_order_date,
    {{ dbt.datediff("cs.last_order_date", "current_date", "day") }}  as days_since_last_order,
   CASE
       WHEN cs.total_spend >= 10000  THEN 'High-Value'
       WHEN cs.total_spend BETWEEN 2500 AND 9999 THEN 'Medium-Value'
       WHEN cs.total_spend < 2500  THEN 'Low-Value'
       ELSE 'Unknown'
   END AS customer_segment
FROM customer_sales cs