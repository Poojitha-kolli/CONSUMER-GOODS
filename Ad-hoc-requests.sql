
-- SQL QUERY 1

SELECT distinct market FROM gdb023.dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC'

-- SQL QUERY 2

WITH CTE1 AS ( 
SELECT COUNT(distinct product_code) AS UNIQUE_PRODUCTS_2020 FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2020),

CTE2 AS (
SELECT COUNT(distinct product_code) AS UNIQUE_PRODUCTS_2021 FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2021)

select *, 
ROUND((CTE2.UNIQUE_PRODUCTS_2021 - CTE1.UNIQUE_PRODUCTS_2020) * 100/CTE1.UNIQUE_PRODUCTS_2020, 2) AS PERCENTAGE_CHANGE from CTE1, CTE2


-- SQL QUERY 3

SELECT segment, COUNT(distinct product_code) as product_count FROM gdb023.dim_product
group by segment
order by product_count desc


-- SQL QUERY 4

WITH CTE1 AS (SELECT segment,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN fs.product_code END) AS UNIQUE_PRODUCTS_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN fs.product_code END) AS UNIQUE_PRODUCTS_2021
FROM gdb023.fact_sales_monthly as fs
join gdb023.dim_product as dp on fs.product_code = dp.product_code
group by segment)

SELECT *, 
(UNIQUE_PRODUCTS_2021 - UNIQUE_PRODUCTS_2020) AS DIFFERENCE
FROM CTE1
order by DIFFERENCE DESC


-- SQL QUERY 5

(SELECT fm.product_code, dp.product, max(manufacturing_cost) as Manufacturing_Cost FROM gdb023.fact_manufacturing_cost fm
join gdb023.dim_product dp on fm.product_code = dp.product_code
group by fm.product_code, dp.product
order by  Manufacturing_Cost desc 
limit 1)

union all 

(SELECT fm.product_code, dp.product, min(manufacturing_cost) as Manufacturing_Cost FROM gdb023.fact_manufacturing_cost fm
join gdb023.dim_product dp on fm.product_code = dp.product_code
group by fm.product_code, dp.product
order by Manufacturing_Cost
limit 1)

-- SQL QUERY 6

SELECT fp.customer_code, customer, round(avg(pre_invoice_discount_pct),4) as avg_dis_percent FROM gdb023.fact_pre_invoice_deductions fp
join gdb023.dim_customer dc on fp.customer_code = dc.customer_code
where fiscal_year = 2021 and market = 'India'
group by fp.customer_code, customer
order by avg_dis_percent desc
limit 5

-- SQL QUERY 7

SELECT monthname(date) as month, year(date) as year, 
round(sum(gross_price * sold_quantity),4) as gross_sales_Amount from gdb023.fact_sales_monthly fs
join gdb023.fact_gross_price fg on fs.product_code = fg.product_code
join gdb023.dim_customer dc on fs.customer_code = dc.customer_code
where customer = 'Atliq Exclusive'
group by year,month
order by year

-- SQL QUERY 8 

SELECT 
CASE 
WHEN MONTH(DATE) BETWEEN 9 AND 11 THEN 'Q1'
WHEN MONTH(DATE) in (12,1,2) THEN 'Q2'
WHEN MONTH(DATE) BETWEEN 3 AND 5 THEN 'Q3'
WHEN MONTH(DATE) BETWEEN 6 AND 8 THEN 'Q4'
END AS QUARTER,
CONCAT(ROUND(SUM(sold_quantity)/1000000,2),'M') as total_sold_quantity from gdb023.fact_sales_monthly
where fiscal_year = 2020
group by quarter
order by total_sold_quantity desc


-- SQL QUERY 9

with CTE1 AS 
(SELECT channel, 
round(sum(gross_price * sold_quantity)/1000000,2) as gross_sales_mln  FROM gdb023.dim_customer dc 
join gdb023.fact_sales_monthly fs on dc.customer_code = fs.customer_code
join gdb023.fact_gross_price fg on fs.product_code = fg.product_code
where fs.fiscal_year  = 2021
group by channel),

CTE2 AS (SELECT SUM(CTE1.gross_sales_mln) as total_sales from CTE1)

SELECT CTE1.channel,
concat(CTE1.gross_sales_mln,'M') as gross_sales_mln, 
round((CTE1.gross_sales_mln * 100) / CTE2.total_sales, 2) AS percentage from cte1,CTE2
order by CTE1.gross_sales_mln desc


-- SQL QUERY 10

WITH CTE1 AS (
SELECT dp.division,
fs.product_code, dp.product, 
SUM(fs.sold_quantity) as total_quantity,
rank() over (partition by dp.division order by sum(fs.sold_quantity) desc) as rank_order
from gdb023.dim_product dp
join gdb023.fact_sales_monthly fs 
on dp.product_code = fs.product_code
where fiscal_year = 2021
group by dp.division, fs.product_code, product)

SELECT * FROM CTE1
where rank_order <= 3
order by division, rank_order



