USE dwh_silver;


-- ===========================================================================
-- 	TABLES CREATION FOR dwh_silver DATABASE
-- ===========================================================================



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
	    cst_create_date DATE,
	    dwh_load_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
	
/*
 * Using 
	    dwh_load_at DATETIME DEFAULT TIMESTAMP just to store meta_data for when this table created
	    so that we can use this data in future if we need to track it for further purpose
*/
	
-- prd_info
	
	CREATE TABLE IF NOT EXISTS crm_prd_info (
	    prd_id INT,
	    prd_key VARCHAR(50),
	    prd_cat_id VARCHAR(50)
	    prd_nm VARCHAR(50),
	    prd_cost INT,
	    prd_line VARCHAR(30),
	    prd_start_dt DATE,
	    prd_end_dt VARCHAR(50),
	    dwh_load_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
-- sales_details
	
	CREATE TABLE IF NOT EXISTS crm_sales_details (
	    sls_ord_num VARCHAR(50),
	    sls_prd_key VARCHAR(50),
	    sls_cust_id INT,
	    sls_order_dt DATE,
	    sls_ship_dt DATE,
	    sls_due_dt DATE,
	    sls_sales INT,
	    sls_quantity INT,
	    sls_price INT,
	    dwh_load_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
	-- ============================================================================
	-- 2. ERP SOURCE LAYER TABLES
	-- ============================================================================
	
-- cust_az12
	
	CREATE TABLE IF NOT EXISTS erp_cust_az12 (
	    CID VARCHAR(50),
	    BDATE VARCHAR(50),
	    GEN VARCHAR(10),
	    dwh_load_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
-- loc_a101
	
	CREATE TABLE IF NOT EXISTS erp_loc_a101 (
	    CID VARCHAR(50),
	    CNTRY VARCHAR(50),
	    dwh_load_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
-- ERP px_cat_g1v2
	
	CREATE TABLE IF NOT EXISTS erp_px_cat_g1v2 (
	    ID VARCHAR(20),
	    CAT VARCHAR(50),
	    SUBCAT VARCHAR(70),
	    MAINTENANCE VARCHAR(10),
	    dwh_load_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
