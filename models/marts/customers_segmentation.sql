WITH customer_sales AS (
   SELECT
       s.customer_id,
       --sum(s.quantity_sold) AS total_purchases,
       SUM(s.total_order_amount) AS total_spend
   FROM {{ ref('stg_fact_sales') }} s
   GROUP BY s.customer_id
)


SELECT
   cs.customer_id,
   --cs.total_purchases,
   cs.total_spend,
   CASE
       WHEN cs.total_spend >= 10000  THEN 'High-Value'
       WHEN cs.total_spend BETWEEN 2500 AND 9999 THEN 'Medium-Value'
       WHEN cs.total_spend < 2500  THEN 'Low-Value'
       ELSE 'Unknown'
   END AS customer_segment
FROM customer_sales cs