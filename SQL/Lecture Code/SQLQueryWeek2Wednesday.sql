CREATE DATABASE demo;

USE demo;

-- Referential Integrity
CREATE TABLE departments (
	department_id int PRIMARY KEY IDENTITY,
	department_name VARCHAR(30),
	department_phone VARCHAR(10)
);

-- Setting up a Foreign Key
CREATE TABLE users (
	user_id int PRIMARY KEY IDENTITY,
	user_fname VARCHAR(30) NOT NULL,
	user_lname VARCHAR(30) NOT NULL,
	user_email_id VARCHAR(50) NOT NULL,
    user_email_validated bit DEFAULT 0,
    user_password VARCHAR(200),
    user_role VARCHAR(30) NOT NULL DEFAULT 'U',
    is_active bit DEFAULT 0,
    last_updated_ts DATETIME DEFAULT getdate(),
	department_id INT FOREIGN KEY REFERENCES departments(department_id)
	ON DELETE CASCADE -- Follows foreign keys to their tables and deletes associated rows
	ON UPDATE CASCADE
);

DROP TABLE departments;

INSERT INTO departments 
	(department_name)
VALUES
	('Marketing'),
	('HR');

INSERT INTO users
	(user_fname, user_lname, user_email_id, user_password, user_role, is_active, department_id)
VALUES
	('Sora', 'Hearts', 'keyblade@master.com', '019he221', 'U', 1, 1),
    ('Minnie', 'Mouse', 'minnie@mouse.com', 'fhuih1234', 'U', 1, 2),
    ('Max', 'Goof', 'max@goof.com', 'j4892hyf1', 'U', 1, 2);

USE retail_db;

-- Validate data loaded
SELECT TOP 20 * FROM retail_db.dbo.order_items;

/*
Loading Data
- From a .sql file
- Load data from a flat file (.csv, Parquet, JSON)
- Backup file (.bak)
- Azure Migration Services: Azure SQL Migration with Azure Data Studio
	- Azure is Microsoft, so using mssql with it is easier

External Applications
- JDBC (Java Database Connector Library)
	- Open source and works with most sql
- ODBC (Open Database Connectivity)
	- Microsoft
	- Allows flexibility
- Type Mappings: Python(strings) -> SQL(varchar)


OLE DB (Open Linking and Embedding)
- Open Linking and Embedding
- API to utilize many different databases
- Used for uncommon/specific file formats
- OPENROWSET
	- Used to access OLE DB data 
	- Reads data from external source (not local!)
*/

-- Queries

-- Shows all tables in database with db name, schema, name, and type
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'retail_db';

-- Best to select top 10 to verify data is loaded
SELECT TOP 10 * FROM departments;

/*

Projecting/Selecting Data

SELECT Statement
- * Wildcard selects all
- Can select specific columns
- Aliases to columns
- DISTINCT -> all unique values
- Simple Aggregations
	- sum()
	- count()
	- max()/min()
	- avg()

*/

SELECT TOP 10 * FROM orders;

-- Full Syntax of 'TOP 10 *'
SELECT * FROM orders ORDER BY order_id -- ORDER BY -> sorts using specified column (can sort anything that is comparable: int, string, date)
OFFSET 0 ROWS -- Can use this to choose specific rows (set to 10 to start at row 11)
FETCH NEXT 10 ROWS ONLY;


-- Select Percentages (% of table: 10% is 10/100 rows)
SELECT TOP 10 PERCENT * FROM orders;


-- Modify columns in select
-- If presenting data, always format data/column names to make it easier to read!
-- AS does not change table, only display
	-- AS should use brackets in mssql (language depedant)
