with 

source as (

    select * from {{ source('retail', 'dim_stores') }}

),

stg_dim_stores as (

    select
        store_id,
        store_name,
        location,
        manager_name

    from source

)

select * from stg_dim_stores