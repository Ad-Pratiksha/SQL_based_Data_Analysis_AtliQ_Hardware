### Supply Chain Analytics  ###

-- Create fact_act_est table
drop table if exists fact_act_est;
CREATE TABLE fact_act_est AS
SELECT
s.date AS date,
s.fiscal_year AS fiscal_year,
s.product_code AS product_code,
s.customer_code AS customer_code,
s.sold_quantity AS sold_quantity,
f.forecast_quantity AS forecast_quantity
FROM fact_sales_monthly s
LEFT JOIN fact_forecast_monthly f
USING (date, customer_code, product_code)
UNION ALL   -- use ALL (faster, no duplicate check)
SELECT
f.date AS date,
f.fiscal_year AS fiscal_year,
f.product_code AS product_code,
f.customer_code AS customer_code,
s.sold_quantity AS sold_quantity,
f.forecast_quantity AS forecast_quantity
FROM fact_forecast_monthly f
LEFT JOIN fact_sales_monthly s
USING (date, customer_code, product_code)
WHERE s.date IS NULL;   -- prevents duplicates

update fact_act_est
set sold_quantity = 0
where sold_quantity is null;

update fact_act_est
set forecast_quantity = 0
where forecast_quantity is null;

-- create the trigger to automatically insert record in fact_act_est table whenever insertion happens in fact_sales_monthly
#	CREATE DEFINER=CURRENT_USER TRIGGER `fact_sales_monthly_AFTER_INSERT` AFTER INSERT ON `fact_sales_monthly` FOR EACH ROW
#	BEGIN
#	insert into fact_act_est
#	(date, product_code, customer_code, sold_quantity)
#	values (
#	NEW.date,
#	NEW.product_code,
#	NEW.customer_code,
#	NEW.sold_quantity
#	)
#	on duplicate key update
#	sold_quantity = values(sold_quantity);
#	END;

-- create the trigger to automatically insert record in fact_act_est table whenever insertion happens in fact_forecast_monthly
#	CREATE DEFINER=CURRENT_USER TRIGGER `fact_forecast_monthly_AFTER_INSERT` AFTER INSERT ON `fact_forecast_monthly` FOR EACH ROW
#	BEGIN
#	insert into fact_act_est
#	(date, product_code, customer_code, forecast_quantity)
#	values (
#	NEW.date,
#	NEW.product_code,
#	NEW.customer_code,
#	NEW.forecast_quantity
#	)
#	on duplicate key update
#	forecast_quantity = values(forecast_quantity);
#	END;

-- To see all the Triggers
show triggers;

-- Creating the table "session_logs" and inserting records
CREATE TABLE session_logs (`ts` DATETIME, `session_id` INT, `user_id` INT, `log` TEXT);
INSERT INTO `session_logs`
(`ts`, `session_id`, `user_id`, `log`)
VALUES
('2022-10-04 08:14:07', '898812', '523', 'CLICKED | Courses Button'),
('2022-10-14 08:18:35', '898812', '523', 'NAVIGATE BACK | Python course page , codebasics.io'),
('2022-10-16 12:07:00', '965345', '523', 'REVIEW GENERATED | Data analytics in power bi'),
('2022-10-22 14:09:22', '188567', '707', 'NEW LOGIN | New login, user name: tasty@jalebi.com'),
('2022-10-22 18:10:06', '188567', '707', 'COURSE PURCHASED | Data analytics in power bi, user name: tasty@jalebi.com');

-- Delete logs that are less than 5 days old
delimiter |
CREATE EVENT e_daily_log_purge
ON SCHEDULE
EVERY 5 SECOND
COMMENT 'Purge logs that are more than 5 days old'
DO
BEGIN
delete from session_logs
where DATE(ts) < DATE("2022-10-22") - interval 5 day;
END |
delimiter ;

-- drop the event
drop event if exists e_daily_log_purge;

