with source as (

    SELECT
        CURRENT_DATE - INTERVAL '1 day' * (ROW_NUMBER() OVER() - 1) AS date_id
    FROM STV_BLOCKLIST
    LIMIT 5000

),

stg_dim_time as (

    select
        date_id,
        EXTRACT(YEAR FROM date_id) AS year,
        EXTRACT(QUARTER FROM date_id) AS quarter,
        EXTRACT(MONTH FROM date_id) AS month,
        EXTRACT(DAY FROM date_id) AS day,
        TRIM(TO_CHAR(date_id, 'Day')) AS day_of_week

    from source

)

select *
from stg_dim_time