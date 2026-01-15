/*
================================================================================
Quality Checks
================================================================================
Script Purpose: Gold Layer Data Quality Checks
Description: 
    Validates the integrity of the Star Schema.
    
    Checks:
    1. Data Consistency: Verify transformed columns (e.g., Gender).
    2. Dimension Structure: Review the Product dimension.
    3. Referential Integrity: Ensure every Fact record links to valid Dimensions.
================================================================================
*/

----------------------------------------------------------------------------------
-- Check 1: Data Consistency (Dimensions)
----------------------------------------------------------------------------------
-- Goal: Ensure gender is normalized (Male, Female, Unknown) after joining CRM & ERP
SELECT DISTINCT 
    gender
FROM gold.dim_customers
ORDER BY gender;


----------------------------------------------------------------------------------
-- Check 2: Dimension Structure
----------------------------------------------------------------------------------
-- Goal: Review the product dimension view (Spot check)
SELECT *
FROM gold.dim_products; -- Corrected from dim_product to dim_products


----------------------------------------------------------------------------------
-- Check 3: Foreign Key Integrity (Fact to Dimension)
----------------------------------------------------------------------------------
-- Goal: Identify "Orphaned" records.
-- Explanation: Every sale MUST belong to a valid Customer and a valid Product.
-- Result Expectation: No Results (Empty Table).
SELECT 
    f.order_number,
    f.customer_key,
    f.product_key
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products AS p -- Corrected table name
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL  -- Fail if Product link is broken
   OR c.customer_key IS NULL; -- Fail if Customer link is broken
