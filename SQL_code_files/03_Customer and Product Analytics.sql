### Customer and Product Analytics ###

-- Include pre-invoice deductions in Croma detailed report
SELECT
s.date,
s.product_code,
p.product,
p.variant,
s.sold_quantity,
g.gross_price as gross_price_per_item,
ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code=p.product_code
JOIN fact_gross_price g
ON g.fiscal_year=get_fiscal_year(s.date)
AND g.product_code=s.product_code
JOIN fact_pre_invoice_deductions as pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=get_fiscal_year(s.date)
WHERE
s.customer_code=90002002 AND
get_fiscal_year(s.date)=2021
LIMIT 1000000;

-- Same report but for all customers in 2021
SELECT
s.date,
s.product_code,
p.product,
p.variant,
s.sold_quantity,
g.gross_price as gross_price_per_item,
ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code=p.product_code
JOIN fact_gross_price g
ON g.fiscal_year=get_fiscal_year(s.date)
AND g.product_code=s.product_code
JOIN fact_pre_invoice_deductions as pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=get_fiscal_year(s.date)
WHERE
get_fiscal_year(s.date)=2021
LIMIT 1000000;

-- Creating dim_date and joining with this table to avoid using the function 'get_fiscal_year()' - query optimization
SELECT
s.date,
dt.fiscal_year,
s.customer_code,
s.product_code,
p.product, p.variant,
s.sold_quantity,
g.gross_price as gross_price_per_item,
ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_date dt
ON dt.calendar_date = s.date
JOIN dim_product p
ON s.product_code=p.product_code
JOIN fact_gross_price g
ON g.fiscal_year=dt.fiscal_year
AND g.product_code=s.product_code
JOIN fact_pre_invoice_deductions pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=dt.fiscal_year
WHERE
dt.fiscal_year=2021
LIMIT 1500000;

-- Added the fiscal year in the fact_sales_monthly table itself
SELECT
s.date,
s.fiscal_year,
s.customer_code,
s.product_code,
p.product, p.variant,
s.sold_quantity,
g.gross_price as gross_price_per_item,
ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code=p.product_code
JOIN fact_gross_price g
ON g.fiscal_year=s.fiscal_year
AND g.product_code=s.product_code
JOIN fact_pre_invoice_deductions pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=s.fiscal_year
WHERE
s.fiscal_year=2021
LIMIT 1500000;

-- Get the net_invoice_sales amount using the CTE's
WITH cte1 AS (
SELECT
s.date,
s.customer_code,
s.product_code,
p.product, p.variant,
s.sold_quantity,
g.gross_price as gross_price_per_item,
ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code=p.product_code
JOIN fact_gross_price g
ON g.fiscal_year=s.fiscal_year
AND g.product_code=s.product_code
JOIN fact_pre_invoice_deductions as pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=s.fiscal_year
WHERE
s.fiscal_year=2021)
SELECT
*,
(1-pre_invoice_discount_pct)*gross_price_total as net_invoice_sales
FROM cte1
LIMIT 1500000;

-- Creating the view `sales_preinv_discount`
#	CREATE VIEW `sales_preinv_discount` AS
#	SELECT
#	s.date,
#	s.fiscal_year,
#	s.customer_code,
#	c.market,
#	s.product_code,
#	p.product,
#	p.variant,
#	s.sold_quantity,
#	g.gross_price as gross_price_per_item,
#	ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
#	pre.pre_invoice_discount_pct
#	FROM fact_sales_monthly s
#	JOIN dim_customer c
#	ON s.customer_code = c.customer_code
#	JOIN dim_product p
#	ON s.product_code=p.product_code
#	JOIN fact_gross_price g
#	ON g.fiscal_year=s.fiscal_year
#	AND g.product_code=s.product_code
#	JOIN fact_pre_invoice_deductions as pre
#	ON pre.customer_code = s.customer_code AND
#	pre.fiscal_year=s.fiscal_year;

-- Now generate net_invoice_sales using the above created view
SELECT
*,
(gross_price_total-pre_invoice_discount_pct*gross_price_total) as net_invoice_sales
FROM sales_preinv_discount;

-- Create a view for post invoice deductions: `sales_postinv_discount`
#	CREATE VIEW `sales_postinv_discount` AS
#	SELECT
#	s.date, s.fiscal_year,
#	s.customer_code, s.market,
#	s.product_code, s.product, s.variant,
#	s.sold_quantity, s.gross_price_total,
#	s.pre_invoice_discount_pct,
#	(1-s.pre_invoice_discount_pct)*s.gross_price_total as net_invoice_sales,
#	(po.discounts_pct+po.other_deductions_pct) as post_invoice_discount_pct
#	FROM sales_preinv_discount s
#	JOIN fact_post_invoice_deductions po
#	ON po.customer_code = s.customer_code AND
#	po.product_code = s.product_code AND
#	po.date = s.date;

-- Create a report for net sales
SELECT
*,
net_invoice_sales*(1-post_invoice_discount_pct) as net_sales
FROM sales_postinv_discount;

-- Finally creating the view `net_sales`
#	CREATE VIEW `net_sales` AS
#	SELECT
#	*,
#	net_invoice_sales*(1-post_invoice_discount_pct) as net_sales
#	FROM sales_postinv_discount;

-- Get top 5 market by net sales in fiscal year 2021
SELECT
market,
round(sum(net_sales)/1000000,2) as net_sales_mln
FROM net_sales
where fiscal_year=2021
group by market
order by net_sales_mln desc
limit 5;

