### Advanced Analytics ###

-- Calculate customer lifetime value for India
WITH CustomerStats AS (
SELECT 
dc.customer_code,
dc.customer,
MIN(fsm.date) AS first_purchase_date,
MAX(fsm.date) AS last_purchase_date,
DATEDIFF(MAX(fsm.date), MIN(fsm.date)) AS customer_lifetime_days,
COUNT(DISTINCT fsm.date) AS purchase_frequency,
SUM(fsm.sold_quantity * fgp.gross_price) AS total_spent,
AVG(fsm.sold_quantity * fgp.gross_price) AS avg_order_value
FROM dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.market = 'India'
GROUP BY dc.customer_code, dc.customer
)
SELECT 
customer_code,
customer,
first_purchase_date,
last_purchase_date,
customer_lifetime_days,
purchase_frequency,
total_spent,
avg_order_value,
CASE 
    WHEN customer_lifetime_days > 0 THEN (total_spent / customer_lifetime_days) * 365 * 3 
    ELSE total_spent * 3 
END AS projected_3year_clv
FROM CustomerStats
ORDER BY total_spent DESC
LIMIT 20;

-- Customer churn rate (a.k.a. Attrition Rate) in India
WITH RecentPurchase AS (
SELECT MAX(date) AS most_recent_purchase_date
FROM fact_sales_monthly
),
CutoffDate AS (
SELECT DATE_SUB(most_recent_purchase_date, INTERVAL 1 YEAR) AS cutoff_date
FROM RecentPurchase
),
ChurnedCustomers AS (
SELECT
dc.customer_code,
dc.customer,
MAX(fsm.date) AS last_purchase_date
FROM
dim_customer dc
LEFT JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
WHERE dc.market = 'India'
GROUP BY
dc.customer_code, dc.customer
HAVING
MAX(fsm.date) IS NULL OR MAX(fsm.date) < (SELECT cutoff_date FROM CutoffDate)
)
-- Calculate the churn rate
SELECT
(SELECT COUNT(*) FROM ChurnedCustomers) / (SELECT COUNT(*) FROM dim_customer WHERE market = 'India') * 100 AS churn_rate_india;

-- Identify at-risk customers in India (no purchase in last 6 months)
WITH recent_purchase AS (
SELECT
dc.customer_code
FROM
dim_customer dc
JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
WHERE
dc.market = 'India' AND
fsm.date >= CURDATE() - INTERVAL 6 MONTH
)
SELECT
dc.customer_code, dc.customer,
MAX(fsm.date) AS last_purchase_date
FROM dim_customer dc
LEFT JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
WHERE dc.market = 'India' AND
dc.customer_code NOT IN (SELECT customer_code FROM recent_purchase)
GROUP BY dc.customer_code, dc.customer
ORDER BY last_purchase_date DESC
LIMIT 20;

-- Product categories frequently purchased together in India
SELECT dp1.category AS category1, dp2.category AS category2, COUNT(*) AS frequency
FROM fact_sales_monthly fsm1
JOIN dim_product dp1 ON fsm1.product_code = dp1.product_code
JOIN fact_sales_monthly fsm2 ON fsm1.customer_code = fsm2.customer_code AND fsm1.date = fsm2.date
JOIN dim_product dp2 ON fsm2.product_code = dp2.product_code
JOIN dim_customer dc ON fsm1.customer_code = dc.customer_code
WHERE fsm1.product_code < fsm2.product_code AND dp1.category <> dp2.category AND dc.market = 'India'
GROUP BY dp1.category, dp2.category
ORDER BY frequency DESC
LIMIT 15;

-- Product divisions frequently purchased together in India
SELECT dp1.division AS division1, dp2.division AS division2, COUNT(*) AS frequency
FROM fact_sales_monthly fsm1
JOIN dim_product dp1 ON fsm1.product_code = dp1.product_code
JOIN fact_sales_monthly fsm2 ON fsm1.customer_code = fsm2.customer_code AND fsm1.date = fsm2.date
JOIN dim_product dp2 ON fsm2.product_code = dp2.product_code
JOIN dim_customer dc ON fsm1.customer_code = dc.customer_code
WHERE fsm1.product_code < fsm2.product_code AND dp1.division <> dp2.division AND dc.market = 'India'
GROUP BY dp1.division, dp2.division
ORDER BY frequency DESC
LIMIT 15;

-- Customer segmentation based on purchasing behavior in India
WITH CustomerStats AS (
    SELECT
        dc.customer_code,
        dc.customer,
        COUNT(DISTINCT fsm.date) AS purchase_frequency,
        SUM(fsm.sold_quantity * fgp.gross_price) AS total_spent
    FROM dim_customer dc
    JOIN fact_sales_monthly fsm ON dc.customer_code = fsm.customer_code
    JOIN dim_product dp ON fsm.product_code = dp.product_code
    JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code
        AND fsm.fiscal_year = fgp.fiscal_year
    WHERE dc.market = 'India'
    GROUP BY dc.customer_code, dc.customer
),
Percentiles AS (
    -- compute the 80th and 50th percentile cutoffs using CUME_DIST()
    SELECT
        MIN(CASE WHEN cd_spent >= 0.8 THEN total_spent END) AS spent_80,
        MIN(CASE WHEN cd_spent >= 0.5 THEN total_spent END) AS spent_50,
        MIN(CASE WHEN cd_freq >= 0.8 THEN purchase_frequency END) AS freq_80,
        MIN(CASE WHEN cd_freq >= 0.5 THEN purchase_frequency END) AS freq_50
    FROM (
        SELECT
            total_spent,
            purchase_frequency,
            CUME_DIST() OVER (ORDER BY total_spent) AS cd_spent,
            CUME_DIST() OVER (ORDER BY purchase_frequency) AS cd_freq
        FROM CustomerStats
    ) x
),
CustomerSegments AS (
    SELECT
        cs.customer_code,
        cs.customer,
        cs.purchase_frequency,
        cs.total_spent,
        CASE
            WHEN cs.total_spent >= p.spent_80 AND cs.purchase_frequency >= p.freq_80 THEN 'High Value'
            WHEN cs.total_spent >= p.spent_50 AND cs.purchase_frequency >= p.freq_50 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM CustomerStats cs
    CROSS JOIN Percentiles p
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(purchase_frequency), 2) AS avg_purchase_frequency,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(SUM(total_spent) / (SELECT SUM(total_spent) FROM CustomerStats) * 100, 2) AS revenue_percentage
FROM CustomerSegments
GROUP BY customer_segment
ORDER BY avg_total_spent DESC;