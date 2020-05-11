/*-------------------------------------------------------------------
-- 3 - Scenario #2
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE AutoDealershipDemo
GO

-----
-- SETUP
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Customer_State_Demo')
	CREATE NONCLUSTERED INDEX IX_Customer_State_Demo ON Customer (
		State
	);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesHistory_Covering')
	CREATE NONCLUSTERED INDEX IX_SalesHistory_Covering ON SalesHistory (
		TransactionDate
	)
	INCLUDE (
		CustomerID, SellPrice, InventoryID
	);
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO








-----
-- Example
-- Ctrl-M: Turn on Actual Execution Plan
DECLARE 
	@TransactionDateStart DATETIME = '2018-01-01',
	@TransactionDateEnd DATETIME = '2019-02-01',
	@State NCHAR(2) = 'IL';

SELECT 
	Customer.State,
	AVG(SalesHistory.SellPrice)
FROM dbo.Inventory
INNER JOIN dbo.SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE TransactionDate >= @TransactionDateStart
	AND TransactionDate < @TransactionDateEnd
	AND Customer.State = @State
GROUP BY 
	Customer.State
OPTION(MAXDOP 1);
GO








-- What's changed?
DECLARE 
	@TransactionDateStart DATETIME = '2018-01-01',
	@TransactionDateEnd DATETIME = '2019-02-01',
	@State CHAR(2) = 'IL';

SELECT 
	Customer.State,
	AVG(SalesHistory.SellPrice)
FROM dbo.Inventory
INNER JOIN dbo.SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE TransactionDate >= @TransactionDateStart
	AND TransactionDate < @TransactionDateEnd
	AND Customer.State = @State
GROUP BY 
	Customer.State
OPTION(MAXDOP 1);
GO








-----
-- Finding Implicit Column Conversions in the Plan Cache
-- Jonathan Kehayias
-- https://www.sqlskills.com/blogs/jonathan/finding-implicit-column-conversions-in-the-plan-cache/

-- Ctrl-M: Turn off Actual Execution Plan
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO


DECLARE @dbname SYSNAME 
SET @dbname = QUOTENAME(DB_NAME());

WITH XMLNAMESPACES (
	DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
) 
SELECT 
	stmt.value('(@StatementText)[1]', 'varchar(max)'), 
	t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)'), 
	t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)'), 
	t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)'), 
	ic.DATA_TYPE AS ConvertFrom, 
	ic.CHARACTER_MAXIMUM_LENGTH AS ConvertFromLength, 
	t.value('(@DataType)[1]', 'varchar(128)') AS ConvertTo, 
	t.value('(@Length)[1]', 'int') AS ConvertToLength, 
	query_plan 
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
CROSS APPLY stmt.nodes('.//Convert[@Implicit="1"]') AS n(t) 
INNER JOIN INFORMATION_SCHEMA.COLUMNS AS ic 
	ON QUOTENAME(ic.TABLE_SCHEMA) = t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)') 
	AND QUOTENAME(ic.TABLE_NAME) = t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)') 
	AND ic.COLUMN_NAME = t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)') 
WHERE t.exist('ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1;
GO








-----
-- Clean up
DROP INDEX Customer.IX_Customer_State_Demo
GO
DROP INDEX SalesHistory.IX_SalesHistory_Covering
GO
