select
    order_id,
    total_order_amount
from {{ ref('fact_sales') }}
where total_order_amount<0