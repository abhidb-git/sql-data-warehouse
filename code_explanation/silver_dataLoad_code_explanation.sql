-- ===========================================================================================
-- cleaning the data before adding it into dwh_silver.crm_cust_info
-- ===========================================================================================
TRUNCATE TABLE dwh_silver.crm_cust_info; -- always truncate to load fresh data from start, else it will duplicate the data

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
WHERE flg = 1; -- select most recent record per customer

-- We have cst_create_date as VARCHAR and we will update it to DATE in dwh_silver

SELECT * FROM dwh_silver.crm_cust_info;

-- ===========================================================================================
-- cleaning data before adding it into dwh_silver.crm_prd_info
-- ===========================================================================================

TRUNCATE TABLE dwh_silver.crm_prd_info;

INSERT INTO dwh_silver.crm_prd_info
(
	prd_id,
	prd_cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt)
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
	END prd_line
	,
	prd_start_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL 1 DAY AS prd_end_dt
FROM
	dwh_bronze.crm_prd_info;


SELECT * FROM dwh_silver.crm_prd_info;
	
	/*
	 * For creating new column cat_id as after analysing the data we found that
	 * bronze.erp_px_cat_g1v2 has column name as id which holds 5 characters only and match sames with
	 * first 5 characters of our bronze.prd_key and that's we are creating this new column so that
	 * we can use this cat_id to JOIN the tables when require
	 * 
	 * FUNCTION SUBSTRING -> takes 3 arguments
	 * =========================================================================================
	 * 1st -> column name from which you want to extract characters
	 * 
	 * 2nd -> from which character position you want to extract, 1 means from the begining of 1st
	 * character, 2 means after 1st character and so on if we increase number
	 * 
	 * 3rd -> how many characters you want to extract
	 * 
	 * NOTE
	 * ----------------------------------------------
	 * If we pass only two arguments in SUBSTRING(xyz, 7) in MySql version, it automatically acts as
	 * dynamic version, means wrting SUBSTRING(xyz, 7, LEN(xyz)) is as good as writing- 
	 * SUBSTRING(xyz, 7), both are valid and tell the sql to get the characters starting from 7th
	 * place till the end of last character
	 * 
	 * FUNCTION REPLACE -> takes 3 arguments
	 * ==========================================================================================
	 * 1st -> column which you want to replace
	 * 2nd -> character you want to replace
	 * 3rd -> new character with which you want to replace old one
	 * 
	 * 
	 *Let's change prd_start_dt and prd_end_dt to DATE format from VARCHAR(20)
	 *==============================================================================================
	 *We can do that by performing below 3 steps OR the most easy way is Just wrap it inside CAST(xyz, AS DATE)
	 *
	 *Step 1
	 *-------------------
	 * ALTER TABLE crm_prd_info
	 * ADD COLUMN prd_start_dt1 VARCHAR(20)
	 * 
	 * Step 2
	 * ---------------------
	 * UPDATE crm_prd_info
	 * SET prd_start_dt1 = STR_TO_DATE(REPLACE(prd_start_dt, '\r', ''), '%d-%m-%Y')
	 * WHERE prd_start_dt REGEXP('[0-9]{2}-[0-9]{2}-[0-9]{4}')
	 * 
	 * why '\r' -> as we checked our data for prd_start_dt and prd_end_dt have lines separated by
	 * '/n' as well as Window carriage '\r' and we already handled /n while loading the data using
	 * bulk import and here only handling \r and it will be replaced by nothing ''
	 * 
	 * We used REGEXP in WHERE clause to make sure that only feilds cotaining numberic values will
	 * be handled and in form of 2 digits for date, 2 for month and 4 for year
	 * 
	 * Step 3
	 * -----------------------
	 * ALTER TABLE crm_prd_info
	 * RENAME COLUMN prd_start_dt1 TO prd_start_dt
	 * 
	 * and,
	 * 
	 * ALTER TABLE crm_prd_info
	 * DROP COLUMN prd_start_dt1*/
	


