    /*
    ===========================================================================
    Stored Procedure: silver.load_silver 

    Description:
        This procedure performs the ETL process to populate the Silver Layer.
        It cleans, transforms, and loads data from Bronze tables into Silver tables.
        
        Steps:
        1. Truncate Silver tables (Full Refresh).
        2. Insert data from Bronze with transformations (Data Quality rules).
        3. Measure and print execution time for each table.
        4. Handle errors using TRY...CATCH block.
    Parameters:
      None.
      This stored procedure dose not accept parameters or return any values.
    Usage Example:
	    EXEC silver.load_silver;
    ===========================================================================
    */

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    -- Declare variables to track execution duration
    DECLARE @start_time DATETIME, 
            @end_time DATETIME, 
            @start_load_silver_layer DATETIME, 
            @end_load_silver_layer DATETIME;

    BEGIN TRY
        PRINT '============================================================';
        PRINT 'Cleaning & Loading Data to Silver Layer';
        PRINT '============================================================';
        
        -- Capture the start time for loading data to the entire silver layer 
        SET @start_load_silver_layer = GETDATE();

        PRINT '------------------------------------------------------------';
        PRINT 'Cleaning & Loading Data to CRM Tables';
        PRINT '------------------------------------------------------------';
        
        /*
        ===========================================================================
        1. Table: silver.crm_cust_info
        Action: Deduplicate customers and standardize text fields.
        ===========================================================================
        */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        
        PRINT '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname, -- Clean: Remove unwanted spaces
            TRIM(cst_lastname) AS cst_lastname,   -- Clean: Remove unwanted spaces
            -- Transformation: Standardize Marital Status (S -> Single, M -> Married)
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'Unknown'
            END cst_marital_status,
            -- Transformation: Standardize Gender (M -> Male, F -> Female)
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'Unknown'
            END cst_gndr,
            cst_create_date
        FROM (
            -- Deduplication Logic: Keep only the most recent record per cst_id
            SELECT
                *,
                ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t 
        WHERE flag_last = 1; -- Filter to keep only the latest record
        
        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '-------------------------------------';
        

        /*
        ===========================================================================
        2. Table: silver.crm_prd_info
        Action: Clean product keys, handle NULL costs, and calculate End Dates.
        ===========================================================================
        */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        
        PRINT '>> Inserting Data Into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Transformation: Format Category ID
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,        -- Transformation: Extract pure Product Key
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,                       -- Data Quality: Handle NULL costs
            -- Transformation: Map Product Line codes to full names
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'Unknown'
            END prd_line,
            CAST(prd_start_dt AS DATE),
            -- Logic: Calculate End Date based on the Start Date of the next record
            CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' SECONDs';
        PRINT '-------------------------------------';
        

        /*
        ===========================================================================
        3. Table: silver.crm_sales_details
        Action: Validate dates and correct data consistency issues in Sales/Price.
        ===========================================================================
        */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        
        PRINT '>> Inserting Data Into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,  
            sls_cust_id, 
            sls_order_dt, 
            sls_ship_dt, 
            sls_due_dt, 
            sls_sales, 
            sls_quantity,
            sls_price    
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            -- Data Quality: Validate Date Formats (Order Date)
            CASE
                WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END sls_order_dt,
            -- Data Quality: Validate Date Formats (Ship Date)
            CASE
                WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END sls_ship_dt,
            -- Data Quality: Validate Date Formats (Due Date)
            CASE
                WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END sls_due_dt,
            -- Logic: Recalculate Sales if missing or incorrect (Sales = Qty * Price)
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            -- Logic: Recalculate Price if missing (Price = Sales / Qty)
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0 
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '-------------------------------------';
        

        PRINT '------------------------------------------------------------';
        PRINT 'Cleaning & Loading Data to ERP Tables';
        PRINT '------------------------------------------------------------';
        
        /*
        ===========================================================================
        4. Table: silver.erp_cust_az12
        Action: Clean Customer IDs and Normalize Gender.
        ===========================================================================
        */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        
        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT 
            -- Transformation: Remove 'NAS' prefix if present
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,
            -- Data Quality: Invalid birthdates (Future dates) set to NULL
            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate 
            END AS bdate,
            -- Transformation: Normalize Gender values
            CASE
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                ELSE 'Unnown' -- Kept as per original logic
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '-------------------------------------';


        /*
        ===========================================================================
        5. Table: silver.erp_loc_a101
        Action: Standardize Country Codes.
        ===========================================================================
        */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        
        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT 
            REPLACE(cid, '-', '') AS cid,
            -- Transformation: Map Country codes to full names
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'Unknown'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '-------------------------------------';


        /*
        ===========================================================================
        6. Table: silver.erp_px_cat_g1v2
        Action: Direct load for Product Categories.
        ===========================================================================
        */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        
        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT 
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '-------------------------------------';


        -- Calculate and Print Total Execution Time
        SET @end_load_silver_layer = GETDATE();
        PRINT '=====================================================';
        PRINT '>> Silver Layer Loading is Completed ';
        PRINT '>> Silver Layer Loading Duration: ' + CAST(DATEDIFF(SECOND, @start_load_silver_layer, @end_load_silver_layer) AS NVARCHAR) + ' seconds';
        PRINT '=====================================================';

    END TRY 
    
    /*
    ===========================================================================
    Error Handling Block
    Description: Catches any runtime errors and prints debugging details.
    ===========================================================================
    */
    BEGIN CATCH
        PRINT '=====================================================';
        PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Procedure: ' + ERROR_PROCEDURE();
        PRINT '=====================================================';
    END CATCH
END
