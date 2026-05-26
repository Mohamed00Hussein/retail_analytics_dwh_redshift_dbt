with 

source as (

    select * from {{ source('raw_data', 'order_items_raw') }}

),

stg_dim_order_items as (

    select
       order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_amount,
    source_system
    from source

)

select * from stg_dim_order_items