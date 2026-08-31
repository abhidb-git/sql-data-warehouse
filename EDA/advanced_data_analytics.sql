-- ==================================================================
-- ADA (Advanced Data Analytics)
-- ==================================================================

-- Chnage Over Time Analysis (Trends)
-- ---------------------------------------------------

-- Analyze Sales performace over time

SELECT
	YEAR(order_date) AS sales_year,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_qunatity
FROM dwh_gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY
	sales_year ASC;

-- In format of year and mont (2010 - January)
	
SELECT
	DATE_FORMAT(order_date, '%Y-%M') AS sales_year,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_qunatity
FROM dwh_gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%M')
ORDER BY
	sales_year ASC;


-- Cumulative Analysis
-- -------------------------------------
	
-- Running total of Sales by Year
	
SELECT
	YEAR(order_date) AS sales_year,
	SUM(sales_amount) AS total_sales,
-- Window Function
	SUM(SUM(sales_amount)) OVER (ORDER BY YEAR(order_date) ASC) AS running_total_byYear
FROM dwh_gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date);

/*
 * WHY 2 times SUM(SUM())?
 * ---------------------------
 * As per sql order of execution the GROUP BY YEA(order_date) will execute earlier then SELECT followed by WINDOW FUNCTION
 * and we only put aggregate function like this when GROUP BY clause is present, the 1st and inner SUM(sales_amount) will
 * execute first and collapse all the row as per grouped years (e.g., Year 2025 = ₹5,000,000). and the outer SUM(SUM())
 * will execute after this which will add or sum all the sales amount which were calculated in previous steps giving us
 * running total.
 * It looks at the already collapsed annual totals and says: "I need to add these annual totals together to make a running timeline."
 */


-- same using SUB-QUERY as that look much cleaner and understandable

SELECT
	*,
-- Window Function
	SUM(total_sales) OVER (ORDER BY sales_year ASC) AS running_total_byYear
FROM 
(
	SELECT
		YEAR(order_date) AS sales_year,
		SUM(sales_amount) AS total_sales
	FROM dwh_gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(order_date)
)t;


-- Calculate total sales per month
-- And running total of sales over time (year)

SELECT
	*,
-- WINDOW FUNCTION
	SUM(total_sales) OVER (PARTITION BY LEFT((sales_month), 4) ORDER BY sales_month ASC) AS running_total_sales
FROM
(
	SELECT
		DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
		SUM(sales_amount) AS total_sales
	FROM dwh_gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY
		DATE_FORMAT(order_date, '%Y-%m')
)t;

/*
	NOTE
-- =================

	DATE_FORMAT() function will change the date into string eg. - 2010-12-10 -> 2010-12 <- it will be as string
	since it is string we can not use YEAR(sales_month) in our window function as YEAR() needs valid DATE type value
	but using DATE_FORMAT we converted it to string that's the reason we are using LEFT(xyz, 4) which will extract 4
	characters as we mentioned in the argumets from left of our string means 2010-12 -> 2010 only after extracting 4 charc
	
	While we are using PARTITION BY it will reset the whole running_total as soon as it encounter new year
*/


-- Let's find moving average price along with running totals by year

SELECT
	*,
-- WINDOW FUNCTION
	SUM(total_sales) OVER (ORDER BY sales_year ASC) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY sales_year ASC) AS moving_avg_price
FROM
(
	SELECT
		YEAR(order_date) AS sales_year,
		SUM(sales_amount) AS total_sales,
		ROUND(AVG(price), 0) AS avg_price
	FROM dwh_gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY
		YEAR(order_date)
)t;


-- Performance Analysis
-- ---------------------------------

-- Analyze the yearly performace of products by comparing each product sales to both
-- it's average sales performance and the previous year's sales

WITH yearly_product_sales AS
(
	SELECT
		YEAR(f.order_date) AS sales_year,
		p.product_name,
		SUM(sales_amount) AS current_sales
	FROM dwh_gold.fact_sales f LEFT JOIN dwh_gold.dim_products p
		 ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY
		YEAR(f.order_date),
		p.product_name;
)

SELECT
	sales_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales, -- No need to add ORDER BY sales_year as it wll give cumulative/running average
	
	current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg, -- will gives us difference between avg_sale and current_sale
	CASE 
		WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
		WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
		ELSE 'Average' -- have to put whole equation here else we can't use alias diff_avg
	END avg_typ,
	
-- Year Over Year Analysis (YoY)
	LAG(current_sales) OVER(PARTITION BY product_name ORDER BY sales_year ASC) AS prv_year_sls,
	current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY sales_year ASC) AS diff_prv_sls,
	CASE 
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY sales_year ASC) < 0 THEN 'Decrease'
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY sales_year ASC) > 0 THEN 'Increase'
		ELSE 'No change' -- have to put whole equation here else we can't use alias diff_prv_sls
	END avg_typ
	
FROM yearly_product_sales
ORDER BY
	product_name, sales_year;
	


