# 🛍️ Retail Analytics Data Warehouse — Redshift × dbt

> An end-to-end analytics engineering project that turns raw retail transactions into a governed, dimensional data warehouse on **Amazon Redshift**, powered by **dbt**. From eight raw source tables to decision-ready marts for **customer segmentation, RFM scoring, and inventory health** — all version-controlled, modular, and reproducible.

<p align="left">
  <img src="https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white" alt="dbt"/>
  <img src="https://img.shields.io/badge/Amazon%20Redshift-8C4FFF?style=for-the-badge&logo=amazonredshift&logoColor=white" alt="Redshift"/>
  <img src="https://img.shields.io/badge/SQL-336791?style=for-the-badge&logo=postgresql&logoColor=white" alt="SQL"/>
  <img src="https://img.shields.io/badge/Jinja-B41717?style=for-the-badge&logo=jinja&logoColor=white" alt="Jinja"/>
</p>

---

## 📌 Why this project exists

Retail businesses sit on transactional data that's useless until it's modeled. This warehouse answers the questions that actually drive revenue and margin:

- **Who are my best customers, and who's about to churn?** → RFM scoring + value segmentation
- **Which products are bleeding cash on the shelf vs. about to stock out?** → Inventory health classification
- **What's selling, where, and when?** → Monthly sales trends + top products per category

The project is built the way a real analytics team ships data: a layered architecture, reusable macros, environment-aware schema routing, and a clean separation between raw, staged, and presentation-ready data.

---

## 🏗️ Architecture & Data Lineage

The warehouse follows a classic **staging → dimensional → marts** flow. Raw data lands in Redshift, gets cleaned in **views**, then is materialized as **tables** in the dimensional and analytics layers.

```
┌─────────────────┐     ┌──────────────────┐     ┌────────────────────────┐
│   RAW LAYER     │     │  STAGING LAYER   │     │      MARTS LAYER       │
│  (Redshift)     │ ──▶ │   (views)        │ ──▶ │      (tables)          │
│  schema:raw_data│     │  schema: staging │     │     schema: dwh        │
└─────────────────┘     └──────────────────┘     └────────────────────────┘
```

**Source → Staging → Dimensional → Analytics** in one diagram:

```
orders_raw ───────────▶ stg_fact_sales ──────────┬─▶ fact_sales
order_items_raw ──────▶ stg_dim_order_items ─────┼─▶ dim_order_items
products_raw ─────────▶ stg_dim_products ────────┼─▶ dim_products
customers_raw ────────▶ stg_dim_customers ───────┼─▶ dim_customers
stores_raw ───────────▶ stg_dim_stores ──────────┼─▶ dim_stores
employees_raw ────────▶ stg_dim_employees ───────┼─▶ dim_employees
inventory_raw ────────▶ stg_fact_inventory ──────┼─▶ fact_inventory
dim_time ─────────────▶ stg_dim_time ────────────┴─▶ dim_time
                                                  │
                                                  ▼
                          ┌───────────────────────────────────────────┐
                          │            ANALYTICS MARTS                 │
                          │                                            │
   stg_fact_sales ───────▶  customers_segmentation ──▶ customers_rfm   │
   stg_fact_sales ───────▶  monthly_sales                              │
   stg_dim_products ─────┐                                             │
   stg_dim_order_items ──┴▶ top_products_per_cat                       │
   fact_inventory ───────┐                                             │
   fact_sales ───────────┼▶ inventory_health                          │
   dim_order_items ──────┤                                             │
   dim_products ─────────┘                                             │
                          └───────────────────────────────────────────┘
```

Materialization strategy is enforced in `dbt_project.yml`:

| Layer    | Materialization | Target schema | Rationale |
|----------|-----------------|---------------|-----------|
| Staging  | `view`          | `staging`     | Lightweight, always-fresh cleaning layer — no storage cost |
| Marts    | `table`         | `dwh`         | Fast reads for BI tools and heavy analytical queries |

---

## ⭐ The Star Schema

The dimensional layer is a conformed star schema — two fact tables surrounded by shared dimensions, so every metric can be sliced by the same customer, product, store, and time attributes.

```
                       dim_time
                          │
       dim_customers ─────┼───── dim_employees
              \           │           /
               \          │          /
                ▶  ┌──────────────┐  ◀
   dim_stores ───▶ │  fact_sales  │ ◀─── dim_products
                   └──────────────┘
                          │
                   ┌──────────────┐
   dim_products ─▶ │fact_inventory│ ◀─ dim_stores
                   └──────────────┘
```

---

## 🧠 Featured Analytics Marts

### 1️⃣ Customer RFM Scoring (`customers_rfm`)

