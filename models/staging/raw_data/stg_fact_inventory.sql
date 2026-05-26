with 

source as (

    select * from {{ source('raw_data', 'inventory_raw') }}

),

stg_fact_inventory as (

    select
        inventory_event_id,
        product_id,
        store_id,
        cast(inventory_date as date) as inventory_date,
        inventory_date as inventory_timestamp,
        stock_level,
        inventory_movement,
        source_system
    from source

)

select * from stg_fact_inventory