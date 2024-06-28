/*

Partitioning

3 Main Strategies
- Hash
- List
- Range

SQL Server only supports range

0. (Optional) Create filegroups
1. Create partition function
2. Create partition scheme
3. Create or alter tables to specify partition column

*/

CREATE DATABASE partition_demo
GO
USE partition_demo
GO

-- Partition Function
-- RANGE RIGHT or LEFT
-- RANGE Right includes the first date
CREATE PARTITION FUNCTION myRangePF1 (DATETIME2(0))
	AS RANGE RIGHT FOR VALUES ('2022-04-01', '2022-05-01', '2022-06-01') -- first part will be all values before 4-1, then 4-1 to 4-30, then 5-1 to 6-31, then 6-1 to end
GO

-- 
ALTER PARTITION FUNCTION myRangePF1 ()
SPLIT RANGE('2022-07-01');

--Partition Scheme
CREATE PARTITION SCHEME myRangePS1
	AS PARTITION myRangePF1
	ALL TO ('PRIMARY');
GO


-- Create Table
CREATE TABLE dbo.PartitionTable (col1 DATETIME2(0) PRIMARY KEY, col2 CHAR(20))
	ON myRangePS1(col1);
GO

CREATE PARTITION FUNCTION myRangePF2 (INT)
	AS RANGE RIGHT FOR VALUES (1, 100, 1000); -- all nums before 1, 1-99, 100-999, 1000-infinity
GO

CREATE PARTITION SCHEME myRangePS2
	AS PARTITION myRangePF2
	ALL TO ('PRIMARY');
GO

-- Combine partitions (merge must happen on boundries)
-- (1, 100, 1000) becomes (1, 1000) with nums before 1, 1-999, 100+
ALTER PARTITION FUNCTION myRangePF2 ()
MERGE RANGE(100);

-- Split partition (create new partition)
ALTER PARTITION FUNCTION myRangePF2 ()
SPLIT RANGE(500);







-- Check if table is partitioned
SELECT SCHEMA_NAME(t.schema_id) AS SchemaName, *   
FROM sys.tables AS t   
JOIN sys.indexes AS i   
    ON t.[object_id] = i.[object_id]   
JOIN sys.partition_schemes ps   
    ON i.data_space_id = ps.data_space_id   
WHERE t.name = 'PartitionTable';   
GO 

-- Determine boundry values for partitioned table
SELECT SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName, i.name AS IndexName, 
    p.partition_number, p.partition_id, i.data_space_id, f.function_id, f.type_desc, 
    r.boundary_id, r.value AS BoundaryValue   
FROM sys.tables AS t  
JOIN sys.indexes AS i  
    ON t.object_id = i.object_id  
JOIN sys.partitions AS p  
    ON i.object_id = p.object_id AND i.index_id = p.index_id   
JOIN  sys.partition_schemes AS s   
    ON i.data_space_id = s.data_space_id  
JOIN sys.partition_functions AS f   
    ON s.function_id = f.function_id  
LEFT JOIN sys.partition_range_values AS r   
    ON f.function_id = r.function_id and r.boundary_id = p.partition_number  
WHERE 
    t.name = 'PartitionTable' 
    AND i.type <= 1  
ORDER BY SchemaName, t.name, i.name, p.partition_number; 


-- Determine partitioning column
SELECT   
    t.[object_id] AS ObjectID
    , SCHEMA_NAME(t.schema_id) AS SchemaName
    , t.name AS TableName   
    , ic.column_id AS PartitioningColumnID   
    , c.name AS PartitioningColumnName
    , i.name as IndexName
FROM sys.tables AS t   
JOIN sys.indexes AS i   
    ON t.[object_id] = i.[object_id]   
    AND i.[type] <= 1 -- clustered index or a heap   
JOIN sys.partition_schemes AS ps   
    ON ps.data_space_id = i.data_space_id   
JOIN sys.index_columns AS ic   
    ON ic.[object_id] = i.[object_id]   
    AND ic.index_id = i.index_id   
    AND ic.partition_ordinal >= 1 -- because 0 = non-partitioning column   