RFM (**R**ecency, **F**requency, **M**onetary) is the workhorse of retail customer analytics. This mart scores every customer on all three axes and rolls them into a single RFM score — the higher the score, the more valuable and engaged the customer.

The scoring is powered by a **custom, reusable Jinja macro** (`macros/rfm.sql`) built on `NTILE`, so the logic lives in exactly one place:

```sql
-- One macro, called once per dimension
{{ rfm_score("days_since_last_order", order="asc")  }} as recency_score    -- fewer days  → higher score
{{ rfm_score("total_orders",          order="desc") }} as frequency_score  -- more orders → higher score
{{ rfm_score("total_spend",           order="desc") }} as monetary_score   -- more spend  → higher score
```

**How it works:** the macro divides customers into 5 equal quantiles (`NTILE(5)`) per metric. The top 20% on a metric earn a **5**; the bottom 20% earn a **1**. The `order` argument flips the ranking direction so recency (where *fewer* days is better) and frequency/monetary (where *more* is better) all score in the same intuitive direction.

```
days_since_last_order ─┐
total_orders ──────────┼─▶ rfm_score() ─▶ recency / frequency / monetary (1–5)
total_spend ───────────┘                            │
                                                     ▼
                                  rfm = (R + F + M) / 3
```

Lineage:

```
stg_fact_sales ─▶ customers_segmentation ─▶ customers_rfm
                       (R/F/M raw inputs)      (scored + averaged)
```

---

### 2️⃣ Customer Value Segmentation (`customers_segmentation`)

Aggregates each customer's lifetime behavior — total orders, total spend, last order date, and days since last order — then buckets them into actionable value tiers:

| Segment        | Rule                          |
|----------------|-------------------------------|
| **High-Value** | total spend ≥ $10,000         |
| **Medium-Value** | $2,500 – $9,999             |
| **Low-Value**  | < $2,500                      |

This mart doubles as the feature table that feeds the RFM model above.

```
stg_fact_sales ─▶ [ aggregate per customer ] ─▶ customers_segmentation ─▶ customers_rfm
```

---

### 3️⃣ Inventory Health (`inventory_health`)

The most logic-rich mart in the project. It answers a deceptively hard question: **"For every product in every store, is the stock level healthy?"** It does this by joining the *latest* stock reading against *recent* sales velocity to compute **days of supply**, then classifies each SKU.

The pipeline runs in four CTEs:

```
fact_inventory ─▶ latest_stock        (most recent stock reading per product × store, via ROW_NUMBER)
                       │
dim_order_items ─┐     │
fact_sales ──────┴─▶ sales_velocity   (trailing-90-day units sold → avg daily units)
                       │
                       ▼
                  stock_and_sales      (current_stock ÷ avg_daily_units → days_of_supply)
                       │
                       ▼
                inventory_health        (classify into stock_status)
```

**Days of supply** = `current_stock / avg_daily_units` → roughly *"how many days until we run out at the current sales pace."* That single number drives the classification:

| `stock_status`     | Condition                        | Business meaning |
|--------------------|----------------------------------|------------------|
| **Dead Stock**     | 0 units sold in 90 days          | Capital frozen on the shelf — candidate for clearance |
| **No Recent Sales**| no velocity to compute supply    | Can't forecast — needs review |
| **Stockout Risk**  | days of supply < 7               | 🚨 Reorder now |
| **Healthy**        | 7 ≤ days of supply < 30          | ✅ Sweet spot |
| **Overstocked**    | days of supply ≥ 30              | Too much capital tied up |

Notable engineering details: it uses `ROW_NUMBER()` to grab only the latest stock snapshot per product/store, `COALESCE` to safely handle products with zero sales, and guards against division-by-zero before computing days of supply.

---

### 4️⃣ Monthly Sales (`monthly_sales`)

Time-series revenue mart aggregating total sales, transaction counts, and average basket size (`total_sales / total_transactions`) by year and month — the backbone of any sales trend dashboard.

### 5️⃣ Top Products per Category (`top_products_per_cat`)

Ranks products *within* each category by units sold using a windowed `ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_quantity_sold DESC)` — instantly surfaces category bestsellers.

---

## 🗂️ Project Structure

