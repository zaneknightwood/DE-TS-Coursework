/* 

Built-in Functions

-- missed this bit

*/

/*

Aggregation Functions
- AVG
- COUNT
- STDEV/VAR
- APPROX_COUNT_DISTINCT
	- Faster than a full distinct count

*/

USE retail_db;

SELECT COUNT(DISTINCT customer_street) FROM customers;
SELECT APPROX_COUNT_DISTINCT(customer_street) FROM customers;

/*

Scalar Functions: One input -> One output

Conversion Functions
- CAST/CONVERT
	- CAST(expression AS datatype); CAST(revenue AS DECIMAL(18,2))
	-CONVERT(datatype, expression); CONVERT(DECIMAL(18,2), revenue)
- TRY_CAST/TRY_CONVERT - Returns NULL if unsuccessful

*/

SELECT CAST(10.646 AS INT) trunc1,
	CAST(-10.646 AS INT) trunc2,
	CAST(10.646 AS NUMERIC(5,1)) round1,
	CAST(-10.646 AS NUMERIC) round2;

SELECT * FROM order_items
WHERE CAST(order_item_subtotal AS INT) LIKE '11%'
ORDER BY order_item_subtotal DESC;

-- TRY_CAST
	-- Can be used to ensure date format matches db date format
	-- SET DATEFORMAT <format> : SET DATEFORMAT mdy
SELECT TRY_CAST('31/12/2024' AS DATETIME2) AS [Date];

/*

Date and Time Functions

*/

SELECT
	SYSDATETIME(), -- datetime2(7)
	SYSDATETIMEOFFSET(), -- datetimeoffset(7) -includes timezone
	SYSUTCDATETIME(), -- datetime2 converted to UTC time
	CURRENT_TIMESTAMP, -- datetime current
	GETDATE(), -- Alias for current_timestamp
	GETUTCDATE(); -- datetime converted to UTC


-- Very important to read documentation on Dates/Times
-- If you/someone mess up the datetime formats, messes everything up
-- ETL Pipeline: SQL (local time) -> DATA LAKE (Datetime with offset) -> Data Warehouse (UTC Time)

-- Construct dates from their individual parts
-- DATEFROMPARTS/TIMEFROMPARTS
SELECT DATEFROMPARTS(2024, 06, 27);
SELECT TIMEFROMPARTS(12, 31, 45, 5234, 5); -- hour, min, sec, subsecond, precision for subsecond

-- FORMAT()
SELECT TOP 10 FORMAT(order_date, 'yyyy-MM       /dd') FROM orders;

-- Comparing Dates
-- DATEDIFF(datepart, start_datetime, end_datetime)
SELECT DATEDIFF(week, min(order_date), max(order_date)) FROM orders;
SELECT DATEDIFF(day, max(order_date), min(order_date)) FROM orders;

--Add to a date
SELECT TOP 3
	order_date,
	DATEADD(day, 3, order_date) plus_3_days,
	DATEADD(month, 3, order_date) plus_3_months,
	DATEADD(year, 3, order_date) plus_3_years
FROM orders;

-- Edge Cases: Leap Years, Last Day of Month, February
	-- Need to lookup in documentation for dataset
	-- Edge cases are handled differently for different languages


-- EOMONTH - returns end of month
SELECT TOP 3 order_date, EOMONTH(order_date) FROM orders;

-- Convert date to datetime with offset
-- Doesn't change format, just adds offset
SELECT GETDATE(), TODATETIMEOFFSET(GETDATE(), '-05:00'); --need to know offset for specific timezone


/*

Mathematical Functions

- ABS(n)
- CIELING(n)
- FLOOR(n)
- PI()
- RAND(seed) - between 0 and 1
- SQRT(float)
- SQUARE(float)
- Trig Functions (many available)


*/

SELECT RAND();

/*

String Funcitons

Quick note on Collation
	- input a string -> result uses input string's collation
	- generate a string -> results uses default db collation

*/

-- LEN()

SELECT LEN('Hello World!') AS result;

-- LOWER(), UPPER()

-- Extract data
-- LEFT(str, n), RIGHT(str, n)

