with 

source as (

    select * from {{ source('raw_data', 'products_raw') }}

),

stg_dim_products as (

    select
        product_id,
    product_name,
    category,
    brand,
    price,
    cost,
    is_active,
    source_system

    from source

)

select * from stg_dim_products