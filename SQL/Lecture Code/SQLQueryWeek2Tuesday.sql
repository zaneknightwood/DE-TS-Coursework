/*
Multiline Comment
*/

-- Single Comment

/*
SQL Server Basics

SQL Syntax
- UPPERCASE = T-SQL Keyword
	- SELECT, UPDATE, DELETE, WHERE
	- Uppercase is not required (case insensitive), but is best practice
- italics = user defined parameter
- bold = Database object
- [] = Allows us to use spaces and special characters ([Movie Title])
	-Spaces not allowed, SQL reads as seperate commands
- ; = end line

Fully Qualified Name
[server].[database].[schema].[table]


*/


-- Fully Qualified Name (needs brackets due to dash in name)
SELECT * FROM [ZY-SURFACE].master.dbo.MSreplication_options;

-- We can leave off the server, cuz we're already connected
SELECT * FROM master.dbo.MSreplication_options;

-- We can leave off the database if we switch contexts
USE master;
SELECT * FROM dbo.MSreplication_options;

-- We can leave off the Schema if it's 'dbo'
SELECT * FROM MSreplication_options;

-- We can let the interpretor fill in the blanks with '.' (Not a great option, can get messy)
--SELECT * FROM [ZY-SURFACE]...MSreplication_options;

-- Batch Operations
-- End of the batch: GO
-- DDL - Create Tables
-- Employees and Departments
-- If Employees is dependant on Departments -> What would happen if Employee table got created first? -> Wouldn't work

/*CREATE Departments;
GO

CREATE Employees;
GO
*/


-- This doesn't define different Transactions. This is for scripting purposes.

/*

Other ways to interact with the server:

CLI(command line interface) - sqlcmd
Programmatically with a Programming language

JDBC

We can use Python with the pymssql library

*/

-- DML = Data Management Language (Changing, updating data)

/*

Database Operations
- DDL
	- CREATE/ALTER/DROP tables/views/sequences
- DML
	- INSERT/SELECT/DELETE/UPDATE
- TCL
	- COMMIT/ROLLBACK/BEGIN TRAN
	- Default: Auto-Commit
	- Transaction: Processes what is highlighted by default

*/

SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

/*

CRUD

CREATE -> INSERT INTO (doesn't create its own tables)
READ -> SELECT
UPDATE -> UPDATE
DELETE -> DELETE

*/


-- Creates a database and all the required files/folders
-- Need to refresh 'Databases' on left in order to see it
CREATE DATABASE demo;

use demo;

-- CREATE TABLE creates a table
-- By default it will put it into the dbo schema
-- We can put it into a diff schema, but we have to create it first

CREATE TABLE users (
    user_id int PRIMARY KEY IDENTITY, -- Identity is a surrogate key. Starts at 1 and counts up.
    user_first_name VARCHAR(30) NOT NULL,
    user_last_name VARCHAR(30) NOT NULL,
    user_email_id VARCHAR(50) NOT NULL,
    user_email_validated bit DEFAULT 0, -- bit = boolean (0 or 1)_
    user_password VARCHAR(200),
    user_role VARCHAR(30) NOT NULL DEFAULT 'U', --DEFAULT works like '=' (sets default value)
    is_active bit DEFAULT 0,
    last_updated_ts DATETIME DEFAULT getdate() -- gives the current date (UTC)
);

-- Typically our Applications will not perform the DDL Part, we will connect to already established dbs
--CRUD

--(C)REATE - INSERT
-- Syntax: INSERT INTO <table> (col1, col2, col3) VALUES (val1, val2, val3)

INSERT INTO users (user_first_name, user_last_name, user_email_id)
VALUES ('Scott', 'Tiger', 'scott@tiger.com');

INSERT INTO users (user_first_name, user_last_name, user_email_id)
VALUES ('Donald', 'Duck', 'donald@duck.com');

INSERT INTO users (user_first_name, user_last_name, user_email_id, user_role, is_active)
VALUES ('Mickey', 'Mouse', 'mickey@mouse.com', 'U', 1);

SELECT * FROM users;

-- Multiple inserts in same command
-- Faster on backend
-- All columns must have values! (maps 1-1)
INSERT INTO users
    (user_first_name, user_last_name, user_email_id, user_password, user_role, is_active)
VALUES
    ('Sora', 'Hearts', 'keyblade@master.com', '019he221', 'U', 1),
    ('Minnie', 'Mouse', 'minnie@mouse.com', 'fhuih1234', 'U', 1),
    ('Max', 'Goof', 'max@goof.com', 'j4892hyf1', 'U', 1);


-- (R)EAD - SELECT
-- SELECT <col1, col2, ..., coln> FROM <table> WHERE <condition>

