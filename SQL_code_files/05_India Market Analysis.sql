### India Market Analysis (Focus Area) ###

-- Top-selling products in India
SELECT
dp.product AS Product_Name,
dp.category AS Category,
dp.segment AS Segment,
SUM(fsm.sold_quantity) AS Quantity_Sold
FROM fact_sales_monthly fsm
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE dc.market = 'India'
GROUP BY dp.product, dp.category, dp.segment
ORDER BY Quantity_Sold DESC
LIMIT 10;

-- Top product categories in India
SELECT
dp.category AS Category,
dp.division AS Division,
SUM(fsm.sold_quantity) AS Quantity_Sold
FROM fact_sales_monthly fsm
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE dc.market = 'India'
GROUP BY dp.category, dp.division
ORDER BY Quantity_Sold DESC
LIMIT 10;

-- Customer breakdown in India by platform and channel
SELECT
platform,
channel,
COUNT(*) AS customer_count
FROM dim_customer
WHERE market = 'India'
GROUP BY platform, channel
ORDER BY customer_count DESC;

-- Customer breakdown in India by sub-zone
SELECT
sub_zone,
COUNT(*) AS customer_count
FROM dim_customer
WHERE market = 'India'
GROUP BY sub_zone
ORDER BY customer_count DESC;

-- Total Revenue by different customers in Sub-zone of India
SELECT dc.sub_zone,
dc.customer,
SUM(fsm.sold_quantity * fgp.gross_price) AS Total_Revenue
FROM fact_sales_monthly fsm
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.market = 'India'
GROUP BY dc.sub_zone, dc.customer_code
ORDER BY Total_Revenue DESC;

-- Number of Sales by Sub-zone in India
SELECT dc.sub_zone,
SUM(fsm.sold_quantity) AS total_sales
FROM fact_sales_monthly fsm
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE dc.market = 'India'
GROUP BY dc.sub_zone
ORDER BY total_sales DESC;

-- Top 5 customers by total revenue in India
SELECT
dc.customer_code,
dc.customer,
SUM(fsm.sold_quantity * fgp.gross_price) as Total_Revenue
FROM
dim_customer dc
INNER JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.market = 'India'
GROUP BY
dc.customer_code, dc.customer
ORDER BY
Total_Revenue DESC
LIMIT 5;

-- Frequency of Purchases in India
SELECT dc.customer_code, dc.customer,
COUNT(DISTINCT fsm.date) AS Purchase_Frequency
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
WHERE dc.market = 'India'
GROUP BY dc.customer_code, dc.customer
ORDER BY Purchase_Frequency DESC
LIMIT 15;

-- Calculate the average order value for each customer in India
SELECT dc.customer_code, dc.customer,
Round(AVG(fsm.sold_quantity * fgp.gross_price), 2) AS average_order_value
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.market = 'India'
GROUP BY dc.customer_code, dc.customer
ORDER BY average_order_value DESC
LIMIT 15;

-- Product category which was purchased on frequent basis in India
SELECT dp.category AS category, COUNT(*) AS purchase_frequency
FROM dim_product dp
JOIN fact_sales_monthly fsm ON dp.product_code = fsm.product_code
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE dc.market = 'India'
GROUP BY dp.category
ORDER BY purchase_frequency DESC
LIMIT 15;

-- Calculate the percentage of total sales contributed by each product category in India
WITH CategorySales AS (
SELECT dp.category AS category,
dp.division AS division,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_sales
FROM fact_sales_monthly fsm
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.market = 'India'
GROUP BY dp.category, dp.division
),
TotalSales AS (
SELECT SUM(total_sales) AS total_sales_amount
FROM CategorySales)
SELECT cs.category, cs.division, cs.total_sales,
(cs.total_sales / ts.total_sales_amount * 100) AS sales_percentage
FROM CategorySales cs
CROSS JOIN TotalSales ts
ORDER BY cs.total_sales DESC
LIMIT 15;

-- Analyze sales performance across different sub-zones in India
SELECT dc.sub_zone,
COUNT(DISTINCT dc.customer_code) AS customer_count,
SUM(fsm.sold_quantity) AS total_quantity_sold,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue,
ROUND(AVG(fsm.sold_quantity * fgp.gross_price), 2) AS avg_order_value
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.market = 'India'
GROUP BY dc.sub_zone
ORDER BY total_revenue DESC;

-- Top product categories by sub-zone in India
SELECT dc.sub_zone, dp.category,
SUM(fsm.sold_quantity) AS quantity_sold,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_revenue
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.market = 'India'
GROUP BY dc.sub_zone, dp.category
ORDER BY dc.sub_zone, total_revenue DESC;