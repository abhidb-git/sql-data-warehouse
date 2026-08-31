-- ===========================================================
--	FOR CUSTOMERS OBJECT - DIMENSION TABLE
-- ===========================================================

-- First check if we are getting duplicate values after joining the tables
-- It should not give us any record or row 

SELECT
	cst_id, COUNT(*)
FROM
	(
	SELECT
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM
		dwh_silver.crm_cust_info ci
	LEFT JOIN
		dwh_silver.erp_cust_az12 ca ON ci.cst_key = ca.cid 
	LEFT JOIN
		dwh_silver.erp_loc_a101 la	ON ci.cst_key = la.cid) t
GROUP BY
	cst_id
HAVING COUNT(*)>1

-- Let's fix the Gender quality issue from ci.cst_gndr and ca.gen and make it more enrich

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE 
	 	WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
	 	ELSE  COALESCE(ca.gen, '/na')
	END new_gen	 
FROM
	dwh_silver.crm_cust_info ci
LEFT JOIN
	dwh_silver.erp_cust_az12 ca ON ci.cst_key = ca.cid 
LEFT JOIN
	dwh_silver.erp_loc_a101 la	ON ci.cst_key = la.cid
	
-- ===========================================================
--	FOR PRODUCTS OBJECT - DIMENSION TABLE
-- ===========================================================	
	
-- First check if we are getting duplicate values after joining the tables
-- It should not give us any record or row 
	
SELECT
	prd_key,
	COUNT(*)
FROM
	(SELECT
		pn.prd_id,
		pn.prd_key,
		pn.prd_cat_id,
		pn.prd_nm,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt,
		pn.prd_end_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
	FROM
		dwh_silver.crm_prd_info pn
	LEFT JOIN
		dwh_silver.erp_px_cat_g1v2 pc ON pn.prd_cat_id = pc.id
	WHERE pn.prd_end_dt IS NULL) t -- Filter out historical data
GROUP BY
	prd_key
HAVING COUNT(*)>1


-- ===========================================================
--	FOR PRODUCTS OBJECT -- FACT TABLE
-- ===========================================================



SELECT
	sd.sls_ord_num,
	sd.sls_prd_key, -- add surrogate created in (pr.product_key) view product_key insted of (sd.sd.sls_prd_key)
	sd.sls_cust_id, -- add surrogate created in (cu.customer_key) view customer_key insted of (sd.sls_cust_id)
	sd.sls_order_dt,
	sd.sls_ship_dt,
	sd.sls_due_dt,
	sd.sls_sales,
	sd.sls_quantity,
	sd.sls_price	
FROM
	dwh_silver.crm_sales_details sd
LEFT JOIN
	dwh_gold.dim_customers cu ON cu.customer_id = sd.sls_cust_id -- Joining with the VIEW created with name dim_customers
LEFT JOIN
	dwh_gold.dim_products pr ON pr.product_number = sd.sls_prd_key -- Joining with the VIEW created with name dim_products


-- After adding Surrogate keys
-- -------------------------------------------
	
SELECT
	sd.sls_ord_num,
	pr.product_key, -- add surrogate created in (pr.product_key) view product_key insted of (sd.sd.sls_prd_key)
	cu.customer_key, -- add surrogate created in (cu.customer_key) view customer_key insted of (sd.sls_cust_id)
	sd.sls_order_dt,
	sd.sls_ship_dt,
	sd.sls_due_dt,
	sd.sls_sales,
	sd.sls_quantity,
	sd.sls_price	
FROM
	dwh_silver.crm_sales_details sd
LEFT JOIN
	dwh_gold.dim_customers cu ON cu.customer_id = sd.sls_cust_id
LEFT JOIN
	dwh_gold.dim_products pr ON pr.product_number = sd.sls_prd_key


-- Quality Check (Foreign Key Integrity (Dimensions))
-- Should not give any record
	
SELECT *
FROM dwh_gold.fact_sales f
LEFT JOIN dwh_gold.dim_products p ON p.product_key = f.product_key
LEFT JOIN dwh_gold.dim_customers c ON c.customer_key = f.customer_key 
WHERE f.product_key IS NULL AND c.customer_key IS NULL







	