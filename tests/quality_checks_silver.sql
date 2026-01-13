/*
================================================================================
Script Purpose: Data Quality Checks (Silver Layer)

Description: 
    This script performs quality assurance checks on the 'Silver' layer tables.
    It validates that the ETL process successfully cleaned, standardized, 
    and deduplicated the data.
    
Checks included:
    1. Zero Nulls & Duplicates (Primary Key integrity).
    2. Zero Unwanted Spaces (TRIM check).
    3. Data Standardization (Confirming values are normalized).
    4. Date Logic (Confirming relationships like Order Date < Ship Date).

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
================================================================================
*/

----------------------------------------------------------------------------------
--                               Table: silver.crm_cust_info
----------------------------------------------------------------------------------

-- Check 1: Duplicate Primary Keys
-- Expectation: No Results (Deduplication Logic Validation)
SELECT
    cst_id,
    COUNT(*) AS duplicates
FROM silver.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1;

-- Check 2: Unwanted Spaces
-- Expectation: No Results (TRIM Logic Validation)
SELECT cst_firstname FROM silver.crm_cust_info WHERE cst_firstname != TRIM(cst_firstname);
SELECT cst_lastname  FROM silver.crm_cust_info WHERE cst_lastname  != TRIM(cst_lastname);

-- Check 3: Data Standardization (Marital Status)
-- Expectation: Only 'Single', 'Married', 'Unknown' (No 'S' or 'M')
SELECT DISTINCT cst_material_status 
FROM silver.crm_cust_info
WHERE cst_material_status NOT IN ('Single', 'Married', 'Unknown');

-- Check 4: Data Standardization (Gender)
-- Expectation: Only 'Male', 'Female', 'Unknown' (No 'M' or 'F')
SELECT DISTINCT cst_gndr 
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'Unknown');


----------------------------------------------------------------------------------
--                               Table: silver.crm_prd_info
----------------------------------------------------------------------------------

-- Check 1: Duplicate Primary Keys
-- Expectation: No Results
SELECT
    prd_id,
    COUNT(*) AS duplicates
FROM silver.crm_prd_info
GROUP BY prd_id 
HAVING COUNT(*) > 1;

-- Check 2: Unwanted Spaces
-- Expectation: No Results
SELECT prd_nm FROM silver.crm_prd_info WHERE prd_nm != TRIM(prd_nm);

-- Check 3: Nulls or Negative Costs
-- Expectation: No Results (ISNULL and validation logic)
SELECT prd_cost 
FROM silver.crm_prd_info 
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check 4: Data Standardization (Product Lines)
-- Expectation: No short codes like 'M', 'R', 'S', 'T'
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info
WHERE prd_line NOT IN ('Mountain', 'Road', 'Touring', 'other Sales', 'Unknown');

-- Check 5: Invalid Date Logic
-- Expectation: No Results
SELECT * FROM silver.crm_prd_info 
WHERE prd_start_dt > prd_end_dt;


----------------------------------------------------------------------------------
--                               Table: silver.crm_sales_details
----------------------------------------------------------------------------------

-- Check 1: Invalid Date Logic (Order Date vs Ship/Due Date)
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check 2: Data Integrity (Sales Calculation)
-- Formula: Sales = Quantity * Price
-- Expectation: No Results (The ETL forced this calculation)
SELECT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
ORDER BY sls_sales, sls_quantity, sls_price;


----------------------------------------------------------------------------------
--                               Table: silver.erp_cust_az12
----------------------------------------------------------------------------------

-- Check 1: Out of Range Dates
-- Expectation: No Results (Future dates were converted to NULL in ETL)
SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- Check 2: Data Standardization (Gender)
-- Expectation: Only 'Male', 'Female', 'Unknown'
SELECT DISTINCT gen 
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female', 'Unnown'); -- Matches ETL Logic 'Unnown' typo preserved


----------------------------------------------------------------------------------
--                               Table: silver.erp_loc_a101
----------------------------------------------------------------------------------

-- Check 1: Data Standardization (Country Codes)
-- Expectation: No short codes like 'US', 'DE'
SELECT DISTINCT cntry 
FROM silver.erp_loc_a101 
WHERE LEN(cntry) <= 3 -- Check for remaining short codes
ORDER BY cntry;


----------------------------------------------------------------------------------
--                               Table: silver.erp_px_cat_g1v2
----------------------------------------------------------------------------------

-- Check 1: Unwanted Spaces
-- Expectation: No Results
SELECT * FROM silver.erp_px_cat_g1v2 WHERE cat         != TRIM(cat);
SELECT * FROM silver.erp_px_cat_g1v2 WHERE subcat      != TRIM(subcat);
SELECT * FROM silver.erp_px_cat_g1v2 WHERE maintenance != TRIM(maintenance);
