CREATE SCHEMA raw_data;
CREATE SCHEMA staging;
CREATE SCHEMA dwh;
--drop SCHEMA IF EXISTS raw_data CASCADE;

--------------




-- =====================================================================
-- Reusable numbers temp table for data generating
-- =====================================================================
CREATE TEMP TABLE numbers AS
--select  generate_series(1, 1000000,1);
WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1
    FROM seq
    WHERE n < 1000000
)
SELECT n
FROM seq;

-- =====================================================================
-- RAW CUSTOMERS
-- =====================================================================

CREATE TABLE raw_data.customers_raw (
    customer_id        BIGINT,
    customer_name      VARCHAR(100),
    email              VARCHAR(150),
    region             VARCHAR(50),
    signup_date        TIMESTAMP,
    source_system      VARCHAR(50),
    ingestion_date     TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE AUTO
SORTKEY AUTO;


INSERT INTO raw_data.customers_raw (
    customer_id,
    customer_name,
    email,
    region,
    signup_date,
    source_system
)
SELECT
    n,
    'Customer_' || n,
    'customer_' || n || '@example.com',

    CASE n % 4
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        ELSE 'West'
    END,

    DATEADD(day,
        -CAST(FLOOR(RANDOM() * 3650) AS INT),
        GETDATE()
    ),

    'CRM_SYSTEM'

FROM numbers
WHERE n <= 100000;


-- =====================================================================
-- RAW PRODUCTS
-- =====================================================================

CREATE TABLE raw_data.products_raw (
    product_id         BIGINT,
    product_name       VARCHAR(200),
    category           VARCHAR(100),
    brand              VARCHAR(100),
    price              DECIMAL(10,2),
    cost               DECIMAL(10,2),
    is_active          BOOLEAN,
    source_system      VARCHAR(50),
    ingestion_date     TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE AUTO
SORTKEY AUTO;


INSERT INTO raw_data.products_raw (
    product_id,
    product_name,
    category,
    brand,
    price,
    cost,
    is_active,
    source_system
)
SELECT
    n,

    'Product_' || n,

    CASE n % 4
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Home & Kitchen'
        ELSE 'Sports'
    END,

    CASE n % 5
        WHEN 0 THEN 'Nike'
        WHEN 1 THEN 'Apple'
        WHEN 2 THEN 'Samsung'
        WHEN 3 THEN 'Adidas'
        ELSE 'Generic'
    END,

    price,

    ROUND(price * (0.45 + RANDOM() * 0.25), 2),

    TRUE,

    'ERP_SYSTEM'

FROM (
    SELECT
        n,
        ROUND(RANDOM() * 500 + 5, 2) AS price
    FROM numbers
    WHERE n <= 500
);


-- =====================================================================
-- RAW STORES
-- =====================================================================

CREATE TABLE raw_data.stores_raw (
    store_id           BIGINT,
    store_name         VARCHAR(150),
    city               VARCHAR(100),
    country            VARCHAR(100),
    manager_name       VARCHAR(100),
    opening_date       DATE,
    source_system      VARCHAR(50),
    ingestion_date     TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE AUTO
SORTKEY AUTO;


INSERT INTO raw_data.stores_raw (
    store_id,
    store_name,
    city,
    country,
    manager_name,
    opening_date,
    source_system
)
SELECT
    n,

    'Store_' || n,

    CASE n % 4
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Los Angeles'
        WHEN 2 THEN 'Chicago'
        ELSE 'Houston'
    END,

    'USA',

    'Manager_' || n,

    DATEADD(day,
        -CAST(FLOOR(RANDOM() * 5000) AS INT),
        CURRENT_DATE
    ),

    'STORE_SYSTEM'

FROM numbers
WHERE n <= 100;


-- =====================================================================
-- RAW EMPLOYEES
-- =====================================================================

CREATE TABLE raw_data.employees_raw (
    employee_id        BIGINT,
    employee_name      VARCHAR(150),
    department         VARCHAR(100),
    employment_type    VARCHAR(50),
    hire_date          DATE,
    salary             DECIMAL(12,2),
    store_id           BIGINT,
    source_system      VARCHAR(50),
    ingestion_date     TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE AUTO
SORTKEY AUTO;


INSERT INTO raw_data.employees_raw (
    employee_id,
    employee_name,
    department,
    employment_type,
    hire_date,
    salary,
    store_id,
    source_system
)
SELECT
    n,

    'Employee_' || n,

    CASE n % 4
        WHEN 0 THEN 'HR'
        WHEN 1 THEN 'Sales'
        WHEN 2 THEN 'Operations'
        ELSE 'Finance'
    END,

    CASE n % 2
        WHEN 0 THEN 'Full-time'
        ELSE 'Part-time'
    END,

    DATEADD(day,
        -CAST(FLOOR(RANDOM() * 3650) AS INT),
        CURRENT_DATE
    ),

    ROUND(RANDOM() * 7000 + 3000, 2),

    CAST(FLOOR(RANDOM() * 100) + 1 AS BIGINT),

    'HR_SYSTEM'

FROM numbers
WHERE n <= 10000;



-- =====================================================================
-- RAW ORDER ITEMS
-- =====================================================================

CREATE TABLE raw_data.order_items_raw (
    order_item_id          BIGINT,
    order_id               BIGINT,
    product_id             BIGINT,
    quantity               INT,
    unit_price             DECIMAL(10,2),
    discount_amount        DECIMAL(10,2),
    source_system          VARCHAR(50),
    ingestion_date         TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE AUTO
SORTKEY AUTO;

INSERT INTO raw_data.order_items_raw (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_amount,
    source_system
)
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    -- discount is a real % (0–30%) of THIS row's gross, so net is always >= 0
    ROUND(CAST(quantity * unit_price * (RANDOM() * 0.30) AS NUMERIC), 2) AS discount_amount,
    source_system
FROM (
    SELECT
        n AS order_item_id,
        CASE
            WHEN n <= 1000000 THEN n
            ELSE CAST(FLOOR(RANDOM() * 1000000) + 1 AS BIGINT)
        END AS order_id,
        CAST(FLOOR(RANDOM() * 500) + 1 AS BIGINT) AS product_id,
        CAST(FLOOR(RANDOM() * 10) + 1 AS INT)     AS quantity,
        ROUND(CAST(RANDOM() * 500 + 5 AS NUMERIC), 2) AS unit_price,
        'ECOMMERCE_PLATFORM' AS source_system
    FROM numbers
    WHERE n <= 1000000
) AS base;


-- =====================================================================
-- RAW ORDERS
-- =====================================================================



CREATE TABLE raw_data.orders_raw (
    order_id               BIGINT,
    customer_id            BIGINT,
    store_id               BIGINT,
    order_timestamp        TIMESTAMP,
    order_status           VARCHAR(50),
    payment_method         VARCHAR(50),
    shipping_city          VARCHAR(100),
    shipping_country       VARCHAR(100),
    total_order_amount     DECIMAL(12,2),
    source_system          VARCHAR(50),
    ingestion_date         TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE AUTO
SORTKEY AUTO;

INSERT INTO raw_data.orders_raw (
    order_id,
    customer_id,
    store_id,
    order_timestamp,
    order_status,
    payment_method,
    shipping_city,
    shipping_country,
    total_order_amount,
    source_system
)
WITH order_totals AS (
    -- Roll the line items up to one total per order.
    -- net line = quantity * unit_price - discount_amount
    SELECT
        order_id,
        SUM(quantity * unit_price - discount_amount) AS order_total
    FROM raw_data.order_items_raw
    GROUP BY order_id
)
SELECT
    o.n AS order_id,
    CAST(FLOOR(RANDOM() * 100000) + 1 AS BIGINT) AS customer_id,
    CAST(FLOOR(RANDOM() * 100) + 1 AS BIGINT)    AS store_id,
    DATEADD(
        day,
        -CAST(FLOOR(RANDOM() * 1825) AS INT),
        GETDATE()
    ) AS order_timestamp,
    CASE o.n % 5
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Cancelled'
        WHEN 3 THEN 'Shipped'
        ELSE 'Delivered'
    END AS order_status,
    CASE o.n % 4
        WHEN 0 THEN 'Credit Card'
        WHEN 1 THEN 'Cash'
        WHEN 2 THEN 'Apple Pay'
        ELSE 'PayPal'
    END AS payment_method,
    CASE o.n % 4
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Chicago'
        WHEN 2 THEN 'Houston'
        ELSE 'Los Angeles'
    END AS shipping_city,
    'USA' AS shipping_country,
    CAST(ROUND(t.order_total, 2) AS DECIMAL(12,2)) AS total_order_amount,
    'ECOMMERCE_PLATFORM' AS source_system
FROM numbers o
JOIN order_totals t
    ON t.order_id = o.n
WHERE o.n <= 300000;


-- =====================================================================
-- RAW INVENTORY EVENTS
-- =====================================================================

CREATE TABLE raw_data.inventory_raw (
    inventory_event_id     BIGINT,
    product_id             BIGINT,
    store_id               BIGINT,
    inventory_date         TIMESTAMP,
    stock_level            INT,
    inventory_movement     VARCHAR(50),
    source_system          VARCHAR(50),
    ingestion_date         TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE AUTO
SORTKEY AUTO;


INSERT INTO raw_data.inventory_raw (
    inventory_event_id,
    product_id,
    store_id,
    inventory_date,
    stock_level,
    inventory_movement,
    source_system
)
SELECT
    n,

    CAST(FLOOR(RANDOM() * 500) + 1 AS BIGINT),

    CAST(FLOOR(RANDOM() * 100) + 1 AS BIGINT),

    DATEADD(day,
        -CAST(FLOOR(RANDOM() * 1825) AS INT),
        GETDATE()
    ),

    CAST(FLOOR(RANDOM() * 1000) AS INT),

    CASE n % 3
        WHEN 0 THEN 'IN'
        WHEN 1 THEN 'OUT'
        ELSE 'ADJUSTMENT'
    END,

    'WAREHOUSE_SYSTEM'

FROM numbers
WHERE n <= 500000;


-- =====================================================================
-- OPTIONAL CLEANUP
-- =====================================================================

DROP TABLE numbers;


-- =====================================================================
-- VALIDATION
-- =====================================================================

SELECT 'customers_raw'   AS table_name, COUNT(*) FROM raw_data.customers_raw
UNION ALL
SELECT 'products_raw', COUNT(*) FROM raw_data.products_raw
UNION ALL
SELECT 'stores_raw', COUNT(*) FROM raw_data.stores_raw
UNION ALL
SELECT 'employees_raw', COUNT(*) FROM raw_data.employees_raw
UNION ALL
SELECT 'orders_raw', COUNT(*) FROM raw_data.orders_raw
UNION ALL
SELECT 'order_items_raw', COUNT(*) FROM raw_data.order_items_raw
UNION ALL
SELECT 'inventory_raw', COUNT(*) FROM raw_data.inventory_raw;



---this is just to test the snapshot so only try it after you create the snapshot amigo
update dwh.dim_customers set customer_name='Mohamed Hussein' where customer_id=1 


--look at the snapshot table
select * from snapshots.dim_customer_snapshot where customer_id=1 


-- you can go crazy and add a negative value to the fact sales table and then run the dbt to check the test 
--only if you want to test the test and see a nice error
--update dwh.fact_sales set total_order_amount =-50 where order_id=1;
--go and test