/*
 * Reason why we can't use alias names like diff_avg and diff_prv_sls instead of putting the whole equation again,
 * The reason is that diff_avg and diff_prv_sls are column alias created by the SELECT list, and another expression in that same 
 * SELECT list cannot generally reference that alias.
 * 
 * Think of it like this 
 * SQL conceptually evaluates the expressions in the SELECT list from the input table, not sequentially from top to bottom.
 * Those are two independent expressions, That's different from how you might think about variables in programming languages.
 * Means -> they are not like the variable that you have created above in programming language which you can use in the next line
 */


-- Part to Whole Analysis
-- -------------------------------

-- Which categories contribute the most to overall sales

WITH category_sales AS	
	(SELECT
		p.category,
		SUM(f.sales_amount) total_sales
	FROM
		dwh_gold.fact_sales f LEFT JOIN dwh_gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY
		p.category)

SELECT
	category,
	total_sales,
	SUM(total_sales) OVER() AS overall_sales,
	CONCAT(ROUND((total_sales / SUM(total_sales) OVER() * 100), 2), '%') AS prct_of_sales -- can't use overall_sales alias here
FROM
	category_sales;
	

-- Data Segmentation Analysis
-- -----------------------------------

-- Segment products into cost ranges and count how many products fall into each segment

SELECT
    price_range,
    COUNT(*) AS product_count
FROM
(
    SELECT
        product_key,
        product_name,
        product_cost,
        CASE 
            WHEN product_cost < 100 THEN 'Low'
            WHEN product_cost <= 500 THEN 'Average'
            WHEN product_cost <= 1000 THEN 'Above average'
            ELSE 'High'
        END AS price_range
    FROM dwh_gold.dim_products
) t
GROUP BY price_range;	


-- Group customer's into three segments based on their spending behavior:
	/*
	 * - VIP: customers with atleast 12 months of history and spending more than 5000
	 * Regular: customers with atleast 12 months of history but speding 5000 or less.
	 * New: customer with lifespan less than 12 months
And find total numbers of customer by each group
	*/


WITH total_customers_spending AS
(
	SELECT
		c.customer_key,
		SUM(f.sales_amount) AS total_spending,
		MIN(order_date) AS first_order_date,
		MAX(order_date) AS last_order_date
	FROM
		dwh_gold.fact_sales f LEFT JOIN dwh_gold.dim_customers c
		ON f.customer_key = c.customer_key
	GROUP BY
		c.customer_key
)

SELECT
	COUNT(customer_key) AS total_customers,
	customer_range
FROM
	(
		SELECT
			customer_key,
			total_spending,
			TIMESTAMPDIFF(MONTH, first_order_date , last_order_date) AS life_span,
			CASE 
				WHEN TIMESTAMPDIFF(MONTH, first_order_date , last_order_date) >= 12 AND total_spending > 5000 THEN 'VIP'
				WHEN TIMESTAMPDIFF(MONTH, first_order_date , last_order_date) >= 12 AND total_spending <= 5000 THEN 'Regular'
				ELSE 'New'
			END AS customer_range	
		FROM total_customers_spending) t
GROUP BY
	customer_range
ORDER BY
	total_customers DESC;


/*
=======================================================================================================================
Customer Report
========================================================================================================================

Purpose:
	- This report consolidates key customer metrics and behaviors
	
Highlights:
		1. Gathers essential fields such as names, ages and tansaction details.
		2. Segment customers into categories (VIP, Regular, New) and age groups.
		3. Aggregate customer level metrics:
			- total orders
			- total sales
			- total quantity purchased
			- total products
			- lifesapn (in months)
		4. Calculate valuable KPIs:
			- recency (months since last order)
			- average order value (total sales / total number of orders)
			- average monthly spend (total sales / number of months (life_span))
 */

