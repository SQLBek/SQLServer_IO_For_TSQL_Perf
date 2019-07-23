/*-------------------------------------------------------------------
-- 1 - Overview
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE AutoDealershipDemo;
GO




-----
-- Ctrl-M: Turn on Actual Execution Plan
SET STATISTICS IO ON
GO
DBCC DROPCLEANBUFFERS;
GO








-----
-- Read with cold cache
SELECT TOP 100000 *
FROM dbo.InventoryFlat;
GO


-- Observations? 
-- Exec Plan: ?
-- Messages: ?








-----
-- Repeat
SELECT TOP 100000 *
FROM dbo.InventoryFlat;
GO


-- Observations? 
-- Exec Plan: ?
-- Messages: ?








-----
-- What is in the Buffer Pool?
-- Ctrl-M: Turn off Actual Execution Plan
SELECT 
	(COUNT(1) * 8) / 1024.0 AS 'Cached Size (MB)',
	CASE database_id
        WHEN 32767 THEN 'ResourceDb'
        ELSE db_name(database_id)
	END AS 'Database'
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id), database_id
ORDER BY 'Cached Size (MB)' DESC
GO




-----
-- Flush the buffer pool
DBCC DROPCLEANBUFFERS;
GO


-- What is in the Buffer Pool?
SELECT 
	(COUNT(1) * 8) / 1024.0 AS 'Cached Size (MB)',
	CASE database_id
        WHEN 32767 THEN 'ResourceDb'
        ELSE db_name(database_id)
	END AS 'Database'
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id), database_id
ORDER BY 'Cached Size (MB)' DESC
GO








-----
-- Mixed JOIN example
DBCC DROPCLEANBUFFERS;
GO


-- Read with cold cache
SELECT TOP 100000 *
FROM dbo.SalesHistory
INNER JOIN dbo.Customer		-- TABLE DIFFERENT
	ON SalesHistory.CustomerID = Customer.CustomerID
ORDER BY SalesHistoryID;
GO

-- Repeat
SELECT TOP 100000 *
FROM dbo.SalesHistory
INNER JOIN dbo.Inventory	-- TABLE DIFFERENT
	ON Inventory.InventoryID = SalesHistory.InventoryID
ORDER BY SalesHistoryID;
GO








-----
-- Explore Query Operations
-- Ctrl-M: Turn on Actual Execution Plan
SET STATISTICS IO ON
GO








-----
-- Heap vs Clustered Index
SELECT 
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
FROM dbo.SalesSummaryHeap;
GO


SELECT 
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
FROM dbo.SalesSummary;
GO








-----
-- One record or page?
SELECT TOP 1
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
FROM dbo.SalesSummaryHeap;
GO


SELECT TOP 1
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
FROM dbo.SalesSummary;
GO




-----
-- Variation
SELECT 
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
FROM dbo.SalesSummaryHeap
WHERE VIN = 'JT29LWW999E389334';
GO


SELECT 
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
FROM dbo.SalesSummary
WHERE VIN = 'JT29LWW999E389334';
GO




-- Ctrl-M: Turn off actual execution plan
EXEC sp_help 'dbo.SalesSummary';


EXEC sp_help 'dbo.SalesSummaryHeap';








-----
-- Range Scan example
-- Ctrl-M: Turn on actual execution plan
SELECT SoldPrice
FROM dbo.InventoryFlat
WHERE SoldPrice BETWEEN 30000 AND 31999
OPTION(MAXDOP 1)
GO 





-- Variation
SELECT SoldPrice
FROM dbo.InventoryFlat
WHERE SoldPrice BETWEEN 30000 AND 31999
ORDER BY SoldPrice DESC
OPTION(MAXDOP 1)
GO 








-----
-- Multi-Seek Example
-- Ctrl-M: Turn on actual execution plan
SELECT 
	Customer.State,
	AVG(SalesHistory.SellPrice)
FROM dbo.SalesHistory
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE Customer.State IN ('IL', 'IN', 'WI', 'IA')
GROUP BY 
	Customer.State
ORDER BY 
	Customer.State
OPTION(MAXDOP 1)
GO




-----
-- Create an index to support this query!
-- DROP INDEX Customer.IX_Customer_State
CREATE NONCLUSTERED INDEX IX_Customer_State ON dbo.Customer (State)
GO


-- Repeat
SELECT 
	Customer.State,
	AVG(SalesHistory.SellPrice)
FROM dbo.SalesHistory
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE Customer.State IN ('IL', 'IN', 'WI', 'IA')
GROUP BY 
	Customer.State
ORDER BY 
	Customer.State
OPTION(MAXDOP 1)
GO








-----
-- Just one state
SELECT 
	Customer.State,
	AVG(SalesHistory.SellPrice)
FROM dbo.SalesHistory
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE Customer.State = 'IL'
GROUP BY 
	Customer.State
ORDER BY 
	Customer.State
OPTION(MAXDOP 1);
GO








-----
-- All fifty states!
SELECT 
	Customer.State,
	AVG(SalesHistory.SellPrice)
FROM dbo.SalesHistory
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE Customer.State IN (
	'AK','AL','AR','AZ','CA','CO','CT','DE','FL','GA','HI','IA','ID',
	'IL','IN','KS','KY','LA','MA','MD','ME','MI','MN','MO','MS','MT',
	'NC','ND','NE','NH','NJ','NM','NV','NY','OH','OK','OR','PA','RI',
	'SC','SD','TN','TX','UT','VA','VT','WA','WI','WV','WY'
)
GROUP BY 
	Customer.State
ORDER BY 
	Customer.State
OPTION(MAXDOP 1);
GO


-- Compare I/O with base query only
SELECT State
FROM dbo.Customer;
GO




-----
-- Clean up
DROP INDEX Customer.IX_Customer_State;
GO








------
-- Multi-Seek Variation
SELECT TOP 100000 *
FROM dbo.SalesHistory
INNER JOIN dbo.Inventory
	ON Inventory.InventoryID = SalesHistory.InventoryID
ORDER BY SalesHistoryID;
GO









------------------------------
-- OPTIONAL
-- Does read-ahead help?
------------------------------
SET STATISTICS TIME ON
GO
DBCC DROPCLEANBUFFERS;
GO


-- Disable sequential read-ahead
DBCC TRACEON (652);
GO
SELECT VIN, MakeName, ModelName, PackageName, ColorName
FROM dbo.InventoryFlat
WHERE DateReceived > '2016-01-01'
OPTION(MAXDOP 1);
PRINT '--'
GO
DBCC TRACEOFF (652);
GO


-- With sequential read-ahead
DBCC DROPCLEANBUFFERS;
GO
PRINT '--'
SELECT VIN, MakeName, ModelName, PackageName, ColorName
FROM dbo.InventoryFlat
WHERE DateReceived > '2016-01-01'
OPTION(MAXDOP 1);
GO




-- Disable random pre-fetch
DBCC DROPCLEANBUFFERS;
GO
DBCC TRACEON (8744);
GO
SELECT VIN, MakeName, ModelName, PackageName, ColorName
FROM dbo.InventoryFlatNVarchar
WHERE InventoryFlatNVarchar.VIN IN (
	SELECT VIN
	FROM Inventory
)
OPTION(MAXDOP 1, LOOP JOIN, RECOMPILE);
PRINT '--'
GO
DBCC TRACEOFF (8744);
GO


-- With random pre-fetch
DBCC DROPCLEANBUFFERS;
GO
PRINT '--'
SELECT VIN, MakeName, ModelName, PackageName, ColorName
FROM dbo.InventoryFlatNVarchar
WHERE InventoryFlatNVarchar.VIN IN (
	SELECT VIN
	FROM Inventory
)
OPTION(MAXDOP 1, LOOP JOIN, RECOMPILE);
GO

