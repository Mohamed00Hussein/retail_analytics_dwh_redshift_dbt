with 

source as (

    select * from {{ source('raw_data', 'stores_raw') }}

),

stg_dim_stores as (

    select
        store_id,
    store_name,
    city,
    country,
    manager_name,
    opening_date,
    source_system

    from source

)

select * from stg_dim_stores