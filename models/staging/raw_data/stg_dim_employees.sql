with

    source as (select * from {{ source("raw_data", "employees_raw") }}),

    stg_dim_employees as (

        select
            employee_id,
            employee_name,
            department,
            employment_type,
            hire_date,
            salary,
            store_id,
            source_system

        from source

    )

select *
from stg_dim_employees
