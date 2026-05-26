
SELECT
   *
FROM {{ ref('stg_fact_inventory') }}
