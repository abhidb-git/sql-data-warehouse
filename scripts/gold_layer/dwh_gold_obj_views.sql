-- ==================================================================
-- Creating First Object CUSTOMERS
-- ==================================================================

CREATE VIEW dwh_gold.dim_customers AS 
	SELECT
		ROW_NUMBER () OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate Key (Act as PRIMARY KEY when required)
		ci.cst_id AS c ustomer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		la.cntry AS country,
		ci.cst_marital_status AS marital_status,
		CASE 
		 	WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- cst_gndr is MASTER column
		 	ELSE  COALESCE(ca.gen, '/na') -- fix gender where gen is NULL
		END AS gender,
		ca.bdate AS birthdate,
		ci.cst_create_date AS create_date
	FROM
		dwh_silver.crm_cust_info ci -- MASTER Table (Data from this is much more important and reason for using LEFT JOIN)
	LEFT JOIN
		dwh_silver.erp_cust_az12 ca ON ci.cst_key = ca.cid 
	LEFT JOIN
		dwh_silver.erp_loc_a101 la	ON ci.cst_key = la.cid
	
-- USE VIEW dim.customers by running -> SELECT * FROM dwh_gold.dim_customers

-- ==================================================================		
-- Creating Second Object PRODUCTS
-- ==================================================================		

CREATE VIEW dwh_gold.dim_products AS
	SELECT
		ROW_NUMBER () OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate Key (Act as PRIMARY KEY when required)
		pn.prd_id AS product_id,
		pn.prd_key AS product_number,
		pn.prd_nm AS product_name,
		pn.prd_cat_id AS category_id,
		pc.cat AS category,
		pc.subcat AS sub_category,
		pc.maintenance,
		pn.prd_cost AS product_cost,
		pn.prd_line AS product_line,
		pn.prd_start_dt AS star_date
	FROM
		dwh_silver.crm_prd_info pn
	LEFT JOIN
		dwh_silver.erp_px_cat_g1v2 pc ON pn.prd_cat_id = pc.id
	WHERE pn.prd_end_dt IS NULL -- Filter out historical data

-- USE VIEW dim.customers by running -> SELECT * FROM dwh_gold.dim_products
	
-- ==================================================================		
-- Creating Second Object SALES 
-- ==================================================================

-- Use the DIMENSION'S Surrogate keys instead of ID's to easily connect FACT with DIMENSIONS (For connecting DATA MODEL)

CREATE VIEW dwh_gold.fact_sales AS
	SELECT
		sd.sls_ord_num AS order_number,
		pr.product_key, -- Surrogate Key
		cu.customer_key, -- Surrogate Key
		sd.sls_order_dt AS order_date,
		sd.sls_ship_dt AS shipping_date,
		sd.sls_due_dt AS due_date,
		sd.sls_sales AS sales_amount,
		sd.sls_quantity AS quantity,
		sd.sls_price AS price	
	FROM
		dwh_silver.crm_sales_details sd
	LEFT JOIN
		dwh_gold.dim_customers cu ON cu.customer_id = sd.sls_cust_id
	LEFT JOIN
		dwh_gold.dim_products pr ON pr.product_number = sd.sls_prd_key




