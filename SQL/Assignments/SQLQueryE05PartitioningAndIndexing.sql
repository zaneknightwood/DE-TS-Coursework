-- Exercises - Partitioning Tables
USE retail_db;

-- Exercise 1

SELECT * INTO orders_part FROM orders
WHERE 1=2
;

CREATE PARTITION FUNCTION monthRange (DATETIME2(0))
	AS RANGE RIGHT FOR VALUES (

CREATE PARTITION FUNCTION myRangePF1 (DATETIME2(0))
	AS RANGE RIGHT FOR VALUES ('2022-04-01', '2022-05-01', '2022-06-01') -- first part will be all values before 4-1, then 4-1 to 4-30, then 5-1 to 6-31, then 6-1 to end
GO

SELECT * FROM orders ORDER BY order_date;

2013-7-25 to 2014-7-24

DECLARE @DatePartitionFunction nvarchar(max) = 
    N'CREATE PARTITION FUNCTION DatePartitionFunction (datetime2) 
    AS RANGE RIGHT FOR VALUES (';  
DECLARE @i datetime2 = '20130101';  
WHILE @i < '20150101'  
BEGIN  
SET @DatePartitionFunction += '''' + CAST(@i as nvarchar(10)) + '''' + N', ';  
SET @i = DATEADD(MM, 1, @i);  
END  
SET @DatePartitionFunction += '''' + CAST(@i as nvarchar(10))+ '''' + N');';  
EXEC sp_executesql @DatePartitionFunction;  
GO  