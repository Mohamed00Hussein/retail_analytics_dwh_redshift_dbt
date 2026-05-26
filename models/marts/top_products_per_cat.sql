with
    top_products_per_cat as (
        select
            p.product_id,
            p.category,
            sum(quantity) total_quantity_sold,
            sum(unit_price) total_amount
        from {{ ref("stg_dim_products") }} as p
        inner join {{ ref("stg_dim_order_items") }} s on p.product_id = s.product_id
        group by p.product_id, p.category
    )

select
    product_id,
    category,
    total_quantity_sold,
    total_amount,
    row_number() over (
        partition by category order by total_quantity_sold desc
    ) product_rank
from top_products_per_cat
order by category asc, total_quantity_sold desc
