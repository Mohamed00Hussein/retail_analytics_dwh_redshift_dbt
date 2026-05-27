{% snapshot dim_customer_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',

        strategy='check',
        check_cols=['customer_name', 'email', 'region']
    )
}}

select * from {{ ref('dim_customers') }}

{% endsnapshot %}