SELECT
	LEFT('123 456 789', 3) left_str,
	RIGHT('123 456 789', 3) right_str;

-- SUBSTRING(str, starting_point, num_to_return)
-- SQL starts at 1, not 0!!
SELECT SUBSTRING('123 456 789', 5, 3) result;

-- STRING_SPLIT(str, split_char, enable_ordinal) --enable_ordinal is 0 or 1
SELECT * FROM STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ', 1);


-- Concatenate strings with CONCAT()
SELECT CONCAT('Hello', ' ', 'World');

-- CONCAT_WS(ws_char, str1, ...strn)
SELECT CONCAT_WS(' ', 'Hello', 'how', 'are', 'you', 'today?')

-- Compare similarity of strings
	-- based on algorythm that compares sounds somehow
SELECT DIFFERENCE('Computer', 'Computation');
SELECT DIFFERENCE('apples', 'oranges');

-- LTRIM, RTRIM, TRIM
SELECT
	LTRIM('      Hello World      1') AS [Left Trim],
	RTRIM('      Hello World      ') AS [Right Trim],
	TRIM('      Hello World      ') AS [Trim];

-- REPLACE
SELECT REPLACE('Hello World!', 'World!', 'Tony!');

-- REPLICATE
SELECT REPLICATE('YAY', 3);

--Handling Nulls

-- COALESCE(exp1, exp2,...expn) -> returns first Not Null expression

USE demo;
GO
DROP TABLE users;

CREATE TABLE users (
	user_id int PRIMARY KEY IDENTITY,
	user_fname VARCHAR(30),
	user_lname VARCHAR(30),
	user_email_id VARCHAR(50),
    user_email_validated bit DEFAULT 0,
    user_password VARCHAR(200),
    user_role VARCHAR(30) NOT NULL DEFAULT 'U',
    is_active bit DEFAULT 0,
    last_updated_ts DATETIME DEFAULT getdate()
);

INSERT INTO users (user_fname, user_lname, user_email_id, user_password, user_role, is_active)
VALUES ('Sora', 'Hearts', 'keyblade@master.com', '019he221', 'U', 1);

INSERT INTO users (user_email_id, user_password, user_role)
VALUES ('minnie@mouse.com', 'fhuih1234', 'U', 1);

INSERT INTO users (is_active)
VALUES (1);

-- Order Matters
SELECT user_id, user_fname, user_lname, user_email_id, user_password, user_role, is_active,
COALESCE(user_fname, user_lname, user_email_id) [First Not Null]
FROM users;

SELECT user_id, user_fname, user_lname, user_email_id, is_active
COALESCE(user_email_id, user_lname, user_fname) [First Not Null]
FROM users;

-- Processing Orders
-- 5 dates: order_placed, warehouse_processed, date_shipped, date_delivered, date_returned
-- COALESCE(date_returned, date_delivered, date_shipped, warehouse_processed, order_placed)
-- SELECT o.status, COALESCE(date_returned, date_delivered, date_shipped, warehouse_processed, order_placed) [Date]


-- NULLIF(exp1, exp2)
-- Returns NULL if expressions are equal, otherwise returns exp1
SELECT NULLIF('Hello', 'World');
SELECT NULLIF('Hello', 'hello');
SELECT NULLIF('Hello', 'Hello');

/*
 Logical Functions

*/

-- CHOOSE(index, val1, val2,...valn)
	-- 1 based indexing

SELECT *, CHOOSE(MONTH(order_date),
	'Winter',
	'Winter',
	'Spring',
	'Spring',
	'Spring',
	'Summer',
	'Summer',
	'Summer',
	'Autumn',
	'Autumn',
	'Autumn',
	'Winter') Season
FROM orders;

-- IIF(if_statment, if_true, if_false)
SELECT *, IIF(order_item_subtotal > 200, 'expensive', 'cheap') [Cost] FROM order_items;

-- 'Syntatic Sugar' for Case statement


/*

CASE STATEMENT

SWITCH STATEMENT

*/

USE AdventureWorks2022;
GO