SELECT user_first_name, user_last_name, user_email_id FROM users;

-- * -Wildcard operator
-- We don't use this much in big data (we only want to get relevent data, also if someone else is removing/changing data we have no way to know)
SELECT * FROM users WHERE is_active = 1;

-- T-SQL we can use TOP keyword (sql will NOT truncate output)
SELECT TOP 2 * FROM users WHERE is_active = 1;

-- (U)PDATE - UPDATE
-- Syntax: UPDATE <table> SET col1=val1, col2=val2 WHERE <condition>
-- If WHERE is left out, UPDATE will occur on every row
UPDATE users
SET
	user_role = 'A',
	user_email_validated = 1
WHERE is_active = 1;

SELECT * FROM users;

-- DDL
-- deletes entire table
DROP TABLE users;

-- (D)ELETE - DELETE
-- Syntax: DELETE FROM <table> WHERE <condition>
-- Best Practice: use TRUNCATE to empty table

DELETE FROM users WHERE user_password IS NULL; --NULL does NOT work with '=', must use 'IS' or 'IS NOT'

-- TCL Basics
BEGIN TRAN transaction1; -- works like a save point, earliest we can roll back

UPDATE users
SET user_email_id = upper(user_email_id)
WHERE user_first_name = 'Mickey';

SAVE TRAN savepoint;
UPDATE users
SET user_email_validated = 1;

ROLLBACK TRAN savepoint;
COMMIT;

-- Clean up after yourself
use master;
DROP DATABASE demo;

/*

DDL = Data Definition Language

DDL Scripts - .sql with table definitions, constraints, indexes, and views

Common Task
- CREATE TABLE
- Creating Indexes (performance)
- Altering tables (constraints)

Uncommon Tasks
- Adding a new column
- TRUNCATE tables (specialized use case, typically better to just drop table)
- Removing constraints

Avoids
- Removing Columns
	- Create a new column and tell applications to switch over on their own
- Changing data types
	- Exception: Natural conversions (INT -> BIGINT)

*/

CREATE DATABASE demo;
GO

USE demo;
GO

CREATE TABLE users (
    user_id int PRIMARY KEY IDENTITY,
    user_first_name VARCHAR(30) NOT NULL,
    user_last_name VARCHAR(30) NOT NULL,
    user_email_id VARCHAR(50) NOT NULL,
    user_email_validated bit DEFAULT 0,
    user_password VARCHAR(200),
    user_role VARCHAR(30) NOT NULL DEFAULT 'U',
    is_active bit DEFAULT 0,
    last_updated_ts DATETIME DEFAULT getdate()
);

-- Document our Database objects
-- Create a Table Comment

-- Extended property (SQL Server specific)
-- Level0: schema, level1: table, level2: column
EXEC sp_addextendedproperty
@name = 'Description',
@value = 'This is my table comment',
@level0type = N'Schema', @level0name='dbo',
@level1type = N'Table', @level1name='users'

-- Add a comment to the user_role column
EXEC sp_addextendedproperty
@name = 'User Roles',
@value = 'Valid values are U and A',
@level0type = N'Schema', @level0name='dbo',
@level1type = N'Table', @level1name='users',
@level2type = N'Column', @level2name = 'user_role'

-- OR right click on table, go to properties, to add table comments

/* 

Data types

INT
VARCHAR
BIGINT
bit
DATETIME


Exact Numerics
- BIGINT - 8 Bytes
- INT - 4 Bytes
- SMALLINT - 2 Bytes
- TINYINT - 1 Byte
- NUMERIC/DECIMAL (precision, scale): NUMERIC(5,2) -> 151.24 (5 total digits, 2 after decimal)
- MONEY (Specify default currency)

Approximate Numerics
- FLOAT(n) - n is number of bits for the mantisswa(front part, 1.234) of the float for scientific notation (1.234 * 10^5)

Date and Time
- DATE - YYYY-MM-DD format, 0001-9999
- TIME - no timezone - hh:mm:ss.nnnnnnn
- DATETIME - YYYY-MM-DD hh:mm:ss.mmmm
- DATETIME2 - YYYY-MM-DD hh:mm:ss.nnnnnnn
- DATETIMEOFFSET - DATETIME2 + Timezone from UTC

Strings
- CHAR(n) - Fixed length string, must be exact -> CHAR(5) 'XXXXX'
- VARCHAR(n) - Variable length string -> n = number of bytes (default, 1 character = 1 byte)
- Text - deprecated

- COLLATION = Default character encoding + extra stuff for database
	- Our Default collation, 1 char = 1 byte
	- If 1 char = 4 byter, VARCHAR(40) -> 10 characters

Binary String
- (VAR)BINARY - binary string
- IMAGE (2^31 -1) ~2.1 GB
	- Most other dbs call this a BLOB (binary large object)
	- Common Design Pattern: store a reference to the image file/url

Other Types
- SPATIAL GEOGRAPHY TYPES -> pyshical, where you are in the world
- SPATIAL GEOMETRY TYPES -> shapes
- HIERARCHYID
- XML

Not a Type in T-SQL: JSON
	- We store JSON in a VARCHAR(n) + System stored procedure
*/

