-- Fails (returns a row) if the two sums differ.
with fact_total as (
    select sum(total_order_amount) as total_amount
    from {{ ref('fact_sales') }}
),

raw_total as (
    select sum(total_order_amount) as total_amount
    from {{ source('raw_data', 'orders_raw') }}
)

select
    fact_total.total_amount as fact_amount,
    raw_total.total_amount  as raw_amount
from fact_total
 join raw_total on 1=1
where fact_total.total_amount <> raw_total.total_amount