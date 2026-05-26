with scores as (

    select
        *,
        {{ rfm_score('days_since_last_order', order='asc') }}  as recency_score,
        {{ rfm_score('total_orders',           order='desc') }} as frequency_score,
        {{ rfm_score('total_spend',           order='desc') }} as monetary_score    
    from {{ ref('customers_segmentation') }} )

    select * 
    ,recency_score*frequency_score*monetary_score as rfm
    from scores