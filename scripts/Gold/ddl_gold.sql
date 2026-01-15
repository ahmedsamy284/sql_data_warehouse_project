/*
================================================================================
DDL Script Purpose: Create Gold Views (Star Schema)
================================================================================
Description: 
    This script creates the final Reporting Views (Gold Layer).
    It transforms the normalized Silver data into a Star Schema consisting of:
    1. Dimensions (dim_customers, dim_products): Descriptive data.
   2. Fact Table (fact_sales): Transactional data linked to dimensions.

Usage:
  - these views can be queried directly for analytics and reporting
================================================================================
*/


-- =======================================================
-- 1. Create Dimension: gold.dim_customers
-- Description: Integrates customer data from CRM and ERP.
-- =======================================================

CREATE OR ALTER VIEW gold.dim_customers AS 
SELECT 
    -- Surrogate Key: Generated unique ID for the Data Warehouse
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
    
    -- Business Keys & Attributes
    ci.cst_id              AS customer_id,
    ci.cst_key             AS customer_number,
    ci.cst_firstname       AS first_name,
    ci.cst_lastname        AS last_name,
    cl.cntry               AS country,
    ci.cst_marital_status  AS marital_status,
    
    -- Master Data Logic: Prioritize CRM gender, fallback to ERP if Unknown
    CASE 
        WHEN ci.cst_gndr != 'Unknown' THEN ci.cst_gndr 
        ELSE ISNULL(ca.gen, 'Unknown')
    END AS gender,
    
    ca.bdate               AS birthdate,
    ci.cst_create_date     AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS cl
   ON ci.cst_key = cl.cid;

GO

-- =======================================================
-- 2. Create Dimension: gold.dim_products
-- Description: Product master data filtered for current active products.
-- =======================================================
CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
    -- Surrogate Key
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    
    -- Business Keys & Attributes
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Important: Filter for current active products only

GO

-- =======================================================
-- 3. Create Fact Table: gold.fact_sales
-- Description: Transactional sales data linked to dimensions via Surrogate Keys.
-- =======================================================
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,  -- Foreign Key to dim_products
    cu.customer_key AS customer_key, -- Foreign Key to dim_customers
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;

GO
