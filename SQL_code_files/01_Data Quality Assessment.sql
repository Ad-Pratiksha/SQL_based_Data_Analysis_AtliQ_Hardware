### Data Cleaning and Quality Assessment ###

-- Set default schema
USE gdb0041;

-- Check for NULL values in dim_customer
SELECT *
FROM dim_customer
WHERE customer_code IS NULL
OR customer IS NULL
OR platform IS NULL
OR channel IS NULL
OR market IS NULL
OR sub_zone IS NULL
OR region IS NULL;

-- Handling NULL Values in dim_customer
SELECT customer_code,
COALESCE(customer, 'N/A') AS customer,
COALESCE(platform, 'N/A') AS platform,
COALESCE(channel, 'N/A') AS channel,
COALESCE(market, 'N/A') AS market,
COALESCE(sub_zone, 'N/A') AS sub_zone,
COALESCE(region, 'N/A') AS region
FROM dim_customer;

-- Check for duplicates in dim_customer
SELECT customer_code, customer, COUNT(*)
FROM dim_customer
GROUP BY customer_code, customer
HAVING COUNT(*) > 1;

-- Check for NULL values in dim_product
SELECT *
FROM dim_product
WHERE product_code IS NULL
OR division IS NULL
OR segment IS NULL
OR category IS NULL
OR product IS NULL
OR variant IS NULL;

-- Handling NULL Values in dim_product
SELECT product_code,
COALESCE(division, 'N/A') AS division,
COALESCE(segment, 'N/A') AS segment,
COALESCE(category, 'N/A') AS category,
COALESCE(product, 'N/A') AS product,
COALESCE(variant, 'N/A') AS variant
FROM dim_product;

-- Check for duplicates in dim_product
SELECT product_code, product, COUNT(*)
FROM dim_product
GROUP BY product_code, product
HAVING COUNT(*) > 1;

-- Check for NULL values in fact_sales_monthly
SELECT *
FROM fact_sales_monthly
WHERE date IS NULL
OR fiscal_year IS NULL
OR product_code IS NULL
OR customer_code IS NULL
OR sold_quantity IS NULL;

-- Check for duplicates in fact_sales_monthly
SELECT date, fiscal_year, product_code, customer_code, COUNT(*)
FROM fact_sales_monthly
GROUP BY date, fiscal_year, product_code, customer_code
HAVING COUNT(*) > 1;