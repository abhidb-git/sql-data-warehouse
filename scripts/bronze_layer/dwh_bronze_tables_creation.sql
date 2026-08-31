-- ============================================================================
-- PROJECT: Data Warehouse ETL (Bronze Layer)
-- DESCRIPTION: Creation and loading of CRM and ERP source tables.
-- ============================================================================

-CREATE DATABASE IF NOT EXISTS dwh_bronze;
-CREATE DATABASE IF NOT EXISTS dwh_silver;
-CREATE DATABASE IF NOT EXISTS dwh_gold;

-USE dwh_bronze;

-- ============================================================================
-- 1. CRM SOURCE LAYER TABLES
-- ============================================================================

-- cust_info

	CREATE TABLE IF NOT EXISTS crm_cust_info (
	    cst_id INT,
	    cst_key VARCHAR(50),
	    cst_firstname VARCHAR(50),
	    cst_lastname VARCHAR(50),
	    cst_marital_status VARCHAR(10),
	    cst_gndr VARCHAR(10),
	    cst_create_date VARCHAR(50)
	);
	
-- prd_info
	
	CREATE TABLE IF NOT EXISTS crm_prd_info (
	    prd_id INT,
	    prd_key VARCHAR(50),
	    prd_nm VARCHAR(50),
	    prd_cost INT,
	    prd_line VARCHAR(5),
	    prd_start_dt VARCHAR(50),
	    prd_end_dt VARCHAR(50)
	);
	
-- sales_details
	
	CREATE TABLE IF NOT EXISTS crm_sales_details (
	    sls_ord_num VARCHAR(50),
	    sls_prd_key VARCHAR(50),
	    sls_cust_id INT,
	    sls_order_dt VARCHAR(50),
	    sls_ship_dt VARCHAR(50),
	    sls_due_dt VARCHAR(50),
	    sls_sales INT,
	    sls_quantity INT,
	    sls_price INT
	);
	
	-- ============================================================================
	-- 2. ERP SOURCE LAYER TABLES
	-- ============================================================================
	
-- cust_az12
	
	CREATE TABLE IF NOT EXISTS erp_cust_az12 (
	    CID VARCHAR(50),
	    BDATE VARCHAR(50),
	    GEN VARCHAR(10)
	);
	
-- loc_a101
	
	CREATE TABLE IF NOT EXISTS erp_loc_a101 (
	    CID VARCHAR(50),
	    CNTRY VARCHAR(50)
	);
	
-- ERP px_cat_g1v2
	
	CREATE TABLE IF NOT EXISTS erp_px_cat_g1v2 (
	    ID VARCHAR(20),
	    CAT VARCHAR(50),
	    SUBCAT VARCHAR(70),
	    MAINTENANCE VARCHAR(10)
	);
	
	







	




