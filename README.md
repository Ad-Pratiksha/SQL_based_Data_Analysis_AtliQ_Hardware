# 🗄️ SQL Data Analysis Project: AtliQ Hardware Business Intelligence
## 📌 Project Overview
This project demonstrates how SQL-driven analysis can generate actionable insights for AtliQ Hardware company. Using sales, customer, product, and supply chain data (2017–2022), I performed end-to-end business analysis to address challenges in:<br>
•	Revenue Optimization: Identifying underperforming markets/products and evaluating discount strategies.<br>
•	Market Expansion: Assessing India’s market potential as a growth driver.<br>
•	Forecast Accuracy & Supply Chain Efficiency: Reducing costs and stockouts through better demand forecasting.<br>
•	Customer & Product Insights: Segmenting customers, analyzing product mix, and identifying retention opportunities.<br>

👉 The goal was to convert raw transactional data into strategic recommendations that drive growth, efficiency, and profitability.<br>

## 🛠 Tech Stack<br>
•	SQL (MySQL) → Core data querying, cleaning, and transformation<br>
•	MySQL Workbench → Query development and testing<br>
•	Python (Pandas, Matplotlib, Seaborn) → Exploratory analysis and visualizations<br>
•	PowerPoint → Presenting results and dashboards<br>
•	Git → Version control for queries and documentation<br>

## 📂 Dataset<br>
•	Source: AtliQ Hardware Database (sample version shared here due to copyright restrictions)<br>
•	Schema: Star schema<br>
•	Dimension Tables: dim_customer, dim_product, dim_date<br>
•	Fact Tables: fact_sales_monthly, fact_gross_price, fact_manufacturing_cost, fact_forecast_monthly, fact_freight_cost, fact_post_invoice_deductions, fact_pre_invoice_deductions<br>
•	Period: FY2017 – FY2022<br>
•	Key Metrics: sold_quantity, gross_price, net_sales, forecast_accuracy<br>

## 📊 Key Analyses

### 🔹 Financial Analysis<br>
•	APAC leads in total sales; India contributes significantly within APAC.<br>
•	Discounting impacts profitability differently across regions.<br>

Example Query – Top 10 Markets by Net Sales<br>

SELECT c.market,<br>
       ROUND(SUM(s.sold_quantity * g.gross_price)/1000000, 2) AS net_sales_mln<br>
FROM fact_sales_monthly s<br>
JOIN dim_customer c ON s.customer_code = c.customer_code<br>
JOIN fact_gross_price g ON s.product_code = g.product_code<br>
                       AND s.fiscal_year = g.fiscal_year<br>
GROUP BY c.market<br>
ORDER BY net_sales_mln DESC<br>
LIMIT 10;<br>

![Dashboard Screenshot](Top_10 markets by net sales.png)

### 🔹 Customer Analysis<br>
•	Segmented customers into High (28%) / Medium (32%) / Low (40%) value.<br>
•	Medium-value customers offer the largest growth opportunity.<br>
•	E-commerce platforms like Amazon & Flipkart sustain 1500+ day customer lifetimes.<br>

Example Query – Customer Segmentation by Revenue Contribution<br>

WITH customer_revenue AS (<br>
    SELECT c.customer_code,<br>
           c.customer,<br>
           SUM(s.sold_quantity * g.gross_price) AS total_revenue<br>
    FROM fact_sales_monthly s<br>
    JOIN dim_customer c ON s.customer_code = c.customer_code<br>
    JOIN fact_gross_price g ON s.product_code = g.product_code<br>
                           AND s.fiscal_year = g.fiscal_year<br>
    GROUP BY c.customer_code, c.customer<br>
)<br>
SELECT customer,<br>
       total_revenue,<br>
       CASE <br>
         WHEN total_revenue >= 100000000 THEN 'High Value'<br>
         WHEN total_revenue BETWEEN 50000000 AND 100000000 THEN 'Medium Value'<br>
         ELSE 'Low Value'<br>
       END AS customer_segment<br>
FROM customer_revenue<br>
ORDER BY total_revenue DESC;<br>

### 🔹 Product Analysis<br>
•	Computer peripherals (Mouse & Keyboards) lead sales (~70M units).<br>
•	Storage devices & high-performance components show strong demand.<br>
•	Smaller accessories highlight cross-selling opportunities.<br>

Example Query – Top Products by Quantity Sold<br>

