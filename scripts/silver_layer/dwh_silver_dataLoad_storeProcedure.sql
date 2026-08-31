-- Creating STORE PROCEDURE for below script to load the clean data from dwh_bronze to dwh_silver tables
-- Supplementry script file is there with full explanation of the below code with commnets with name dwh_data_insrt_slvrDB.sql

-- Drop the existing procedure if it already exists
DROP PROCEDURE IF EXISTS dwh_silver.load_silver;

-- CREATING PROCEDURE with name dwh_silver.load_silver
DELIMITER $$

CREATE PROCEDURE dwh_silver.load_silver ()
BEGIN
	
	TRUNCATE TABLE dwh_silver.crm_cust_info;
	TRUNCATE TABLE dwh_silver.crm_prd_info;
	TRUNCATE TABLE dwh_silver.crm_sales_details;
	TRUNCATE TABLE dwh_silver.erp_cust_az12;
	TRUNCATE TABLE dwh_silver.erp_loc_a101;
	TRUNCATE TABLE dwh_silver.erp_px_cat_g1v2;
	-- ===========================================================================================
	-- 1. dwh_silver.crm_cust_info
	-- ===========================================================================================
	
	INSERT INTO dwh_silver.crm_cust_info
	(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)
	SELECT
		cst_id,
		TRIM(cst_key) AS cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			ELSE 'n/a'
		END cst_marital_status -- normalize gndr marital_status to readable format
		,
		CASE
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			ELSE 'n/a'
		END cst_gndr, -- normalize gndr values to readable format
		CASE
			WHEN LENGTH(REGEXP_REPLACE(cst_create_date, '[^0-9]', '')) != 8 THEN NULL
			ELSE STR_TO_DATE (CAST(cst_create_date AS CHAR), '%d-%m-%Y')
		END AS cst_create_date
	FROM
		(SELECT -- removing duplicates
			*,
		 ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flg
		 FROM 
		 	dwh_bronze.crm_cust_info) t
	WHERE flg = 1;
	
	-- ===========================================================================================
	-- 2. dwh_silver.crm_prd_info
	-- ===========================================================================================
	
	INSERT INTO dwh_silver.crm_prd_info
	(
		prd_id,
		prd_cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	SELECT
		prd_id,
		REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
		SUBSTRING(prd_key, 7) AS prd_key,
		prd_nm,
		COALESCE(prd_cost, 0) AS prd_cost,
		CASE
			WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			ELSE 'n/a'
		END AS prd_line,
		prd_start_dt,
		LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL 1 DAY AS prd_end_dt
	FROM dwh_bronze.crm_prd_info;
		
	-- ===========================================================================================
	-- 3. dwh_silver.crm_sales_details
	-- ===========================================================================================
	
	INSERT INTO dwh_silver.crm_sales_details
	(
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
	WITH fixed_price AS
	(
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			CASE
				WHEN sls_price <= 0 OR sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price
			END AS corrected_price
		FROM dwh_bronze.crm_sales_details
	),
	fixed_sales AS
	(
		SELECT
			*,
			CASE
				WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != corrected_price * sls_quantity 
					THEN corrected_price * ABS(NULLIF(sls_quantity, 0))
				ELSE sls_sales
			END AS corrected_sales
		FROM fixed_price
	)
	SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE 
			WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 THEN NULL
			ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d') -- SAFE DATE CONVERSION
		END AS sls_order_dt,
		CASE 
			WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 THEN NULL
			ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d') -- SAFE DATE CONVERSION
		END AS sls_ship_dt,
		CASE 
			WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 THEN NULL
			ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d') -- SAFE DATE CONVERSION
		END AS sls_due_dt,
		corrected_sales AS sls_sales,
		sls_quantity,
		corrected_price AS sls_price
	FROM fixed_sales;
	
	-- ===========================================================================================
	-- 4. dwh_silver.erp_cust_az12
	-- ===========================================================================================
	
	INSERT INTO dwh_silver.erp_cust_az12
	(
		cid,
		bdate,
		gen
	)
	SELECT
		CASE 
			WHEN cid LIKE ('NAS%') THEN SUBSTRING(cid, 4)
			ELSE cid
		END AS cid,
		CASE	
			WHEN CAST(bdate AS DATE) > CURRENT_DATE() THEN NULL
			ELSE CAST(bdate AS DATE)
		END AS bdate,
		CASE
			WHEN UPPER(TRIM(REPLACE(gen, '\r',''))) IN ('M', 'MALE') THEN 'Male'
			WHEN UPPER(TRIM(REPLACE(gen, '\r', ''))) IN ('F', 'FEMALE') THEN 'Female'
			ELSE 'n/a'
		END AS gen
	FROM dwh_bronze.erp_cust_az12;
	
	-- ===========================================================================================
	-- 5. dwh_silver.erp_loc_a101
	-- ===========================================================================================
	
	INSERT INTO dwh_silver.erp_loc_a101
	(
		cid,
		cntry
	)
	SELECT
		REPLACE(cid, '-', '') AS cid,
		CASE
			WHEN cntry IS NULL OR REPLACE(TRIM(cntry), '\r', '') = '' THEN 'n/a'
			WHEN REPLACE(TRIM(cntry), '\r', '') = 'DE' THEN 'Germany'
			WHEN REPLACE(TRIM(cntry), '\r', '') IN ('US', 'USA') THEN 'United States'
			ELSE TRIM(cntry)
		END AS cntry
	FROM dwh_bronze.erp_loc_a101;
	
	-- ===========================================================================================
	-- 6. dwh_silver.erp_px_cat_g1v2
	-- ===========================================================================================
	
	INSERT INTO dwh_silver.erp_px_cat_g1v2
	(
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
	FROM dwh_bronze.erp_px_cat_g1v2;

END $$

DELIMITER ;

-- Use CALL dwh_silver.load_silver()