JOIN sys.columns AS c   
    ON t.[object_id] = c.[object_id]   
    AND ic.column_id = c.column_id   
WHERE t.name = 'PartitionTable';   
GO 



/*

Analytics Functions

Window Functions

Types
- GLOBAL: func() OVER (ORDER BY <col>)
	-does funciont over all of specified col
- Aggregations: func() OVER (PARTITION BY <col>)
	- allows comparison between aggrigations based on columns(ie date, department #, etc)

*/
-- need to add hr db
USE hr_db;

-- returns a column that adds to count as it goes
-- continues to add for each row encountered
SELECT employee_id, COUNT(1) OVER (ORDER BY employee_id)
FROM employees;

-- adds the salary for each employee, keeping track
-- ie, emp1 500 - sum 500, emp2 300 - sum 800, emp3 200 - sum 1000
SELECT employee_id, SUM(salary) OVER (ORDER BY employee_id)
FROM employees;


-- shows all total salaries of each department
SELECT employee_id, department_id, SUM(salary) dept_salary
FROM employees
GROUP BY department_id;


-- Compare each employee salary to the avg salary of their department
-- Traditional way - use subquery
SELECT TOP 10 e.employee_id, e.department_id, e.salary,
	ae.department_salary_expense,
	ROUND(e.salary/ae.department_salary_expense * 100, 2) pct_salary
FROM employees e JOIN (
	SELECT department_id,
		SUM(salary) AS department_salary_expense,
		ROUND(AVG(salary), 2) AS avg_salary_expense
	FROM employees
	GROUP BY department_id
) ae
ON e.department_id = ae.department_id
ORDER BY department_id, salary;


-- Rewrite with window functions
-- this method only allows partitioning by column
	-- matches specific value of column
SELECT TOP 10
	employee_id,
	department_id,
	salary, --individual employee salary
	SUM(salary) OVER (PARTITION BY department_id) total_dept_salary, --total salary for department
	AVG(salary) OVER (PARTITION BY department_id) avg_dept_salary, --average employee salary for department
	salary/SUM(salary) OVER (PARTITION BY department_id) pct_dept_salary --percentage
FROM employees;

USE retail_db;


-- Daily Revenue Table CTAS
SELECT
	o.order_date,
	CAST(SUM(oi.order_item_subtotal) AS DECIMAL(18,2)) revenue
INTO daily_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
WHERE o.order_status IN ('COMPLETED', 'CLOSED')
GROUP BY o.order_date;


-- Daily Product Revenue
SELECT
	o.order_date,
	oi.order_item_product_id,
	CAST(SUM(oi.order_item_subtotal) AS DECIMAL(18,2)) revenue
INTO daily_product_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
WHERE o.order_status IN ('COMPLETED', 'CLOSED')
GROUP BY o.order_date, oi.order_item_product_id;

SELECT TOP 10 * FROM daily_revenue;
SELECT TOP 10 * FROM daily_product_revenue
ORDER BY order_item_product_id;


-- Now we can analyze based off window functions
SELECT *,
	SUM(revenue) OVER (PARTITION BY order_date) total_daily_revenue,
	MIN(revenue) OVER (PARTITION BY order_date) min_daily_revenue,
	MAX(revenue) OVER (PARTITION BY order_date) max_daily_revenue
FROM daily_product_revenue
ORDER BY order_item_product_id, order_date;

SELECT *,
	SUM(revenue) OVER (PARTITION BY order_date) total_daily_revenue,
	MIN(revenue) OVER (PARTITION BY order_date) min_daily_revenue,
	MAX(revenue) OVER (PARTITION BY order_date) max_daily_revenue,
	AVG(revenue) OVER (PARTITION BY order_item_product_id) max_product_revenue
FROM daily_product_revenue
ORDER BY order_item_product_id, order_date;

-- Cumulative Aggregation vs Moving Aggregation

-- Cumulative Aggregation: Running Total
-- Moving Aggregation: Looks at a window of time
	--ie, avg sales over the last 7, 30, and 90 days

