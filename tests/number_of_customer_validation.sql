-- Fails (returns a row) if the distinct counts differ.
with dim_count as (
    select count(distinct customer_id) as customer_count
    from {{ ref('dim_customers') }}
),

raw_count as (
    select count(distinct customer_id) as customer_count
    from {{ source('raw_data', 'customers_raw') }}
)

select
    dim_count.customer_count as dim_count,
    raw_count.customer_count as raw_count
from dim_count
 join raw_count on 1=1
where dim_count.customer_count <> raw_count.customer_count