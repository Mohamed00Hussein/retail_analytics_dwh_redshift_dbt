WITH top_products_per_cat AS (
   SELECT
       p.product_id,
        p.category,
       sum(quantity_sold) total_quantity_sold,
       sum(total_amount) total_amount
   FROM  {{ ref('stg_retail__dim_products') }} as p
   inner join {{ ref('stg_retail__fact_sales') }} s
        on
    p.product_id = s.product_id
   GROUP BY p.product_id,p.category
)


SELECT
   product_id,
   category,
   total_quantity_sold,
   total_amount,
   row_number() over(partition by category order by total_quantity_sold desc) product_rank
FROM top_products_per_cat
ORDER BY category asc , total_quantity_sold desc