-- Forecast accuracy report using cte
SET SESSION sql_mode = ''; 
with forecast_err_table as (
select 
a.customer_code,
sum(sold_quantity),
sum(forecast_quantity),
sum(forecast_quantity-sold_quantity) as net_err,
sum((forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as net_err_pct,
sum(abs(forecast_quantity-sold_quantity)) as abs_err,
sum(abs(forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as abs_err_pct
from fact_actual_est a
where a.fiscal_year = 2021
group by a.customer_code)
select 
e.*,
c.customer as customer_name,
c.market,
if(abs_err_pct > 100, 0, 100-abs_err_pct) as forecast_accuracy
from forecast_err_table e
join dim_customer c using(customer_code)
order by forecast_accuracy desc;

-- Write a stored proc for the same
#	CREATE PROCEDURE `get_forecast_accuracy`(
#	IN in_fiscal_year INT
#	)
#	BEGIN
#	SET SESSION sql_mode = ''; 
#	with forecast_err_table as (
#	select 
#	a.customer_code,
#	sum(sold_quantity),
#	sum(forecast_quantity),
#	sum(forecast_quantity-sold_quantity) as net_err,
#	sum((forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as net_err_pct,
#	sum(abs(forecast_quantity-sold_quantity)) as abs_err,
#	sum(abs(forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as abs_err_pct
#	from fact_actual_est a
#	where a.fiscal_year = 2021
#	group by a.customer_code)
#	select 
#	e.*,
#	c.customer as customer_name,
#	c.market,
#	if(abs_err_pct > 100, 0, 100-abs_err_pct) as forecast_accuracy
#	from forecast_err_table e
#	join dim_customer c using(customer_code)
#	order by forecast_accuracy desc;
#	END;

-- Forecast accuracy report using temporary table
ALTER TABLE fact_act_est 
MODIFY forecast_quantity BIGINT SIGNED NOT NULL,
MODIFY sold_quantity BIGINT SIGNED NOT NULL;
drop table if exists forecast_err_table;
create temporary table forecast_err_table
select
s.customer_code as customer_code,
c.customer as customer_name,
c.market as market,
sum(s.sold_quantity) as total_sold_qty,
sum(s.forecast_quantity) as total_forecast_qty,
sum(s.forecast_quantity-s.sold_quantity) as net_error,
sum(s.forecast_quantity-s.sold_quantity)*100/sum(s.forecast_quantity) as net_error_pct,
sum(abs(s.forecast_quantity-s.sold_quantity)) as abs_error,
sum(abs(s.forecast_quantity-sold_quantity))*100/sum(s.forecast_quantity) as abs_error_pct
from fact_act_est s
join dim_customer c
on s.customer_code = c.customer_code
where s.fiscal_year=2021
group by customer_code;

select
*,
if (abs_error_pct > 100, 0, 100.0 - abs_error_pct) as forecast_accuracy
from forecast_err_table
order by forecast_accuracy desc;

-- Create a new user 'thor'
create user 'thor'@'localhost' identified by 'thor';

-- Allow certain access to 'thor' user for the database
grant select on dim_customer to 'thor'@'localhost';
grant select on dim_product to 'thor'@'localhost';
grant execute on procedure get_forecast_accuracy to 'thor'@'localhost';

-- See all the access for 'thor' user
show grants for 'thor'@'localhost';

-- Write a query for customers whose forecast accuracy has dropped from 2020 to 2021
# step 1: Get forecast accuracy of FY 2021 and store that in a temporary table
drop table if exists forecast_accuracy_2021;
create temporary table forecast_accuracy_2021
with forecast_err_table as (
select
s.customer_code as customer_code,
c.customer as customer_name,
c.market as market,
sum(s.sold_quantity) as total_sold_qty,
sum(s.forecast_quantity) as total_forecast_qty,
sum(s.forecast_quantity-s.sold_quantity) as net_error,
round(sum(s.forecast_quantity-s.sold_quantity)*100/sum(s.forecast_quantity),1) as net_error_pct,
sum(abs(s.forecast_quantity-s.sold_quantity)) as abs_error,
round(sum(abs(s.forecast_quantity-sold_quantity))*100/sum(s.forecast_quantity),2) as abs_error_pct
from fact_act_est s
join dim_customer c
on s.customer_code = c.customer_code
where s.fiscal_year=2021
group by customer_code
)
select
*,
if (abs_error_pct > 100, 0, 100.0 - abs_error_pct) as forecast_accuracy
from
forecast_err_table
order by forecast_accuracy desc;
# step 2: Get forecast accuracy of FY 2020 and store that also in a temporary table
drop table if exists forecast_accuracy_2020;
create temporary table forecast_accuracy_2020
with forecast_err_table as (
select
s.customer_code as customer_code,
c.customer as customer_name,
c.market as market,
sum(s.sold_quantity) as total_sold_qty,
sum(s.forecast_quantity) as total_forecast_qty,
sum(s.forecast_quantity-s.sold_quantity) as net_error,
round(sum(s.forecast_quantity-s.sold_quantity)*100/sum(s.forecast_quantity),1) as net_error_pct,
sum(abs(s.forecast_quantity-s.sold_quantity)) as abs_error,
round(sum(abs(s.forecast_quantity-sold_quantity))*100/sum(s.forecast_quantity),2) as abs_error_pct
from fact_act_est s
join dim_customer c
on s.customer_code = c.customer_code
where s.fiscal_year=2020
group by customer_code
)
select
*,
if (abs_error_pct > 100, 0, 100.0 - abs_error_pct) as forecast_accuracy
from
forecast_err_table
order by forecast_accuracy desc;
# step 3: Join forecast accuracy tables for 2020 and 2021 using a customer_code
select
f_2020.customer_code,
f_2020.customer_name,
f_2020.market,
f_2020.forecast_accuracy as forecast_acc_2020,
f_2021.forecast_accuracy as forecast_acc_2021
from forecast_accuracy_2020 f_2020
join forecast_accuracy_2021 f_2021
on f_2020.customer_code = f_2021.customer_code
where f_2021.forecast_accuracy < f_2020.forecast_accuracy
order by forecast_acc_2020 desc;