-- ===========================================================================================
-- cleaning data before adding it into dwh_silver.crm_sales_details
-- ===========================================================================================

TRUNCATE TABLE dwh_silver.crm_sales_details;

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
    sls_price)
WITH fixed_price AS
(SELECT 
	sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
	CASE
		WHEN sls_price <= 0 OR
		sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END AS corrected_price
FROM
	dwh_bronze.crm_sales_details
	),
fixed_sales AS
(
	SELECT
	*,
	CASE
		WHEN sls_sales <= 0 OR
		sls_sales IS NULL OR
		sls_sales != corrected_price * sls_quantity THEN corrected_price * ABS(NULLIF(sls_quantity, 0)) -- ABS() change any negative number to positive
		ELSE sls_sales
	END corrected_sales
FROM
	fixed_price
	)

SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE 
		WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%d-%m-%Y') -- CAST(xyz, AS CHAR) is to change data from it's type of INT,
	END sls_order_dt,											-- VARCHAR, etc to CHAR or any other valid format as per you SQL engine
	CASE 
		WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%d-%m-%Y')
	END sls_ship_dt,
	CASE 
		WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%d-%m-%Y')
	END sls_due_dt,
	corrected_sales AS sls_sales,
	sls_quantity,
	corrected_price AS sls_price
FROM fixed_sales;

SELECT * FROM dwh_silver.crm_sales_details;


/* IMPORTANT
 * ===========================
 * Why to use 2 CTE's?
 * ----------------------------
 * 
 * If we try to fix the sls_sales, sls_price and sls_qunatity as per our business rule which are below - 
 * 
 * 1 -> When Sales is negative, zero, or null, derive it using price and quantity (price*qunatity)
 * 2 -> When Price is zero or null, calculate it using sales and quantity (sales/quantity)
 * 3 -> When Price is negative, change it to positive
 * 
 * We will get stuck in circular dependency, means our sales depends on sls_price * sls_qunatity which is basic fundamental
 * for calculating the same and for the price sls_sales / sls_qunatity.
 * 
 * Why can't we just use one SELECT?

Suppose we have:

sales    = 10
price    = 0
quantity = 2

If price is 0 → calculate price = sales / quantity
price = 10 / 2 = 5 So the correct price is 5.

Now, sales should be checked using the corrected price:
sales = corrected_price × quantity
      = 5 × 2 = 10
      
But if we try to do everything in one SELECT:

SELECT
    CASE
        WHEN sls_price <= 0
        THEN sls_sales / sls_quantity
        ELSE sls_price
    END AS corrected_price,

    CASE
        WHEN sls_sales != corrected_price * sls_quantity
        THEN corrected_price * sls_quantity
        ELSE sls_sales
    END AS corrected_sales
FROM sales;

The problem is:

corrected_sales
       ↓
needs corrected_price
       ↓
but corrected_price was created
in the SAME SELECT

SQL generally doesn't allow one SELECT expression to use another SELECT expression's alias at the same query level.
Also, simply putting corrected_price above corrected_sales doesn't help. SQL doesn't work like a programming language
where the first line creates a variable that the next line can immediately use.

So why use 2 CTEs?
-----------------------------------------------------
We use the first CTE to create corrected_price first.
------------------------------------------------------
WITH fixed_price AS
(
    SELECT
        *,
        CASE
            WHEN sls_price <= 0 OR sls_price IS NULL
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS corrected_price
    FROM sales
)
Now our data logically looks like:
sales | price | quantity | corrected_price
------+-------+----------+----------------
  10  |   0   |    2     |       5
  
 Now corrected_price is available as an actual column from fixed_price.
 ------------------------------------------------------------------------- 
 So the second CTE can use it:
 ------------------------------------------------------------------------- 
  WITH fixed_price AS
(
    SELECT
        *,
        CASE
            WHEN sls_price <= 0 OR sls_price IS NULL
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS corrected_price
    FROM sales
),

fixed_sales AS
(
    SELECT
        *,
        CASE
            WHEN sls_sales <= 0
              OR sls_sales IS NULL
              OR sls_sales != corrected_price * sls_quantity
            THEN corrected_price * ABS(NULLIF(sls_quantity, 0))
            ELSE sls_sales
        END AS corrected_sales
    FROM fixed_price
)

Now the flow is very simple:
----------------------------------------------------------
Original Data
     ↓
CTE 1: Fix Price
     ↓
corrected_price = 5
     ↓
CTE 2: Fix Sales using corrected_price
     ↓
corrected_sales = 5 × 2 = 10

The easiest way to remember it
--------------------------------------------------------------
We use 2 CTEs because corrected_sales depends on corrected_price.

First CTE → calculate corrected price.

Second CTE → use corrected price to calculate corrected sales.
 */