-- Creates big switch statement
SELECT ProductNumber,
	ProductLine,
	Category = CASE ProductLine
		WHEN 'R' THEN 'Road'
		WHEN 'M' THEN 'Mountain'
		WHEN 'T' THEN 'Touring'
		WHEN 'S' THEN 'Other'
		ELSE 'Not For Sale'
		END,
	Name
FROM Production.Product
ORDER BY ProductNumber;


/*

Views

- View is just a named query
- Doesn't physically store data (runs the query each time)
- Stores a query for ease of use
- Used mostly for reports
	- DO NOT show primary keys in reports!
- Queries are fine, but modifications are limited
	- Updatable Views: Unaggregated views are generally updatable
	- Not recommended

*/

-- Updatable View
CREATE VIEW orders_v AS
SELECT * FROM orders;

SELECT * FROM orders;
SELECT * FROM orders_v;

-- update changes both view and underlying table when view made as table instead of query
UPDATE orders_v
SET order_status = LOWER(order_status);

DROP VIEW orders_v;


-- create view as query
CREATE VIEW orders_v AS
SELECT order_id, order_date, order_customer_id, upper(order_status) order_status FROM orders;

-- Views are usually report ready
CREATE VIEW orders_v AS
SELECT
	order_ id [Order ID],
	FORMAT(order_date, 'yyyy-MM-dd') [Order Date],
	order_customer_id [Customer ID],
	upper(order_status) [Status]
FROM orders;

SELECT * FROM orders_v;


-- Get the daily revenue for each product

SELECT
	CAST(o.order_date AS Date) [Order Date],
	p.product_name [Product],
	CAST(SUM(order_item_subtotal) AS DECIMAL(18,2)) [Revenue]
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
JOIN products p ON oi.order_item_product_id = p.product_id
GROUP BY p.product_id, o.order_date, p.product_name;

-- Make it a view
CREATE VIEW daily_product_revenue AS
SELECT
	CAST(o.order_date AS Date) [Order Date],
	DATENAME(dw, order_date) [Day of the Week],
	p.product_name [Product],
	CAST(SUM(order_item_subtotal) AS DECIMAL(18,2)) [Revenue]
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
JOIN products p ON oi.order_item_product_id = p.product_id
GROUP BY p.product_id, o.order_date, p.product_name;

-- More complex our query, the longer it takes to view
-- Write to tables, read from views
-- Can query aggregated columns from view

--Query our view
SELECT * FROM daily_product_revenue
WHERE [Day of the Week] = 'Friday'
ORDER BY Revenue DESC;

-- Try and Update the view
-- Doesn't work
UPDATE daily_product_revenue
SET Product = 'Generic';


-- Nesting views is possible, but not recommended
-- Create a view from a view -> queries view, view queries table
	-- Can lead to issues


-- Common Table Expression (CTE)
	-- Named Query
-- Functionally works as subquery
-- WITH <name> AS (<definition>)
-- Exisits only until ';'
	-- is not stored
-- allows for more clarity when using complex subqueries

WITH order_details_nq AS (
	SELECT * FROM orders o
	JOIN order_times oi ON o.order_id = oi.oreder_item_order_id
) SELECT * FROM order_details_nq;

-- We can use CTEs to filter by derived and aggregated cols
WITH order_details_nq AS (
SELECT
	CAST(o.order_date AS Date) [Order Date],
	DATENAME(dw, order_date) [Day of the Week],
	p.product_name [Product],
	CAST(SUM(order_item_subtotal) AS DECIMAL(18,2)) [Revenue]
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
JOIN products p ON oi.order_item_product_id = p.product_id
GROUP BY p.product_id, o.order_date, p.product_name
)
SELECT * FROM order_details_nq
WHERE Revenue < 100 AND [Day of the Week] = 'Sunday';

/*

Subqueries

Queries in the FROM/WHERE clause
Alias is Mandaroty in FROM clause
- Usually small one liners

*/

SELECT * FROM
(SELECT * FROM orders WHERE order_status LIKE 'CL%') o
JOIN order_items oi ON o.order_id = oi.order_item_order_id;