```
retail_analytics_dwh_redshift_dbt/
├── dbt_project.yml              # Project config + layer-level materialization rules
├── models/
│   ├── schema.yml               # Source definitions (8 raw Redshift tables)
│   ├── staging/raw_data/        # 7 stg_* cleaning views
│   │   ├── stg_fact_sales.sql
│   │   ├── stg_fact_inventory.sql
│   │   └── stg_dim_*.sql
│   └── marts/                   # Dimensional + analytics layer (tables)
│       ├── dim_*.sql            # Conformed dimensions
│       ├── fact_sales.sql
│       ├── fact_inventory.sql
│       ├── customers_segmentation.sql
│       ├── customers_rfm.sql
│       ├── inventory_health.sql
│       ├── monthly_sales.sql
│       └── top_products_per_cat.sql
├── macros/
│   ├── rfm.sql                  # ⭐ Custom reusable NTILE-based RFM scoring macro
│   └── generate_schema_name.sql # Environment-aware schema routing
├── tests/
│   ├── negative_orders.sql           # Flags any negative order amount
│   ├── total_order_amount_validation.sql     # Revenue parity: fact_sales vs orders_raw
│   └── number_of_customer_validation.sql  # Row parity: dim_customers vs customers_raw
├── snapshots/
│   └── customers_snapshot.sql        # SCD Type 2 history on the customers dimension
├── seeds/
└── analyses/
```

---

## ⚙️ Engineering Highlights

- **Reusable macro design** — RFM logic is abstracted into a single parameterized macro (`order`, `buckets`) instead of being copy-pasted three times. Change the bucket count once, and recency/frequency/monetary all update together.
- **Custom schema routing** — an overridden `generate_schema_name` macro controls exactly which Redshift schema each layer lands in (`staging` vs `dwh`).
- **Cross-database-safe SQL** — uses dbt's built-in `dbt.datediff` and `dbt.dateadd` cross-db macros rather than hard-coded Redshift syntax, keeping models portable.
- **Layered materialization** — staging as throwaway views, marts as persisted tables, configured declaratively at the project level.
- **DRY dimensional layer** — staging holds the cleaning logic; dimensions stay thin, so transformations have a single source of truth.

---

## ✅ Data Quality

Models are guarded by **custom singular data tests** that enforce business rules the warehouse should never violate. Each follows dbt's "return the failing rows" pattern — the query selects offending records, and the test passes only when **zero rows** come back.

| Test | Target | Asserts |
|------|--------|---------|
| `negative_orders` | `fact_sales` | No order has a negative `total_order_amount` |
| `reconcile_sales_total` | `fact_sales` ↔ `orders_raw` | Total revenue in the fact table matches the raw source — no rows dropped or double-counted |
| `reconcile_customer_count` | `dim_customers` ↔ `customers_raw` | Every distinct customer survives the journey from raw into the dimension |

The two **reconciliation tests** are the backbone of pipeline trust: `reconcile_sales_total` sums `total_order_amount` on both sides and fails if a single cent drifts, while `reconcile_customer_count` compares distinct `customer_id` counts so neither silent row loss nor accidental fan-out can slip through. Catching these at build time stops bad data from flowing into the revenue, segmentation, and RFM marts downstream.

```bash
dbt test                                # run every test
dbt test --select negative_orders       # run just one
```

---

## 📸 Snapshots — Slowly Changing Dimensions

Customers aren't static — they move regions, change emails, update names. The `customers_snapshot` captures that history as a **Type 2 slowly changing dimension (SCD2)**, so the warehouse can answer *"what did this customer look like at the time of their order?"* rather than only showing the latest state.

It uses dbt's `check` strategy on the attributes most likely to drift (`customer_name`, `email`, `region`), versioning a new row each time one changes:

```
stg_dim_customers ─▶ customers_snapshot ─▶ versioned history
                       (check strategy)      (valid_from / valid_to per change)
```

```bash
dbt snapshot   # capture the current state and version any changes
```

---

## 🚀 Getting Started

**Prerequisites:** Python 3.8+, a Redshift cluster, and a dbt profile named `default` pointing at it.you will find the source layer (raw_data) sql script in the files, run it on the redshift editor first.

```bash
# 1. Install dbt with the Redshift adapter
pip install dbt-redshift

# 2. Confirm your connection
dbt debug

# 3. Load any seed data (if used)
dbt seed

# 4. Build the entire warehouse (staging → marts)
dbt run

# 5. Run data quality tests
dbt test

# 6. Capture dimension history (SCD2)
dbt snapshot

# 7. Generate & serve the documentation site + lineage graph
dbt docs generate && dbt docs serve
```

> The raw layer is expected to already exist in Redshift under the `raw_data` schema (see `models/schema.yml` for the eight source tables).

---

## 🧰 Tech Stack

| Tool | Role |
|------|------|
| **Amazon Redshift** | Cloud data warehouse / compute engine |
| **dbt cloud(Data Build Tool)** | Transformation, testing, docs, lineage |
| **SQL + Jinja** | Modeling language and templating for reusable macros |

---

## 📈 What this demonstrates

This project is a compact but complete demonstration of **analytics engineering** fundamentals: dimensional modeling (star schema), the staging/marts pattern, reusable macro development, data quality testing with source reconciliation, slowly changing dimensions (SCD2 snapshots), environment-aware deployment, and translating business questions (churn risk, dead stock, customer value) directly into maintainable SQL models.