-- ===========================================================================================
-- cleaning data before adding it into dwh_silver.erp_cust_az12
-- ===========================================================================================

TRUNCATE TABLE dwh_silver.erp_cust_az12;

INSERT INTO dwh_silver.erp_cust_az12
(
	cid,
	bdate,
	gen)
SELECT
	CASE 
		WHEN cid LIKE ('NAS%') THEN SUBSTRING(cid, 4)
		ELSE cid
	END AS cid,
	CASE	
		WHEN CAST(bdate AS DATE) > CURRENT_DATE() THEN NULL
		ELSE CAST(bdate AS DATE)
	END bdate,
	CASE
		WHEN UPPER(TRIM(REPLACE(gen, '\r',''))) IN ('M', 'MALE') THEN 'Male'
		WHEN UPPER(TRIM(REPLACE(gen, '\r', ''))) IN ('F', 'FEMALE') THEN 'Female'
		ELSE 'n/a'
	END AS gen
FROM dwh_bronze.erp_cust_az12;

	
SELECT * FROM dwh_silver.erp_cust_az12;


/* '\r' is hidden character we have in many columns of our many tables that's the reason we have to first replace it with
 * nothing to implement our main functions or to fulfill our purpose, include '\r' while importing the data from csv file
 * during -> 'LOAD DATA LOCAL INFILE "c:\xyz\xyz"' where we use LINES TERMINATED BY '\t', '\r'
 */


-- ===========================================================================================
-- cleaning data before adding it into dwh_silver.erp_cust_az12
-- ===========================================================================================

TRUNCATE TABLE dwh_silver.erp_loc_a101;

INSERT INTO dwh_silver.erp_loc_a101
(
	cid,
	cntry)
SELECT
	REPLACE(cid, '-', '') AS cid,
	CASE
		WHEN cntry IS NULL OR REPLACE(TRIM(cntry), '\r', '') = '' THEN 'n/a'
		WHEN REPLACE(TRIM(cntry), '\r', '') = 'DE' THEN 'Germany'
		WHEN REPLACE(TRIM(cntry), '\r', '') IN ('US', 'USA') THEN 'United States'
		ELSE TRIM(cntry)
	END AS cntry
FROM
	dwh_bronze.erp_loc_a101;


SELECT * FROM dwh_silver.erp_loc_a101;



-- ===========================================================================================
-- cleaning data before adding it into dwh_silver.erp_px_cat_g1v2
-- ===========================================================================================

TRUNCATE TABLE dwh_silver.erp_px_cat_g1v2;

INSERT INTO dwh_silver.erp_px_cat_g1v2
(
	id,
	cat,
	subcat,
	maintenance)
SELECT
	id,
	cat,
	subcat,
	maintenance
FROM
	dwh_bronze.erp_px_cat_g1v2

-- No quality issue found in this tabe :)

SELECT * FROM dwh_silver.erp_px_cat_g1v2




/* NOTE
 * ===============
 * 
 * You will find STORE PROCEDURE created for loading all this data on daily basis with new data with name of
 * dwh_silver.load_silver
 * 
 * You will just have to call the procedure by
 * CALL dwh_silver.load_silver ();
 */