-- ROWS BETWEEN clause
	-- ROWS BETWEEN x AND y
	-- UNBOUNDED PROCEDING/UNBOUNDED FOLLOWING
	-- 3 PRECEDING/3 FOLLOWING
	-- CURRENT ROW

-- Compare each daily product revenue to avg for product over previous week

-- It will only take into account the data it has
	-- if 6 values don't exist, it only takes what's available
	-- would need to insert values for unaccounted for dates
SELECT *,
	AVG(revenue) OVER (PARTITION BY order_item_product_id
		ORDER BY order_date
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) last_wk_avg
FROM daily_product_revenue
ORDER BY order_item_product_id, order_date;

-- Compare current day revenue to total revenue so far
SELECT *,
	SUM(revenue) OVER (
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cumulative_total_rev -- don't need to partition because the dates in this column are unique
FROM daily_revenue;

-- Compare monthly revenue
SELECT *,
	SUM(revenue) OVER (
		PARTITION BY FORMAT(order_date, 'yyyy-MM') -- need to partition so all days in the month get grouped together
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) cumulative_monthly_rev -- sum is grouped, not date rows, so it resets rolling total for each month
FROM daily_revenue
ORDER BY order_date;



-- Avg revenue in a 5 day moving window
	-- see what current row looks like compared to 2 days befor and 2 days after

SELECT *,
	AVG(revenue) OVER (
		ORDER BY order_date
		ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
	) five_day_avg
FROM daily_revenue
ORDER BY order_date;

-- lead(col, #), lag(col, #), first_value(), last_value()
	-- must specify order

SELECT *,
	LAG(revenue, 1) OVER (ORDER BY order_date) prior_day_rev,
	LEAD(revenue, 1) OVER (ORDER BY order_date) next_day_rev
FROM daily_revenue;

SELECT *,
	FIRST_VALUE(order_date) OVER (
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) first_day,
	LAST_VALUE(order_date) OVER (
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) last_day
FROM daily_revenue;

-- View first and last day product was ordered
SELECT *,
	FIRST_VALUE(order_date) OVER (
		PARTITION BY order_item_product_id
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) first_day,
	LAST_VALUE(order_date) OVER (
		PARTITION BY order_item_product_id
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) last_day
FROM daily_product_revenue;

-- rank(), dense_rank(), row_number()

USE hr_db;

-- ranks based on column
	-- orderby desc so highest is ranked first
SELECT
	employee_id,
	first_name,
	last_name,
	department_id,
	salary,
	RANK() OVER(
		PARTITION BY department_id
		ORDER BY salary DESC
	) [Rank], -- skips values with ties (rank 1, 2, 2, 2, 5, 6)
	DENSE_RANK() OVER(
		PARTITION BY department_id
		ORDER BY salary DESC
	) [Dense Rank], -- does not skip ties (rank 1, 2, 2, 3, 3, 4, 5)
	ROW_NUMBER() OVER(
		PARTITION BY department_id
		ORDER BY salary DESC, last_name ASC
	) [Rank] -- eliminates ties via second order by
FROM employees;


-- order by is only scoped to function
SELECT
	employee_id,
	first_name,
	last_name,
	department_id,
	salary,
	RANK() OVER(
		PARTITION BY department_id
		ORDER BY salary DESC
	) [Rank], -- skips values with ties (rank 1, 2, 2, 2, 5, 6)
	DENSE_RANK() OVER(
		PARTITION BY department_id
		ORDER BY salary DESC
	) [Dense Rank], -- does not skip ties (rank 1, 2, 2, 3, 3, 4, 5)
	ROW_NUMBER() OVER(
		PARTITION BY department_id
		ORDER BY salary DESC, last_name ASC
	) [Rank] -- eliminates ties via second order by
FROM employees
ORDER BY department_id, salary DESC;



/*

ORDER OF OPERATIONS

When we write a query:
SELECT
FROM
JOIN - ON
WHERE
GROUP BY - HAVING
ORDER BY

SQL executes in order:
FROM
JOIN - ON
WHERE
GROUP BY - HAVING
SELECT
ORDER BY

*/

SELECT * FROM (
	SELECT
		employee_id,
		first_name,
		last_name,
		department_id,
		salary,
		RANK() OVER (
			PARTITION BY department_id
			ORDER BY salary DESC
		) [Rank]
	FROM employees
) nq
WHERE nq.[Rank] <= 5;

USE retail_db;

/*

Variables and Stored Proceedures

Variables are Local objects
- Exist only for the block they're in
- DECLARE @name <Type;
- Mainly used in Scripts and Procedures

Stored Procedures

Pros:
- Reduced server/client network traffic
- Stronger Security
- DRY code, reusable
- Easier Maintenance
- Improved Performance
	- Optimizes on first run

Types:
- System defined
- Temporary
- User defined
- Extended User defined
	- stored procdure imported form someone else

*/

DECLARE @MyNum DECIMAL(18,2);
DECLARE @FirstName VARCHAR(30), @LastName VARCHAR(30);

SET @MyNum = 11516.91;

SELECT * FROM daily_revenue
WHERE revenue = @MyNum
ORDER BY order_date;
GO


USE AdventureWorks2022;
GO

-- naming convention: usp (userstoredprocedure)
-- NVARCHAR(n) = N'string'
-- Name procedure, Declare variables, Setup what it does
CREATE PROCEDURE HumanResources.uspGetEmployeesTest
	@LastName NVARCHAR(50), -- variables need to match db
	@FirstName NVARCHAR(50)
AS
	SET NOCOUNT ON; -- turns off 'n rows affected' message, best practice to add
	SELECT FirstName, LastName, Department
	FROM HumanResources.vEmployeeDepartmentHistory
	WHERE FirstName = @FirstName AND LastName = @LastName
	AND EndDate IS NULL;
GO

-- Use Stored Procedures by using EXECUTE command (EXEC)
EXECUTE HumanResources.uspGetEmployeesTest N'Ackerman', N'Pilar';

-- OR
EXEC HumanResources.uspGetEmployeesTest @LastName=N'Ackerman', @FirstName=N'Pilar';

-- If keywords are specified (@keyword=value), order doesn't matter
-- OR
EXEC HumanResources.uspGetEmployeesTest @FirstName=N'Pilar', @LastName=N'Ackerman';

SELECT * FROM HumanResources.Employee;

EXEC uspGetEmployeeManagers 123;

/*

Triggers

-Events that fire when an event of type x happens

Types:
- LOGON
- DDL
- DML

LOGON: (happen on server)
- Fire in response LOGON event
- Happens after authentication but before session established
- Will not fire if authentication fails

DDL Trigger:
- Fires in response to DDL events
- CREATE, ALTER, DROP, GRANT, DENY, REVOKE, OR UPDATE STATICS
- Use Cases:
	- Saftey: prevent changes to schema changes
	- Automate actions in response to schema changes
	- Record database schema changes

DML Trigger:
- Fire in response to DML events
- INSERT, UPDATE, DELETE
- Use Cases:
	- Enforcing Data Integrety Policies
	- Query Tables
	- Complex T-SQL Satements

*/

USE demo;
GO

-- DDL Trigger (happen on database)
CREATE TRIGGER safety
ON DATABASE
FOR DROP_TABLE, ALTER_TABLE
AS
	PRINT 'You must disable Trigger "Safety" before dropping or altering tables.'
	ROLLBACK;
GO

DROP TABLE users;
GO


-- DML Trigger (happen on table)
CREATE TRIGGER getTable
ON users
AFTER INSERT, UPDATE, DELETE
AS
	SELECT * FROM users;
GO
	
INSERT INTO users (user_fname, user_lname, user_email_id)
VALUES ('Test', 'Bob', 'Bob@Test.com');
GO

-- Sequence
CREATE SCHEMA Test;
GO

CREATE SEQUENCE Test.CountBy1
	START WITH 1
	INCREMENT BY 1;
GO

CREATE SEQUENCE Test.TestSequence;
SELECT * FROM sys.sequences WHERE name = 'CountBy1';

SELECT NEXT VALUE FOR Test.CountBy1 AS FirstUse;
SELECT NEXT VALUE FOR Test.CountBy1 AS SecondUse;