-- Columns will appear in the order they are selected
-- Predictor should be last column
SELECT TOP 10
	order_id AS [Order ID#],
	format(order_date, 'yyy-MM') AS [Order Month], -- note, without AS column will have no name!
	order_customer_id AS [Customer ID#],
	order_status AS [Status]
FROM orders;

-- Get the number of dates that products were ordered on
SELECT COUNT(DISTINCT order_date) AS [Days] FROM orders;

-- COUNT(1) or COUNT(*)
	-- Almost identical (1 means true)
-- COUNT(col) counts all non-null rows

-- How many customers(rows) are there?
SELECT COUNT(1) FROM customers;

-- How many live in TX?
SELECT COUNT(1) FROM customers WHERE customer_state = 'TX';


-- Run together, shows num non-null customer_state and num non-null customers (I think??)
SELECT COUNT(customer_state) FROM customers;
SELECT COUNT(1) FROM customers;


/*

Filtering Data

WHERE <condition>

Comparators: =, !=, >, <, >=, <=
	LIKE/ILIKE

Combine conditions with OR and AND
Ranges of Data using BETWEEN: BETWEEN x AND y

Nulls
- Have to use IS/IS NOT NULL
- Cannot use =/!=

*/

-- Filter by a single value
SELECT TOP 10 * FROM orders
WHERE order_customer_id = 333;

-- Select specific rows using primary key
SELECT * FROM orders WHERE order_id = 716;

-- Filter non-uniques (needs column name)
SELECT DISTINCT order_status FROM orders;

-- Filter by multiple values
SELECT TOP 10 * FROM orders
WHERE order_customer_id = 333
	OR order_customer_id = 127
	OR order_customer_id = 1;

-- Better syntax using IN
-- >50 values in the IN clause is massively expenses
SELECT TOP 10 * FROM orders
WHERE order_customer_id IN (333,127,1);

-- LIKE Operator
-- % -> match any number of characters
-- _ -> match any single character
-- ILIKE -> case insensitive LIKE (doesn't work in mssql, mssql is case insensitive)
SELECT TOP 10 * FROM orders
WHERE order_status LIKE 'COMPLETE%';

-- View collation
-- Latin1_General_CI_AS (language_General?_case(CI=case insensitive)_AS?) LOOK THIS UP!!
SELECT CONVERT (varchar(256), SERVERPROPERTY('collation'));

-- Popular use of LIKE is date matching
SELECT TOP 10 PERCENT * FROM orders
WHERE format(order_date, 'yyy-MM-dd') LIKE '2014-01%';

-- Check Nulls
SELECT COUNT(1) FROM orders
WHERE order_date IS NULL;

-- Can use NOT LIKE to pull anything that doesn't contain thing
SELECT TOP 10 PERCENT * FROM orders
WHERE FORMAT(order_date, 'yyy-MM-dd') NOT LIKE '2014-01%';

/*

JOINS

- ANSI and NON-ANSI JOINS
- We will be using ANSI style JOINS
	- Syntax: <col> JOIN <col2> ON <condition:> (col1=col2)
- NON-ANSI
	- Syntax: SELECT orders.*, order_items.* FROM orders, WHERE order.order_id = order_items.order_id


Types of JOINS
- Outer
	- Left outer
	- Right outer
	- Full outer
	- Always preserve at least 1 table
- Inner
	- Only records that appear in both tables

*/

-- Specify the cols to join on
-- SELECT o.* FROM orders o -> creates an alias for orders
-- SELECT order_items oi -> creates an alias for order_items
-- Inner joins by default
SELECT TOP 10 o.*, oi.order_item_id, oi.order_item_subtotal
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id;

-- Left Join
-- Preserves all data from left table and only matching table form right
-- All orders with items on them + all orders without times on them
SELECT TOP 10 PERCENT o.*, oi.order_item_id, oi.order_item_subtotal
FROM orders o
LEFT OUTER JOIN order_items oi ON o.order_id = oi.order_item_order_id;


-- Right Join
-- Preserves all data from right table and only matching table form right
SELECT TOP 10 PERCENT o.*, oi.order_item_id, oi.order_item_subtotal
FROM order_items oi
RIGHT OUTER JOIN orders o ON o.order_id = oi.order_item_order_id;


-- How many orders with items on them?
-- Combine select statements
SELECT COUNT(1) FROM orders o
WHERE order_id IN (SELECT DISTINCT order_item_order_id FROM order_items);

-- Cross Join AKA Cartesian Join = NxM 20,000 * 20,000 = 400,000,000 (Data science queiries, not supported in mssql)
-- Full outer join 20,000 + 20,000 = 40,000
-- Self Join(employees: manager_id, employee_id) -> join table on itself to see which employees are managers


-- Filter using WHERE
-- Avoid ambiguous cols (cols that could exist in either table)
-- Cannot use derived cols in filter
SELECT TOP 10 o.*, oi.order_item_id, oi.order_item_subtotal
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
WHERE o.order_status LIKE 'Closed%';

-- Derived cols
	-- Cols created inside select (order_month in this case is created by format)
SELECT TOP 10 o.order_id, FORMAT(order_date, 'yyy-MM') as order_month, oi.order_item_id, oi.order_item_subtotal
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
WHERE o.order_month LIKE 'Closed%';

-- Can be done with filtering in where statement
SELECT TOP 10 o.order_id, FORMAT(order_date, 'yyyy-MM') as [order_month], oi.order_item_id, oi.order_item_subtotal
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
WHERE format(order_date, 'yyyy-MM') LIKE '2014-01%';


/* 

Simple Aggregations

Global Aggregations
- Total number of orders
- Average order total
- Max order total

Aggregations by key
- GROUP BY
- Syntax: GROUP BY <column> <aggregation>
	- GROUP BY department_id sum(salary)

Rules
- If we have a non-aggregated column in the results, it MUST be in the GROUP BY clause
- We can have derived columns in aggregate function
- Cannot use WHERE on 

*/

SELECT order_item_product_id, sum(order_item_subtotal) revenue
FROM order_items
GROUP BY order_item_product_id;

-- Derived columns
SELECT COUNT(1) [Count], format(order_date, 'yyyy-MM') [order_month]
FROM orders
GROUP BY format(order_date, 'yyyy-MM')
ORDER BY format(order_date, 'yyyy-MM');

-- No WHERE clause, have to use HAVING
SELECT COUNT(1) [Count], format(order_date, 'yyyy-MM') [order_month]
FROM orders
GROUP BY format(order_date, 'yyyy-MM')
HAVING COUNT(1) > 5000
ORDER BY format(order_date, 'yyyy-MM');

-- Order of Operations: FROM -> WHERE -> GROUP BY -> SELECT


-- Formatting
SELECT
	order_item_order_id,
	sum(order_item_subtotal) [Revenue],
	max(order_item_subtotal) [Largest Item],
	min(order_item_subtotal) [Smallest Item],
	avg(order_item_subtotal) [Average Item],
	count(order_item_subtotal) [Total # Items]
FROM order_items
GROUP BY order_item_order_id;


-- cast
SELECT
	order_item_order_id,
	sum(order_item_subtotal) [Revenue],
	max(order_item_subtotal) [Largest Item],
	min(order_item_subtotal) [Smallest Item],
	cast(avg(order_item_subtotal) AS decimal(6,2)) [Average Item],
	count(order_item_subtotal) [Total # Items]
FROM order_items
GROUP BY order_item_order_id;

-- round
SELECT
	order_item_order_id,
	sum(order_item_subtotal) [Revenue],
	max(order_item_subtotal) [Largest Item],
	min(order_item_subtotal) [Smallest Item],
	round(avg(order_item_subtotal), 2) [Average Item],
	count(order_item_subtotal) [Total # Items]
FROM order_items
GROUP BY order_item_order_id
ORDER BY [Revenue] desc;

/*

Sorting Data in SQL

Clustered Index: Data is physically sorted in this order
Non-Clustered Index: Tells us how to sort along that index
If not using either index, SQL will perform a full table scan (incredibly expensive)

*/

-- Without indexing, this checks entire table
SELECT * FROM order_items
ORDER BY order_item_subtotal;

-- Create index for column, makes sorting faster
CREATE INDEX order_item_subtotal_index ON order_items(order_item_subtotal desc);

-- Check what's going in under the hood
	-- ON shows info when code executed, OFF turns this off
SET SHOWPLAN_ALL ON;


-- Composite Sorting
	-- sorts in order of arguments (all of each date sorted by id)
SELECT * FROM orders
ORDER BY order_date desc, order_customer_id desc;
