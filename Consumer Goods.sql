-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT distinct(market)
from gdb023.dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

-- What is the percentage of unique product increase in 2021 vs. 2020? 
WITH product_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
),
product_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021
)
SELECT unique_products_2020, unique_products_2021,
       ROUND(((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100, 2) AS percentage_chg
FROM product_2020, product_2021;


-- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 


SELECT segment,count(distinct product_code)
		as product_count
FROM dim_product
group by segment
order by product_count desc;

-- Which segment had the most increase in unique products in 2021 vs 2020?
WITH product_2020 AS (
    SELECT COUNT(DISTINCT s.product_code) AS unique_products_2020, p.segment 
    FROM fact_sales_monthly s
    join dim_product p
    on s.product_code = p.product_code
    WHERE fiscal_year = 2020
    group by p.segment
    ),
product_2021 AS (
    SELECT COUNT(DISTINCT s.product_code) AS unique_products_2021,p.segment 
    FROM fact_sales_monthly s
    join dim_product p
    on s.product_code = p.product_code
    WHERE fiscal_year = 2021
    group by p.segment
)
SELECT p2020.segment,unique_products_2020, unique_products_2021,
       ROUND(unique_products_2021 - unique_products_2020) AS Difference
FROM product_2020 p2020
JOIN product_2021 p2021
ON p2020.segment = p2021.segment
order by Difference desc; 

-- Get the products that have the highest and lowest manufacturing costs.

SELECT 
    p.product,
    m.manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p
    ON p.product_code = m.product_code
WHERE m.manufacturing_cost = (
    SELECT MAX(manufacturing_cost) 
    FROM fact_manufacturing_cost
)
OR m.manufacturing_cost = (
    SELECT MIN(manufacturing_cost)
    FROM fact_manufacturing_cost
);


-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

select pre.customer_code,
	round(avg(pre_invoice_discount_pct),2) as average_discount_percentage,
    c.customer
from fact_pre_invoice_deductions pre
join dim_customer c
on pre.customer_code = c.customer_code
where fiscal_year = 2021 and market = "India" 
group by pre.customer_code, c.customer
order by average_discount_percentage desc
limit 5 ;

-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
SELECT 
    MONTH(s.date) AS Month,
    year(s.date) AS Year,
    ROUND(SUM(g.gross_price * s.sold_quantity)/1000000, 2) AS Gross_sales_Amount  
FROM fact_sales_monthly s
JOIN fact_gross_price g
    ON s.product_code = g.product_code 
    AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
    ON s.customer_code = c.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY date
ORDER BY date,Gross_sales_Amount DESC;

-- In which quarter of 2020, got the maximum total_sold_quantity?

SELECT 
CASE 
	WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
	WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
	WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
	WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
END AS Quarters,sum(sold_quantity) as total_sold_quantity
FROM gdb023.fact_sales_monthly
where fiscal_year = 2020
group by Quarters;


-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

SELECT 
    c.channel,
    ROUND(SUM(g.gross_price * s.sold_quantity) / 1000000, 2) AS gross_sales_mln,
    ROUND((SUM(g.gross_price * s.sold_quantity) / 
          (SELECT SUM(gp.gross_price * sm.sold_quantity)
           FROM fact_sales_monthly sm
           JOIN fact_gross_price gp ON sm.product_code = gp.product_code 
           AND sm.fiscal_year = gp.fiscal_year
           WHERE sm.fiscal_year = 2021)) * 100, 2) AS percentage_contribution
FROM fact_sales_monthly s
JOIN fact_gross_price g
    ON s.product_code = g.product_code 
    AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
    ON s.customer_code = c.customer_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
ORDER BY gross_sales_mln DESC;

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?


WITH cte AS (
    SELECT 
        p.division,
        p.product,
        s.product_code,
        SUM(s.sold_quantity) AS total_sold_quantity,  
        ROW_NUMBER() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
    FROM fact_sales_monthly s
    JOIN dim_product p
    ON s.product_code = p.product_code 
    WHERE s.fiscal_year = 2021
    GROUP BY p.division, p.product, s.product_code 
)
SELECT 
    division,
    product,
    product_code,
    total_sold_quantity,  
    rank_order
FROM cte
WHERE rank_order <= 3;
        

