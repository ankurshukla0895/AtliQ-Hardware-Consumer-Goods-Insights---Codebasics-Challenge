**AtliQ Hardware Consumer Goods Insights - Codebasics Challenge**

**Project Overview:** Leveraged MySQL for sophisticated data querying and analytics to address management’s ad hoc requests in the consumer goods sector.

**Skills Gained:** Enhanced SQL proficiency, specializing in:

* Subqueries: For filtering and aggregating data.
* CTEs (Common Table Expressions): For structuring complex queries more clearly.
* JOINs: To combine and analyze data from multiple tables.
* Window Functions: Utilizing RANK() to perform advanced data analysis and ranking.

**Insights Delivered:**

* Product Trends: Identified and analyzed trends in product sales.
* Top Customers: Determined top customers based on sales volume.
* Discount Strategies: Assessed the impact of various discount strategies on sales.
* Sales Metrics: Calculated key sales metrics, including average sales and total quantities sold.

**Impact and Learnings:** Showcased actionable insights and demonstrated the effectiveness of SQL in addressing complex analytical tasks.

**Key Takeaways:** Mastery of MySQL’s advanced features is crucial for in-depth data analysis, highlighting the importance of continual learning and adaptation in the data field.

1. **Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.** <br>
   ```
   SELECT DISTINCT market FROM dim_customer WHERE customer="Atliq Exclusive" AND region="APAC";
   ```
2. **What is the percentage of unique product increase in 2021 vs. 2020?**
```
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
   ```

**3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.**
```
SELECT
	segment,
	COUNT(DISTINCT product_code) AS product_count
FROM
	dim_product
GROUP BY
	segment
ORDER BY
	product_count DESC;
```

4. **Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?** <br>

```
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
   ```
**5. Get the products that have the highest and lowest manufacturing costs.**
```
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
```
**6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.**
```
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
```   
**7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.**
```
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
``` 
**8. In which quarter of 2020, got the maximum total_sold_quantity?**
```
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
```   
**9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?**
```
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
```    
**10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?**
```
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
```