SELECT p.product,<br>
       ROUND(SUM(s.sold_quantity)/1000000, 2) AS qty_sold_mln<br>
FROM fact_sales_monthly s<br>
JOIN dim_product p ON s.product_code = p.product_code<br>
GROUP BY p.product<br>
ORDER BY qty_sold_mln DESC<br>
LIMIT 10;<br>

### 🔹 India Market Deep Dive<br>
•	E-Commerce dominates (Amazon ₹240M+, Flipkart ₹108M).<br>
•	Brick & Mortar (Vijay Sales, Propel, Electricalsocity) remain significant.<br>
•	India delivers 4–6x higher revenue per customer vs. other markets.<br>

Example Query – Top Customers in India<br>

SELECT c.customer,<br>
       ROUND(SUM(s.sold_quantity * g.gross_price)/1000000, 2) AS revenue_inr_mln,<br>
       c.platform<br>
FROM fact_sales_monthly s<br>
JOIN dim_customer c ON s.customer_code = c.customer_code<br>
JOIN fact_gross_price g ON s.product_code = g.product_code<br>
                       AND s.fiscal_year = g.fiscal_year<br>
WHERE c.market = 'India'<br>
GROUP BY c.customer, c.platform<br>
ORDER BY revenue_inr_mln DESC<br>
LIMIT 10;<br>

### 🔹 Supply Chain Analysis<br>
•	Forecast accuracy ~45% vs. 80% target → major inefficiencies.<br>
•	Even top accounts (Amazon, Walmart) show accuracy gaps.<br>
•	Opportunity to implement ML/AI forecasting models.<br>

Example Query – Forecast Accuracy by Customer<br>

SELECT c.customer,<br>
       ROUND(SUM(f.forecast_quantity)/SUM(s.sold_quantity) * 100, 2) AS forecast_accuracy_pct<br>
FROM fact_sales_monthly s<br>
JOIN dim_customer c ON s.customer_code = c.customer_code<br>
JOIN fact_forecast_monthly f ON s.product_code = f.product_code<br>
                            AND s.fiscal_year = f.fiscal_year<br>
                            AND s.date = f.date<br>
GROUP BY c.customer<br>
ORDER BY forecast_accuracy_pct ASC<br>
LIMIT 10;<br>

### 🔹 Comparative Market Analysis<br>
•	India’s revenue grew ~35x (₹26M → ₹910M) between 2018–2022.<br>
•	Other regions have larger customer bases but much lower per-customer revenue.<br>

Example Query – Revenue Trend India vs. Other Markets<br>

SELECT fiscal_year,<br>
       SUM(CASE WHEN market = 'India' THEN s.sold_quantity * g.gross_price ELSE 0 END) AS india_revenue,<br>
       SUM(CASE WHEN market <> 'India' THEN s.sold_quantity * g.gross_price ELSE 0 END) AS other_revenue<br>
FROM fact_sales_monthly s<br>
JOIN dim_customer c ON s.customer_code = c.customer_code<br>
JOIN fact_gross_price g ON s.product_code = g.product_code<br>
                       AND s.fiscal_year = g.fiscal_year<br>
GROUP BY fiscal_year<br>
ORDER BY fiscal_year;<br>

## 🚀 Business Impact & Recommendations<br>
•	Prioritize India → Allocate resources to scale in a high-efficiency market.<br>
•	Engage Medium-Value Customers → Loyalty programs & upselling campaigns.<br>
•	Diversify Products & Customers → Reduce dependency on top 20% revenue contributors.<br>
•	Improve Forecasting Models → Deploy ML/AI models to increase accuracy from 45% → 70%+.<br>
•	Strengthen E-commerce Partnerships → Deepen engagement with Amazon & Flipkart.<br>
•	Scale Best Practices Globally → Replicate India’s success in other APAC markets.<br>

## 📷 Screenshots / Visuals<br>
The repository includes:<br>
•	ERD of database schema<br>
•	SQL scripts for each analysis block<br>
•	Charts on customer segmentation, market comparison, and product trends<br>

## 📈 Project Impact<br>
✔ Solved reporting gaps through segmentation & visibility<br>
✔ Identified revenue risks and forecasting inefficiencies<br>
✔ Highlighted India vs. global growth opportunities<br>
✔ Enabled data-driven decisions across finance, product, customer, and supply chain<br>