-- Same as CTE
SELECT * FROM 
(
SELECT
	CAST(o.order_date AS Date) [Order Date],
	DATENAME(dw, order_date) [Day of the Week],
	p.product_name [Product],
	CAST(SUM(order_item_subtotal) AS DECIMAL(18,2)) [Revenue]
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
JOIN products p ON oi.order_item_product_id = p.product_id
GROUP BY p.product_id, o.order_date, p.product_name
) sq
WHERE [Day of the Week] = 'Monday';

-- WHERE Clause Subqueries
-- Potential performance concerns (likely to cause a full table scan)

-- All of the orders with no items on them
-- A little janky to try and do on a join
SELECT * FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_item_order_id;

-- Use a subquery
SELECT * FROM orders o
WHERE o.order_id NOT IN (SELECT DISTINCT order_item_order_id FROM order_items);


/*

CTAS - Create Table As Select

Standard Syntax: CREATE TABLE <table> AS SELECT ...
SQL Server Syntax: SELECT <cols> INTO <new_table> FROM <current_table>

Creates a full copy into a new table using the results of query
Do not specify col names or data types - based on results

Use Cases
- Taking a backup for troubleshooting and debugging
- Migrating schemas
- Historical Analysis (slow and complex queries)
- Copy table definitions into empty table
- Make sdjustments to table

*/


-- Simple backup
SELECT * INTO customers_backup FROM customers;

SELECT * FROM customers;
SELECT * FROM customers_backup;

DROP TABLE customers_backup;

-- Copy table definition (empty table)
-- Add a false where condition

SELECT * INTO customers_backup FROM customers
WHERE 1=2;

-- Make adjustments to tables
SELECT order_id,
	FORMAT(order_date, 'yyyy') AS order_year,
	FORMAT(order_date, 'MM') AS order_month,
	FORMAT(order_date, 'dd') AS order_day,
	order_customer_id,
	order_status
INTO orders_backup
FROM orders;

SELECT * FROM orders_backup;

-- Cleanup after yourself
	-- use naming conventions to more easily see what's been created
	-- drop tables when finished with them
DROP TABLE orders_backup;

-- INSERT INTO with results of a query
-- Columns for specified table must match query results

-- Create Table
CREATE TABLE customer_order_metrics (
	customer_id INT NOT NULL,
	order_month CHAR(7) NOT NULL,
	order_count INT,
	order_revenue FLOAT
);

-- Define a composite PK 
ALTER TABLE customer_order_metrics
	ADD PRIMARY KEY (order_month, customer_id);

-- Build query
SELECT TOP 10
	o.order_customer_id customer_id,
	FORMAT(o.order_date, 'yyyy-MM') order_month,
	COUNT(1) order_count,
	CAST(SUM(oi.order_item_subtotal) AS DECIMAL(18,2)) order_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
GROUP BY o.order_customer_id, FORMAT(o.order_date, 'yyyy-MM')
ORDER BY order_month, order_count DESC;


-- INSERT INTO
INSERT INTO customer_order_metrics
SELECT
	o.order_customer_id customer_id,
	FORMAT(o.order_date, 'yyyy-MM') order_month,
	COUNT(1) order_count,
	CAST(SUM(oi.order_item_subtotal) AS DECIMAL(18,2)) order_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
GROUP BY o.order_customer_id, FORMAT(o.order_date, 'yyyy-MM')
ORDER BY order_month, order_count DESC;

SELECT * FROM customer_order_metrics;

-- Returning a table is much faster than running a query

DROP TABLE customer_order_metrics;

-- UPDATE and DELETE are also possible to do with queries

/*

UPSERT/MERGE

UPSERT = INSERT + UPDATE


SQL Server doesn't have UPSERT

Must use MERGE

Incredibly common in Data Warehouses


Slow way: Develope and UPDATE statement and an INSERT statement and manually check data for which is which
UPSERT Statement: Best case, but not always available

MERGE Statement

Pros:
	- Gives absolute control
	- Able to Update, Insert, and Delete all in one statement
Cons:
	- Very verbose

*/

-- see video/uploaded notes for example