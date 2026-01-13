/*
================================================================================
Script Purpose: Create Silver Layer Tables (DDL)
Description:
    This script initializes the tables for the 'Silver' layer in the Data Warehouse.
    It drops existing tables (if they exist) and recreates them with the correct 
    schema definition.
    
    Data Sources:
    - CRM System (Customer, Product, Sales)
    - ERP System (Customer, Location, Category)
    
    Metadata:
    - dwh_create_date: Tracks when the record was loaded into the Silver layer.
================================================================================
*/

-- =======================================================
-- Source: CRM System
-- =======================================================

/*
----------------------------------------------------------
Table: silver.crm_cust_info
Description: Stores cleansed customer demographic information.
----------------------------------------------------------
*/
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status NVARCHAR(50), -- Note: Confirm if 'Marital' spelling is intended
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME2 DEFAULT GETDATE() -- Audit Column
);
GO


/*
----------------------------------------------------------
Table: silver.crm_prd_info
Description: Stores cleansed product master data.
----------------------------------------------------------
*/
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*
----------------------------------------------------------
Table: silver.crm_sales_details
Description: Stores transactional sales data.
----------------------------------------------------------
*/
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


-- =======================================================
-- Source: ERP System
-- =======================================================

/*
----------------------------------------------------------
Table: silver.erp_cust_az12
Description: Stores ERP-specific customer attributes.
----------------------------------------------------------
*/
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR(50),
    bdate           DATE,
    gen             NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*
----------------------------------------------------------
Table: silver.erp_loc_a101
Description: Stores location/country reference data.
----------------------------------------------------------
*/
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR(50),
    cntry           NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*
----------------------------------------------------------
Table: silver.erp_px_cat_g1v2
Description: Stores product sub-category and maintenance info.
----------------------------------------------------------
*/
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR(50),
    cat             NVARCHAR(50),
    subcat          NVARCHAR(50),
    maintenance     NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
