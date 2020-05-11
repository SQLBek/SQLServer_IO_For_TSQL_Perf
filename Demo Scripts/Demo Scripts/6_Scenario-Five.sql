/*-------------------------------------------------------------------
-- 5 - Scenario #5
-- 
-- OPTIONAL
-- Summary: Just get IDs then go back and get everything else
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE AutoDealershipDemo
GO

-----
-- SETUP
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO








-----
-- Intro the example data
SELECT 
	ModelName, 
	COUNT(1) AS NumOfModels,
	SUM(COUNT(1)) OVER(PARTITION BY(SELECT NULL)) TotalNumOfRecords
FROM dbo.InventoryFlat
GROUP BY ModelName
ORDER BY ModelName;
GO

-- What indexes are on this table?
EXEC sp_SQLskills_helpindex 'dbo.InventoryFlat';
GO







-----
-- Example query
-- Ctrl-M: Turn on Actual Execution Plan
SELECT 
	InventoryFlatID, VIN,
	MakeName, ModelName, PackageName, ColorName, 
	TrueCost, InvoicePrice, MSRP, 
	DateReceived, Sold, SoldPrice
FROM dbo.InventoryFlat
WHERE ModelName = 'RAV4'
OPTION(MAXDOP 1);
GO



-- How much work does this query do?
-- Exec Plan: Index Operation Used?
-- Logical Reads: 
-- Execution Time:








-----
-- What if we split them up into multiple queries?
--
-- Let's retreive the IDs first, then run a second
-- query against the wide table to get all of the
-- other columns!








-----
-- 1. Create a temp table
CREATE TABLE #tmpIDs (
	tmpID INT PRIMARY KEY CLUSTERED
);


-- 2. Insert Clustering Key IDs into temp table
INSERT INTO #tmpIDs (
	tmpID
)
SELECT InventoryFlatID
FROM dbo.InventoryFlat
WHERE ModelName = 'RAV4';


-- 3. Query dbo.InventoryFlat to get data back
SELECT 
	InventoryFlatID, VIN,
	MakeName, ModelName, PackageName, ColorName, 
	TrueCost, InvoicePrice, MSRP, 
	DateReceived, Sold, SoldPrice
FROM dbo.InventoryFlat
INNER JOIN #tmpIDs
	ON #tmpIDs.tmpID = InventoryFlat.InventoryFlatID
OPTION(MAXDOP 1);
GO



-- How much work does this query do?
-- Exec Plan: Index Operation Used?
-- Logical Reads: 
-- Execution Time:








-----
-- EXISTS() instead of INNER JOIN
SELECT 
	InventoryFlatID, VIN,
	MakeName, ModelName, PackageName, ColorName, 
	TrueCost, InvoicePrice, MSRP, 
	DateReceived, Sold, SoldPrice
FROM dbo.InventoryFlat
WHERE EXISTS(
	SELECT 1
	FROM #tmpIDs
	WHERE #tmpIDs.tmpID = InventoryFlat.InventoryFlatID
)
OPTION(MAXDOP 1);
GO



-- How much work does this query do?
-- Exec Plan: Index Operation Used?
-- Logical Reads: 
-- Execution Time:








-----
-- Optional - Let's go parallel!
SELECT 
	InventoryFlatID, VIN,
	MakeName, ModelName, PackageName, ColorName, 
	TrueCost, InvoicePrice, MSRP, 
	DateReceived, Sold, SoldPrice
FROM dbo.InventoryFlat
WHERE ModelName = 'RAV4'
OPTION(MAXDOP 1);
GO

SELECT 
	InventoryFlatID, VIN,
	MakeName, ModelName, PackageName, ColorName, 
	TrueCost, InvoicePrice, MSRP, 
	DateReceived, Sold, SoldPrice
FROM dbo.InventoryFlat
WHERE ModelName = 'RAV4';
GO


SELECT 
	InventoryFlatID, VIN,
	MakeName, ModelName, PackageName, ColorName, 
	TrueCost, InvoicePrice, MSRP, 
	DateReceived, Sold, SoldPrice
FROM dbo.InventoryFlat
WHERE EXISTS(
	SELECT 1
	FROM #tmpIDs
	WHERE #tmpIDs.tmpID = InventoryFlat.InventoryFlatID
);
GO