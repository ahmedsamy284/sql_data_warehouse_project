/*
===========================================================
 Create Database and Medallion Schemas
===========================================================
DESCRIPTION: 
    This script initializes the 'DataWarehouse' environment. 
    It follows the Medallion Architecture by setting up three distinct 
    layers: Bronze, Silver, and Gold.

PROCESS:
    1. Checks if 'DataWarehouse' already exists.
    2. Drops the existing database if found (Full Reset).
    3. Creates a fresh 'DataWarehouse' database.
    4. Configures the internal schemas: 'bronze', 'silver', and 'gold'.

================================================================================
⚠️ WARNING:
    Running this script will PERMANENTLY DELETE the entire 'DataWarehouse' 
    database and all its contents. Ensure you have a backup before execution.
================================================================================
*/

USE master;
GO

-- Drop and Recreate the 'DataWarehouse' Database (if it exists)

IF EXISTS (SELECT 1 FROM sys.databases WHERE name ='DataWarehouse')

BEGIN

	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;

END;
GO

-- Create the new 'DataWarehouse'database

 CREATE DATABASE DataWarehouse;
 GO

 USE DataWarehouse;
 GO

 -- Create Schemas

 Create Schema bronze;
 GO

 Create Schema silver;
 GO

 Create Schema gold;
 GO