-- Stored proc to get top n markets by net sales for a given year
#	CREATE PROCEDURE `get_top_n_markets_by_net_sales`(
#	IN in_fiscal_year INT,
#	IN in_top_n INT
#	) DETERMINISTIC
#	BEGIN
#	SELECT
#	market,
#	round(sum(net_sales)/1000000,2) as net_sales_mln
#	FROM net_sales
#	where fiscal_year=in_fiscal_year
#	group by market
#	order by net_sales_mln desc
#	limit in_top_n;
#	END;

-- stored procedure that takes market, fiscal_year and top n as input and returns top n customers by net sales
#	CREATE PROCEDURE `get_top_n_customers_by_net_sales`(
#	IN in_market VARCHAR(45),
#	IN in_fiscal_year INT,
#	IN in_top_n INT
#	) DETERMINISTIC
#	BEGIN
#	select
#	customer,
#	round(sum(net_sales)/1000000,2) as net_sales_mln
#	from net_sales s
#	join dim_customer c
#	on s.customer_code=c.customer_code
#	where
#	s.fiscal_year=in_fiscal_year
#	and s.market=in_market
#	group by customer
#	order by net_sales_mln desc
#	limit in_top_n;
#	END;

-- Find customer wise net sales percentage contribution
with cte1 as (
select
customer,
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code=c.customer_code
where s.fiscal_year=2021
group by customer)
select
*,
net_sales_mln*100/sum(net_sales_mln) over() as pct_net_sales
from cte1
order by net_sales_mln desc;

-- Find customer wise net sales distribution per region for FY 2021
with cte1 as (
select
c.customer,
c.region,
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales n
join dim_customer c
on n.customer_code=c.customer_code
where fiscal_year=2021
group by c.customer, c.region)
select
*,
net_sales_mln*100/sum(net_sales_mln) over (partition by region) as pct_share_region
from cte1
order by region, pct_share_region desc;

-- Find out top 3 products from each division by total quantity sold in a given year
SET SESSION sql_mode = '';  -- preventing full group by for the current connection
with cte1 as
(select
p.division,
p.product,
sum(sold_quantity) as total_qty
from fact_sales_monthly s
join dim_product p
on p.product_code=s.product_code
where fiscal_year=2021
group by p.product),
cte2 as
(select
*,
dense_rank() over (partition by division order by total_qty desc) as drnk
from cte1)
select * from cte2 where drnk<=3;

-- Creating stored procedure for the above query
#	CREATE PROCEDURE `get_top_n_products_per_division_by_qty_sold`(
#	IN in_fiscal_year INT,
#	IN in_top_n INT
#	)  DETERMINISTIC
#	BEGIN
#	with cte1 as (
#	select
#	p.division,
#	p.product,
#	sum(sold_quantity) as total_qty
#	from fact_sales_monthly s
#	join dim_product p
#	on p.product_code=s.product_code
#	where fiscal_year=in_fiscal_year
#	group by p.division, p.product),
#	cte2 as (
#	select
#	*,
#	dense_rank() over (partition by division order by total_qty desc) as drnk
#	from cte1)
#	select * from cte2 where drnk <= in_top_n;
#	END;

-- Create a view for gross sales
#	CREATE VIEW `gross_sales` AS
#	SELECT
#	s.date,
#	s.fiscal_year,
#	s.customer_code,
#	c.customer,
#	c.market,
#	s.product_code,
#	p.product, p.variant,
#	s.sold_quantity,
#	g.gross_price as gross_price_per_item,
#	round(s.sold_quantity*g.gross_price,2) as gross_price_total
#	from fact_sales_monthly s
#	join dim_product p
#	on s.product_code=p.product_code
#	join dim_customer c
#	on s.customer_code=c.customer_code
#	join fact_gross_price g
#	on g.fiscal_year=s.fiscal_year
#	and g.product_code=s.product_code;

-- Write a stored procedure to get the top n products by net sales for a given year
#	CREATE PROCEDURE get_top_n_products_by_net_sales(
#	IN in_fiscal_year int,
#	IN in_top_n int
#	)
#	BEGIN
#	select
#	p.product,
#	round(sum(net_sales)/1000000,2) as net_sales_mln
#	from net_sales s
#	join dim_product p ON s.product_code=p.product_code
#	where fiscal_year=in_fiscal_year
#	group by p.product
#	order by net_sales_mln desc
#	limit in_top_n;
#	END;

-- Write a query to get region wise % net sales breakdown by customers
with cte1 as(
SELECT
c.customer,
c.region,
round(sum(s.net_sales)/1000000,2) as net_sales_mln
FROM net_sales s
JOIN dim_customer c ON s.customer_code=c.customer_code
WHERE fiscal_year=2021
GROUP BY c.customer, c.region)
select
*,
(net_sales_mln*100)/sum(net_sales_mln) over(partition by region) as pct
from cte1
order by region, net_sales_mln DESC;

-- Retrieve the top 2 markets in every region by their gross sales amount in FY=2021
with cte1 as (
select
c.market,
c.region,
round(sum(gross_price_total)/1000000,2) as gross_sales_mln
from gross_sales s
join dim_customer c
on c.customer_code=s.customer_code
where fiscal_year=2021
group by market, region
order by gross_sales_mln desc
),
cte2 as (
select *,
dense_rank() over(partition by region order by gross_sales_mln desc) as drnk
from cte1
)
select * from cte2 where drnk<=2;