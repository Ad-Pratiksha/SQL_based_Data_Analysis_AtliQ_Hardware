### Comparative Analysis ###

-- Compare India with other markets in terms of revenue
SELECT 
CASE 
    WHEN dc.market = 'India' THEN 'India'
    ELSE 'Other Markets'
END AS market_group,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue,
COUNT(DISTINCT dc.customer_code) AS customer_count,
ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / COUNT(DISTINCT dc.customer_code), 2) AS revenue_per_customer
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
GROUP BY market_group
ORDER BY total_revenue DESC;

-- Compare product category preferences between India and other markets
SELECT 
dp.category,
CASE 
    WHEN dc.market = 'India' THEN 'India'
    ELSE 'Other Markets'
END AS market_group,
SUM(fsm.sold_quantity) AS quantity_sold,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
GROUP BY dp.category, market_group
ORDER BY dp.category, total_revenue DESC;

-- Compare performance across all regions
SELECT dc.region,
COUNT(DISTINCT dc.customer_code) AS customer_count,
SUM(fsm.sold_quantity) AS total_quantity_sold,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue,
ROUND(AVG(fsm.sold_quantity * fgp.gross_price), 2) AS avg_order_value
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
GROUP BY dc.region
ORDER BY total_revenue DESC;

-- Top markets by region
WITH market_ranking AS (
SELECT 
dc.region,
dc.market,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue,
RANK() OVER (PARTITION BY dc.region ORDER BY SUM(fsm.sold_quantity * fgp.gross_price) DESC) AS market_rank
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
GROUP BY dc.region, dc.market
)
SELECT region, market, total_revenue
FROM market_ranking
WHERE market_rank <= 3
ORDER BY region, market_rank;

-- Channel effectiveness by market
SELECT dc.market, dc.channel,
COUNT(DISTINCT dc.customer_code) AS customer_count,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue,
ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / COUNT(DISTINCT dc.customer_code), 2) AS revenue_per_customer
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
GROUP BY dc.market, dc.channel
ORDER BY dc.market, total_revenue DESC;

-- Platform effectiveness by market
SELECT dc.market, dc.platform,
COUNT(DISTINCT dc.customer_code) AS customer_count,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue,
ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / COUNT(DISTINCT dc.customer_code), 2) AS revenue_per_customer
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
GROUP BY dc.market, dc.platform
ORDER BY dc.market, total_revenue DESC;