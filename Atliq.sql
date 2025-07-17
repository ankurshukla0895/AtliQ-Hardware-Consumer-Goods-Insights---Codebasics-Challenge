SELECT * FROM dim_customer;
-- Que 1) Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT
	DISTINCT market
FROM
	dim_customer
WHERE
	customer="Atliq Exclusive" AND region="APAC";
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
SELECT * FROM fact_sales_monthly;
-- Que 2) What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
WITH year_in_20_21 as (
SELECT
	COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) as unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) as unique_products_2021
FROM
	fact_sales_monthly
    )

SELECT 
	unique_products_2020,
    unique_products_2021,
    ROUND(ABS(unique_products_2020-unique_products_2021)/(unique_products_2020+unique_products_2021) * 100,2) as percentage_chg
FROM
	year_in_20_21;
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------   
SELECT * FROM dim_product;    
SELECT * FROM fact_sales_monthly;
-- Que 3) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count.
SELECT
	segment,
	COUNT(DISTINCT product_code) AS product_count
FROM
	dim_product
GROUP BY
	segment
ORDER BY
	product_count DESC;	
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
SELECT * FROM dim_product;
SELECT * FROM fact_sales_monthly;
-- Que 4) Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference
WITH year_in_20_21_ AS (
SELECT
	dp.segment,
	COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN fm.product_code END) as product_count_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN fm.product_code END) as product_count_2021
FROM
	fact_sales_monthly fm 
INNER JOIN
	dim_product dp
ON
	dp.product_code = fm.product_code
GROUP BY
	dp.segment
ORDER BY
	product_count_2021 DESC)
    
SELECT 
	segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM
	year_in_20_21_
ORDER BY
	difference DESC;
 -- ----------x----------x----------x----------x----------x----------x----------x----------x----------
 SELECT * FROM dim_product;
 SELECT * FROM fact_manufacturing_cost;
-- Que 5) Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost
    
-- Get the product with the highest manufacturing cost
WITH HighestCost AS (
    SELECT 
        dp.product_code,
        dp.product,
        fmc.manufacturing_cost
    FROM
        dim_product dp
    JOIN
        fact_manufacturing_cost fmc
    ON
        dp.product_code = fmc.product_code
    ORDER BY fmc.manufacturing_cost DESC
    LIMIT 1
),
-- Get the product with the lowest manufacturing cost
LowestCost AS (
    SELECT 
        dp.product_code,
        dp.product,
        fmc.manufacturing_cost
    FROM
        dim_product dp
    JOIN
        fact_manufacturing_cost fmc
    ON
        dp.product_code = fmc.product_code
    ORDER BY fmc.manufacturing_cost ASC
    LIMIT 1
)

-- Combine the results
SELECT * FROM HighestCost
UNION ALL
SELECT * FROM LowestCost;
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
SELECT * FROM dim_customer;
SELECT * FROM fact_pre_invoice_deductions;
-- Que 6) Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage
SELECT
	dc.customer_code,
    dc.customer,
    ROUND(AVG(fpid.pre_invoice_discount_pct),3) AS average_discount_percentage
FROM
	fact_pre_invoice_deductions fpid
JOIN
	dim_customer dc
ON
	dc.customer_code = fpid.customer_code
WHERE
	fiscal_year = 2021 AND market = 'India'
GROUP BY
	dc.customer_code,
    dc.customer
ORDER BY
	average_discount_percentage DESC
LIMIT 5;
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
SELECT * FROM dim_customer;
SELECT * FROM fact_sales_monthly;
SELECT * FROM fact_gross_price;
-- Que 7) Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount
SELECT 
	MONTHNAME(fsm.date) AS "Month",
    fsm.fiscal_year As "Year",
    ROUND(SUM(fgp.gross_price * fsm.sold_quantity),2) AS "Gross sales Amount"
FROM 
	fact_sales_monthly fsm
JOIN
	fact_gross_price fgp
ON
	fsm.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
JOIN
	dim_customer dc
ON
	dc.customer_code = fsm.customer_code
WHERE
	dc.customer = "Atliq Exclusive"
GROUP BY
	MONTHNAME(fsm.date), fsm.fiscal_year
ORDER BY
	 ROUND(SUM(fgp.gross_price * fsm.sold_quantity),2) DESC;
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
SELECT * FROM dim_customer;
SELECT * FROM fact_sales_monthly;
-- Que 8) In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity
SELECT 
	quarter(date) AS "Quarter",
    SUM(sold_quantity) AS total_sold_quantity
FROM
	fact_sales_monthly
WHERE 
	fiscal_year = 2020
GROUP BY
	quarter(date)
ORDER BY
	total_sold_quantity DESC
LIMIT 1 -- THIS LIMIT IS OPTIONAL IF YOU REMOVE IT YOU WILL ABLE TO SEE total_sold_quantity for all the 4 Quarter
;
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
SELECT * FROM dim_customer;
SELECT * FROM fact_sales_monthly;
SELECT * FROM fact_gross_price;
-- Que 9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage
SELECT
	dc.channel AS "channel",
    ROUND((SUM(fgp.gross_price * fsm.sold_quantity)/1e6),2) AS gross_sales_mln,
    CONCAT(ROUND(100.0 * SUM(fgp.gross_price * fsm.sold_quantity) / 
          (SELECT SUM(fgp.gross_price * fsm.sold_quantity)
           FROM fact_sales_monthly fsm
           JOIN fact_gross_price fgp
           ON fsm.product_code = fgp.product_code 
           AND fsm.fiscal_year = fgp.fiscal_year
           WHERE fsm.fiscal_year = 2021), 2),'%') AS "percentage"
FROM 
    fact_sales_monthly fsm
JOIN
    fact_gross_price fgp
ON
    fsm.product_code = fgp.product_code 
    AND fsm.fiscal_year = fgp.fiscal_year
JOIN
	dim_customer dc
ON
	dc.customer_code = fsm.customer_code	
WHERE 
    fsm.fiscal_year = 2021
GROUP BY 
    dc.channel
ORDER BY 
    gross_sales_mln DESC
LIMIT 1 -- OPTIONAL
;        
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
SELECT * FROM dim_customer;
SELECT * FROM dim_product;
SELECT * FROM fact_sales_monthly;
-- Que 10) Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_code product total_sold_quantity rank_order
-- ----------x----------x----------x----------x----------x----------x----------x----------x----------
WITH RankedProducts AS (
    SELECT 
        dp.division AS "Division",
        dp.product_code AS "Product_Code",
        dp.product AS "Product",
        SUM(fsm.sold_quantity) AS "total_sold_quantity",
        RANK() OVER (PARTITION BY dp.division ORDER BY SUM(fsm.sold_quantity) DESC) AS "rank_order"
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_product dp ON fsm.product_code = dp.product_code
    WHERE 
        fsm.fiscal_year = 2021
    GROUP BY 
        dp.division, dp.product_code, dp.product
)
SELECT 
    Division,
    Product_Code,
    Product,
    total_sold_quantity,
    rank_order
FROM 
    RankedProducts
WHERE 
    rank_order <= 3
ORDER BY 
    Division, rank_order;