CREATE VIEW dwh_gold.customers_report AS
	WITH base_query AS
	(
		SELECT
		/*--------------------------------------------------------------------------------
		 * Base Query: Retrive core columns from tables
		  --------------------------------------------------------------------------------*/
			c.customer_key,
			c.customer_number,
			CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
			TIMESTAMPDIFF(YEAR, c.birthdate, CURRENT_DATE()) AS age,
			f.product_key,
			f.order_number,
			f.order_date,
			f.sales_amount,
			f.quantity
		FROM
			dwh_gold.fact_sales f LEFT JOIN dwh_gold.dim_customers c
			ON f.customer_key = c.customer_key
		WHERE order_date IS NOT NULL
	),	
	customer_aggregation AS
	(
		SELECT
		/*--------------------------------------------------------------------------------
		 * Customer Aggregation: Summarizes key metrics at customer level
		  --------------------------------------------------------------------------------*/
			customer_key,
			customer_number,
			customer_name,
			age,
			SUM(sales_amount) AS total_spend,
			COUNT(DISTINCT order_number) AS total_orders,
			SUM(quantity) AS total_qunatity,
			COUNT(DISTINCT product_key) AS total_products,
			MAX(order_date) AS last_order_date,
			TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS life_span
		FROM
			base_query
		GROUP BY
			customer_key,
			customer_number,
			customer_name,
			age)	
	SELECT
	/*
	 ---------------------------------------------------------------------------------------------
	 Final Query: Where we are segmenting the data and all customers result into one output
	 ---------------------------------------------------------------------------------------------*/
		customer_key,
			customer_number,
			customer_name,
			age,
			CASE 
				WHEN age BETWEEN 20 AND 29 THEN '20-29'
				WHEN age BETWEEN 30 AND 39 THEN '30-39'
				WHEN age BETWEEN 40 AND 49 THEN '40-49'
				ELSE '50 and above'
			END AS age_group,
			CASE 
				WHEN life_span >= 12 AND total_spend > 5000 THEN 'VIP'
				WHEN life_span >= 12 AND total_spend <= 5000 THEN 'Regular'
				ELSE 'New'
			END AS customer_range,
			last_order_date,
			TIMESTAMPDIFF(MONTH, last_order_date, CURRENT_DATE()) AS recency,
			total_orders,
			total_spend,
			total_qunatity,
			total_products,
			life_span,
			--	Compute Average order value
			CASE 
				WHEN total_orders = 0 THEN '0'
				ELSE ROUND(total_spend / total_orders, 2)
			END AS avg_order_value,
			--	Compute Average monthly spend
			CASE 
				WHEN life_span = 0 THEN total_spend
				ELSE ROUND(total_spend / life_span, 2)
			END AS avg_monthly_spend
	FROM customer_aggregation;

	
-- Build product report

/*
=======================================================================================================================
Product Report
========================================================================================================================

Purpose:
	- This report consolidates key product metrics and behaviors
	
Highlights:
		1. Gathers essential fields such as product name, category, subcategory and cost.
		2. Segment products by revenue to identify High-Performers, Mid-Rangers, or Low-Performers.
		3. Aggregate product level metrics:
			- total orders
			- total sales
			- total quantity sold
			- total customers (unique)
			- lifesapn (in months)
		4. Calculate valuable KPIs:
			- recency (months since last sale)
			- average order revenue (AOR) (total sales / total orders)
			- average monthly revenue (total sales / number of months (life_span))
 */


CREATE VIEW dwh_gold.products_report AS
	WITH core_query AS
	(
		SELECT
		/*--------------------------------------------------------------------------------
			 * Base Query: Retrive core columns from tables
			  --------------------------------------------------------------------------------*/
			f.customer_key,
			f.order_number,
			f.sales_amount,
			f.quantity,
			f.order_date,
			p.product_key,
			p.product_name,
			p.category,
			p.sub_category,
			p.product_cost	
		FROM
			dwh_gold.fact_sales f LEFT JOIN dwh_gold.dim_products p
			ON f.product_key = p.product_key
		WHERE order_number IS NOT NULL
	),
	product_aggregation AS
	(
		SELECT
		/*--------------------------------------------------------------------------------
			 * Product Aggregation: Summarizes key metrics at product level
			  --------------------------------------------------------------------------------*/
			product_key,
			product_name,
			category,
			sub_category,
			product_cost,
			TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS life_span,
			MAX(order_date) AS last_sale_date,
			COUNT(DISTINCT customer_key) AS total_customers,
			COUNT(DISTINCT order_number) AS total_orders,
			SUM(sales_amount) AS total_sales,
			SUM(quantity) AS quantity_sold,
			ROUND(SUM(sales_amount) / NULLIF(SUM(quantity), 0), 2) AS avg_selling_price
		FROM
			core_query
		GROUP BY
			product_key,
			product_name,
			category,
			sub_category,
			product_cost
	)
	
	SELECT 
	/*
		 ---------------------------------------------------------------------------------------------
		 Final Query: Where we are segmenting the data and all products result into one output
		 ---------------------------------------------------------------------------------------------*/
		product_key,
		product_name,
		category,
		sub_category,
		product_cost,
		last_sale_date,
		TIMESTAMPDIFF(MONTH, last_sale_date, CURRENT_DATE()) AS recency,
		CASE 
			WHEN total_sales > 50000 THEN 'High-Performer'
			WHEN total_sales >= 10000 THEN 'Mid-ranger'
			ELSE 'Low-Performer'
		END product_segment,	
		life_span,
		total_orders,
		total_sales,
		quantity_sold,
		total_customers,
		avg_selling_price,
		--	Compute Average order revenue (AOR)
		CASE
			WHEN total_orders = 0 THEN 0
			ELSE total_sales / total_orders
		END AS avg_order_revenue,
		--	Compute Average monthly revenue (AOR)
		CASE 
			WHEN life_span <= 1 THEN total_sales
			ELSE ROUND(total_sales / life_span, 2)
		END AS avg_monthly_revenue	
	FROM
		product_aggregation;
