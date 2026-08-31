TRUNCATE TABLE crm_cust_info;
	
	/* USE BELOW TWO ONLY IF YOUR DATA REQUIRE THEM
	 * =================================================================================================
	 * ENCLOSED BY '"' --> if you see text inside double quotes, ignore any commas or line breaks
	 * hidden within it. Treat everything inside those quotes as one single value.
	 * EXAMPLE ->
	 * Scenario in your CSV			Without these rules					With these rules
	 * 1, "John, Jr.", Doe		Splits into 4 columns (Crashes)		Maps into 3 correct columns
	 * 
	 * ESCAPED BY '' --> Do not use backslashes as escape commands. Read backslashes exactly as literal
	 * characters, and handle quote fields exactly the way Excel does
	 * EXAMPLE ->
	 * Scenario in your CSV			Without these rules						With these rules
	 * "Windows\Paths"			Becomes WindowsPaths (Corrupt data)		Stays exactly as Windows\Paths
	 */
	
	LOAD DATA LOCAL INFILE 'D:/MySQL projects/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
	INTO TABLE crm_cust_info
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n' -- could have added \r also to remove lines terminated by Window carriage (invisble character)
							-- but i didn't bcz it better to know how to handle if we encounter in future which we did while
							-- transforming data for uploading in dwh_silver layer tables
	
	IGNORE 1 ROWS -- Will ignore the TOP ROW which generally hold columns name only
	(
		@v_cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)
	SET cst_id = NULLIF(@v_cst_id, '');
	
	/*
	================================================================================
	💡 KNOWLEDGE BASE: CODES, VARIABALES, AND CSV MAPPING MECHANICS
	================================================================================
	
	1. THE 'v_' PREFIX NAMING CONVENTION
	   - Purpose: It is an industry-standard naming convention.
	   
	   - Benefit: It makes it instantly clear to any developer or teammate that the 
	     field is a temporary in-memory variable, not a physical table column.
	
	2. WHY WE SEPARATE NUMBERS FROM STRINGS (Why not use '@' for everything?)
	   - String Columns (VARCHAR/TEXT): Leniency. If a text cell is empty in the CSV, 
	     MySQL handles it automatically by inserting a harmless empty string ('').
	     
	   - Numeric Columns (INT): Strictness. If an integer cell is empty, MySQL will 
	     try to force text/blank data into a math slot. This causes a fatal crash 
	     in strict mode or forces an inaccurate '0'.
	     
	   - Rules for Floats/Decimals: Just like INTs, FLOAT and DECIMAL columns must 
	     use variables if they contain empty cells, as they face the exact same 
	     strict math validation rules and crash risks.
	
	3. WHY WE MUST LIST ALL COLUMNS INSIDE THE PARENTHESES ()
	   - Question: Why not just list the single column that needs a variable?
	   
	   - Answer: The parentheses () create a strict structural map of your CSV file. 
	     MySQL reads the CSV columns from left to right. If your file has 7 columns, 
	     you must list 7 slots inside the () in the exact same order.
	     
	   - Impact: If you skip listing the regular columns, MySQL loses its alignment, 
	     misplaces your data, or ignores the rest of your CSV columns completely. 
	     The list acts as the master blueprint to map every CSV column correctly 
	     while safely intercepting the troubled ones.
	================================================================================
	*/
	
	
TRUNCATE TABLE crm_prd_info;
	
	LOAD DATA LOCAL INFILE 'D:/MySQL projects/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
	INTO TABLE crm_prd_info
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS
	(
		@v_prd_id,
		prd_key,
		prd_nm,
		@v_prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt)
	SET prd_id = NULLIF(@v_prd_id, ''), -- multiple set can only be separated by ',' do not write multiple
		prd_cost = NULLIF(@v_prd_cost, ''); -- SET while loading the data it is not allowed
		

TRUNCATE TABLE crm_sales_details;
	
	LOAD DATA LOCAL INFILE 'D:/MySQL projects/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
	INTO TABLE crm_sales_details
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS
	(
		sls_ord_num,
		sls_prd_key,
		@v_sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		@v_sls_sales,
		@v_sls_quantity,
		@v_sls_price)
	SET sls_cust_id = NULLIF(@v_sls_cust_id, ''),
		sls_sales = NULLIF(@v_sls_sales, ''),
		sls_quantity = NULLIF(@v_sls_quantity, ''),
		sls_price = NULLIF(@v_sls_price, '');
	
TRUNCATE TABLE erp_cust_az12;
	

	LOAD DATA LOCAL INFILE 'D:/MySQL projects/sql-data-warehouse-project/datasets/source_erp/cust_az12.csv'
	INTO TABLE erp_cust_az12
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS;
	
TRUNCATE TABLE erp_loc_a101;
	

	LOAD DATA LOCAL INFILE 'D:/MySQL projects/sql-data-warehouse-project/datasets/source_erp/loc_a101.csv'
	INTO TABLE erp_loc_a101
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS;
	
	
TRUNCATE TABLE erp_px_cat_g1v2;
	
	LOAD DATA LOCAL INFILE 'D:/MySQL projects/sql-data-warehouse-project/datasets/source_erp/px_cat_g1v2.csv'
	INTO TABLE erp_px_cat_g1v2
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS;
		
/* You have to Run all the code as SCRIPT and you will load the data for Every table in One go
 * In mysql STORE PROCEDURE will not allow to run the code LOAD DATA.... because of it's safety feature and this is the
 * reason i was unable to create the procedure for this script even in dynamic sql LOAD DATA is not allowed
 */

/*Below code will show us the number of records inserted in the tables which you can verify from the number of records
 * you have in your Excel file (csv file)
 */
SELECT 'crm_cust_info' AS table_name, COUNT(*) AS data_count FROM crm_cust_info
UNION ALL
SELECT 'crm_prd_info' AS table_name, COUNT(*) AS data_count FROM crm_prd_info
UNION ALL
SELECT 'crm_sales_details' AS table_name, COUNT(*) AS data_count FROM crm_sales_details
UNION ALL
SELECT 'erp_cust_az12' AS table_name, COUNT(*) AS data_count FROM erp_cust_az12
UNION ALL
SELECT 'erp_loc_a101' AS table_name, COUNT(*) AS data_count FROM erp_loc_a101
UNION ALL
SELECT 'erp_px_cat_g1v2' AS table_name, COUNT(*) AS data_count FROM erp_px_cat_g1v2;