/*

CONSTRAINTS

- NOT NULL
- CHECK <condition>
- DEFAULT
- UNIQUE
	- Composite Columns also unique - UNIQUE(full_name, email)
- PRIMARY KEY
	- UNIQUE, NOT NULL
	- 1 per table (multiple columns can be composite key)
	- Surrogate Key (Artificial Key)
		-IDENTITY(start, increment)
	- Creates a Clustered Index (rows are physically sorted based on that index)
- FOREIGN KEY
	- Establish links between tables
	- Most often references other PKs
		- Can reference any UNIQUE column
	- Must reference the same db
	- Doesn't automatically create an index (it is recommended)
	- Referential integrity
		- Cannot delete data that is referenced by a foreign key
		- Cascading RI
			- Action that is taken when a user tries to delete/update a referenced field
				- NO ACTION -> it rejects and sends an error (default)
				- CASCADE -> FK Update/delete corresponding referenced rows
					-Very dangerous
				- SET DEFAULT -> Update the FK to the default value

*/
DROP TABLE users;

-- Define all of our constraints at the end of the CREATE TABLE Statement
-- Allows us to name our constraints
CREATE TABLE users (
    user_id int IDENTITY,
    user_first_name VARCHAR(30) NOT NULL,
    user_last_name VARCHAR(30) NOT NULL,
    user_email_id VARCHAR(50) NOT NULL,
    user_email_validated bit DEFAULT 0,
    user_password VARCHAR(200),
    user_role VARCHAR(30) NOT NULL DEFAULT 'U',
    is_active bit DEFAULT 0,
    last_updated_ts DATETIME DEFAULT getdate(),
	CONSTRAINT pk_users_user_id PRIMARY KEY CLUSTERED (user_id)
);

-- Add it afterwards
-- Preffered way with DDL Scripts
CREATE TABLE users (
    user_id int IDENTITY,
    user_first_name VARCHAR(30) NOT NULL,
    user_last_name VARCHAR(30) NOT NULL,
    user_email_id VARCHAR(50) NOT NULL,
    user_email_validated bit DEFAULT 0,
    user_password VARCHAR(200),
    user_role VARCHAR(30) NOT NULL DEFAULT 'U',
    is_active bit DEFAULT 0,
    last_updated_ts DATETIME DEFAULT getdate(),
);

ALTER TABLE users
ADD CONSTRAINT pk_users_user_id PRIMARY KEY CLUSTERED (user_id);

/*
Loading and Dumping Data

Loading Data
- .sql
- Data files (CSV, Parquet, JSON)
	- Structured data
- Backup File (.bak)

Backups
- Data
- Transaction Log
	- Logs every COMMIT
	- Allows recreation of Transactions
- Uses
	- Restoration and Recovery
	- Migrate/export data
	- Production system has primary node (writer) and secondary nodes (read replicas)
		- read replicas can be promoted to writers if writer goes down

Recovery Models
- Full
	- Representative of the database and all data at the time of backup
	- Expensive
	- Can take a long time to complete
- Differential Backup
	- Contains the changes since the last backup
	- Run the full backup and then all differentials in sequence
	- Common Strategy: Full backup during off hours (1:00-3:00AM), Diff backup every 6 hours or so
	- Production Environments typically run multiple copies of the db concurrently with Diff backup running at different times for each
- Logs
	- Backup the transaction logs since last full backup
	- Replay every transaction in the log
- Data
	- Export the tables as files
	- Just keep the data files

Restore/Recovery
- Multi-phase process that copies the data and logs then rolls forward all transactions
- Types
	- Full
	- Incremental
	- Manual
*/


-- Backup
-- Also possible via: rt clk DB, choose Tasks, choose Backup, clk ok
-- Mssql only has permission to write to backup folder! Must be here!
BACKUP DATABASE demo
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\demo.bak';

-- Import flat flile
	-- rt clk DB, choose Tasks, choose Import flatfile
-- Import files via gitbash:
	-- Use sqlcmd
		-- open folder location in gitbash terminal
		-- $ sqlcmd -S localhost -i [filename]

-- Create via backup
-- Rt clk Databases, choose Restore Database, choose db to restore, clk ok

RESTORE DATABASE[demo]
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\demo.bak';



