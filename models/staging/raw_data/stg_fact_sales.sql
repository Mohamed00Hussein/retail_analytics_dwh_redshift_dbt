with 

source as (

    select * from {{ source('raw_data', 'orders_raw') }}

),

stg_fact_sales as (

    select
        order_id,
        customer_id,
        cast(order_timestamp as date) as order_date,
        order_timestamp,
        order_status,
        payment_method,
        shipping_city,
        store_id,
        shipping_country,
        total_order_amount,
        source_system

    from source

)

select * from stg_fact_sales