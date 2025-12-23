/*
===========================================================
 Stored Procedure: Loading Data to Bronze Layer  (Source --> Bronze)
===========================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs a full load (Truncate + Insert) for both CRM and ERP datasets.
	It performs the following actions:
	-Truncates the bronze layer tables before loading data.
	-Uses the 'BULK INSERT' command to load data from CSV files to bronze layer tables. 

Parameters:
    None. 
    This procedure does not accept any parameters.

Usage Example:
	EXEC bronze.load_bronze
===========================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	-- Declare variables to track execution duration
	DECLARE @start_time DATETIME , @end_time DATETIME , @start_load_bronze_layer DATETIME , @end_load_bronze_layer DATETIME;

	BEGIN TRY
		PRINT '============================================================';
		PRINT 'Loading Data to Bronze Layer';
		PRINT '============================================================';
		
		-- Capture the start time for loading data to the entire bronze layer 
		SET @start_load_bronze_layer = GETDATE();

		-- =======================================================
        -- Loading CRM Tables
        -- =======================================================
		PRINT '------------------------------------------------------------';
		PRINT 'Loading Data to CRM Tables';
		PRINT '------------------------------------------------------------';

		-- 1. Load crm_cust_info
        -- Set start time to measure duration for this specific table
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info; 
		PRINT '>> Inserting Data Into:bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\DATA\Baraa\SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		-- Calculate end time and print duration for crm_cust_info
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '-------------------------------------';

		-- 2. Load crm_prd_info
        -- Set start time to measure duration for this specific table
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table:bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info; 
		PRINT '>> Inserting Data Into:bronze.crm_prd_info';	
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\DATA\Baraa\SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		-- Calculate end time and print duration for crm_prd_info
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '-------------------------------------';

		-- 3. Load crm_sales_details
        -- Set start time to measure duration for this specific table
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table:bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details; 
		PRINT '>> Inserting Data Into:bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\DATA\Baraa\SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		-- Calculate end time and print duration for crm_sales_details
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '-------------------------------------';
		
		-- =======================================================
        -- Loading ERP Tables
        -- =======================================================
		PRINT '------------------------------------------------------------';
		PRINT 'Loading Data to ERP Tables';
		PRINT '------------------------------------------------------------';

		-- 1. Load erp_cust_az12
        -- Set start time to measure duration for this specific table
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table:bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12; 
		PRINT '>> Inserting Data Into:bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\DATA\Baraa\SQL\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		-- Calculate end time and print duration for erp_cust_az12
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '-------------------------------------';

		-- 2. Load erp_loc_a101
        -- Set start time to measure duration for this specific table
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table:bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101; 
		PRINT '>> Inserting Data Into:bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\DATA\Baraa\SQL\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		-- Calculate end time and print duration for erp_loc_a101
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '-------------------------------------';

		-- 3. Load erp_px_cat_g1v2
        -- Set start time to measure duration for
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table:bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2; 
		PRINT '>> Inserting Data Into:bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\DATA\Baraa\SQL\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		-- Calculate end time and print duration for erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '-------------------------------------';

		-- Calculate total execution time for the whole layer
		SET @end_load_bronze_layer = GETDATE();
		PRINT '=====================================================';
		PRINT '>> Bronze Layer Loading is Completed ';
		PRINT '>> Bronze Layer Loading Duration: ' + CAST(DATEDIFF(second,@start_load_bronze_layer,@end_load_bronze_layer) AS NVARCHAR)+' seconds';
		PRINT '=====================================================';

	END TRY 
	-- Error Handling Block: Capture and print error details if any operation fails
	BEGIN CATCH
		PRINT '=====================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Line' + CAST (ERROR_LINE() AS NVARCHAR);
		PRINT 'Error State' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT 'Error Procedure' + ERROR_PROCEDURE();
		PRINT '=====================================================';
	END CATCH
END;
