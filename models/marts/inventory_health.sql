with latest_stock as (

    -- most recent stock reading per product/store
    select
        product_id,
        store_id,
        current_stock
    from (
        select
            product_id,
            store_id,
            stock_level as current_stock,
            row_number() over (
                partition by product_id, store_id
                order by inventory_date desc
            ) as rn
        from {{ ref('fact_inventory') }}
    )
    where rn = 1

),

sales_velocity as (

    -- units sold per product/store over the trailing 90 days
    select
        oi.product_id,
        s.store_id,
        sum(oi.quantity)        as units_sold_90d,
        sum(oi.quantity) / 90.0 as avg_daily_units
        from {{ ref('dim_order_items') }} as oi
        left join {{ ref('fact_sales') }} as s on s.order_id = oi.order_id
    where order_date >= {{ dbt.dateadd('day', -90, 'current_date') }}
    group by oi.product_id, s.store_id

),

stock_and_sales as (

    select
        latest_stock.product_id,
        latest_stock.store_id,
        products.product_name,
        products.category,
        latest_stock.current_stock,
        coalesce(sales_velocity.units_sold_90d, 0)  as units_sold_90d,
        coalesce(sales_velocity.avg_daily_units, 0) as avg_daily_units,
        case
            when coalesce(sales_velocity.avg_daily_units, 0) = 0 then null
            else round(latest_stock.current_stock / sales_velocity.avg_daily_units, 1)
        end as days_of_supply
    from latest_stock
    left join sales_velocity
        on  latest_stock.product_id = sales_velocity.product_id
        and latest_stock.store_id   = sales_velocity.store_id
    left join {{ ref('dim_products') }} products
        on latest_stock.product_id = products.product_id

),

inventory_health as (

    select
        stock_and_sales.*,
        case
            when units_sold_90d = 0     then 'Dead Stock'
            when days_of_supply is null then 'No Recent Sales'
            when days_of_supply < 7     then 'Stockout Risk'
            when days_of_supply < 30    then 'Healthy'
            else 'Overstocked'
        end as stock_status
    from stock_and_sales

)

select * from inventory_health