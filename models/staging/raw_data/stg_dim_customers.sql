with 

source as (

    select * from {{ source('raw_data', 'customers_raw') }}

),

stg_dim_customers as (

    select
        customer_id,
        customer_name,
        email,
        region,
        signup_date,
        source_system,
        ingestion_date

    from source

)

select * from stg_dim_customers