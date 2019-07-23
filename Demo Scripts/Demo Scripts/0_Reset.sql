USE AutoDealershipDemo
GO

/*******************************************************
*** TURN ON SENTRYONE
*** EXECUTE THIS WORKLOAD
-- Execute in a new window
EXEC AutoDealershipDemo.Workload.sp_RandomVINLookupBatch
GO 1000
*******************************************************/




EXEC sp_configure N'show advanced options', 1
RECONFIGURE
GO

-- Reset indexes
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_InventoryFlat_DateReceived_VIN')
	DROP INDEX InventoryFlat.IX_InventoryFlat_DateReceived_VIN
GO
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesHistory_InventoryID')
	DROP INDEX SalesHistory.IX_SalesHistory_InventoryID
GO
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesHistory_InventoryID_Covering')
	DROP INDEX SalesHistory.IX_SalesHistory_InventoryID_Covering
GO
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_Inventory_VIN_Covering')
	DROP INDEX Inventory.IX_Inventory_VIN_Covering
GO
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_Customer_State')
	DROP INDEX Customer.IX_Customer_State
GO
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_Inventory_VIN')
	ALTER INDEX [IX_Inventory_VIN] ON [dbo].[Inventory] DISABLE
GO

-----
-- Populate SalesSummary & SalesSummaryHeap
TRUNCATE TABLE dbo.SalesSummaryHeap;
TRUNCATE TABLE dbo.SalesSummary;

INSERT INTO dbo.SalesSummaryHeap (
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
)
SELECT TOP 500000
	Inventory.VIN,
	Inventory.InvoicePrice,
	SalesHistory.SellPrice,
	SalesHistory.TransactionDate
FROM dbo.Inventory
INNER JOIN dbo.SalesHistory
	ON Inventory.InventoryID = SalesHistory.InventoryID


INSERT INTO dbo.SalesSummary (
	VIN,
	InvoicePrice,
	SellPrice,
	TransactionDate
)
SELECT TOP 500000
	Inventory.VIN,
	Inventory.InvoicePrice,
	SalesHistory.SellPrice,
	SalesHistory.TransactionDate
FROM dbo.Inventory
INNER JOIN dbo.SalesHistory
	ON Inventory.InventoryID = SalesHistory.InventoryID

GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesSummary_TransDate')
	CREATE NONCLUSTERED INDEX IX_SalesSummary_TransDate ON SalesSummary (TransactionDate)
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesSummaryHeap_TransDate')
	CREATE NONCLUSTERED INDEX IX_SalesSummaryHeap_TransDate ON SalesSummaryHeap (TransactionDate)
GO

-----
-- INDEX RESETS

-----
-- dbo.Customer
-- Should be no non-clustered indexes on Customer
-- Quick Reset -> remove all NCL's from Customer
DECLARE @SQLCmd NVARCHAR(4000);
DECLARE rsExe CURSOR FAST_FORWARD FOR 
	SELECT 'DROP INDEX Customer.' + name + ';' AS SQLCmd
	FROM sys.indexes
	WHERE indexes.object_id = OBJECT_ID(N'dbo.Customer')
		AND indexes.type = 2	-- Nonclustered Indexes
		AND indexes.is_primary_key = 0

OPEN rsExe

FETCH NEXT 
	FROM rsExe INTO @SQLCmd 

WHILE @@FETCH_STATUS = 0
	BEGIN
	-- Do Stuff
	EXEC sp_executesql @SQLCmd 

	FETCH NEXT 
 		FROM rsExe INTO @SQLCmd 
	END  
CLOSE rsExe
DEALLOCATE rsExe
GO

-----
-- dbo.Inventory
-- Should only have: IX_Inventory_DateReceived & IX_Inventory_VIN (disabled)
DECLARE @SQLCmd NVARCHAR(4000);
DECLARE rsExe CURSOR FAST_FORWARD FOR 
	SELECT 'DROP INDEX Inventory.' + name + ';' AS SQLCmd
	FROM sys.indexes
	WHERE indexes.object_id = OBJECT_ID(N'dbo.Inventory')
		AND indexes.type = 2	-- Nonclustered Indexes
		AND indexes.is_primary_key = 0

OPEN rsExe

FETCH NEXT 
	FROM rsExe INTO @SQLCmd 

WHILE @@FETCH_STATUS = 0
	BEGIN
	-- Do Stuff
	EXEC sp_executesql @SQLCmd 

	FETCH NEXT 
 		FROM rsExe INTO @SQLCmd 
	END  
CLOSE rsExe
DEALLOCATE rsExe
GO
/****** Object:  Index [IX_Inventory_DateReceived]    Script Date: 7/14/2019 5:22:50 PM ******/
CREATE NONCLUSTERED INDEX [IX_Inventory_DateReceived] ON [dbo].[Inventory]
(
	[InventoryID] ASC,
	[DateReceived] ASC
)
INCLUDE([VIN],[MSRP],[TrueCost]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
USE [AutoDealershipDemo]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Inventory_VIN]    Script Date: 7/14/2019 5:23:01 PM ******/
CREATE NONCLUSTERED INDEX [IX_Inventory_VIN] ON [dbo].[Inventory]
(
	[VIN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 75) ON [PRIMARY]
GO

ALTER INDEX [IX_Inventory_VIN] ON [dbo].[Inventory] DISABLE
GO



-----
-- dbo.SalesHistory
-- Should only have: IX_SalesHistory_TransactionDate 
-- DISABLED: IX_SalesHistory_CustomerID, IX_SalesHistory_InventoryID, IX_SalesHistory_SalesPersonID
DECLARE @SQLCmd NVARCHAR(4000);
DECLARE rsExe CURSOR FAST_FORWARD FOR 
	SELECT 'DROP INDEX SalesHistory.' + name + ';' AS SQLCmd
	FROM sys.indexes
	WHERE indexes.object_id = OBJECT_ID(N'dbo.SalesHistory')
		AND indexes.type = 2	-- Nonclustered Indexes
		AND indexes.is_primary_key = 0

OPEN rsExe

FETCH NEXT 
	FROM rsExe INTO @SQLCmd 

WHILE @@FETCH_STATUS = 0
	BEGIN
	-- Do Stuff
	EXEC sp_executesql @SQLCmd 

	FETCH NEXT 
 		FROM rsExe INTO @SQLCmd 
	END  
CLOSE rsExe
DEALLOCATE rsExe
GO

USE [AutoDealershipDemo]
GO

/****** Object:  Index [IX_SalesHistory_CustomerID]    Script Date: 7/14/2019 5:26:22 PM ******/
CREATE NONCLUSTERED INDEX [IX_SalesHistory_CustomerID] ON [dbo].[SalesHistory]
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 75) ON [PRIMARY]
GO

ALTER INDEX [IX_SalesHistory_CustomerID] ON [dbo].[SalesHistory] DISABLE
GO

USE [AutoDealershipDemo]
GO

/****** Object:  Index [IX_SalesHistory_InventoryID]    Script Date: 7/14/2019 5:26:29 PM ******/
CREATE NONCLUSTERED INDEX [IX_SalesHistory_InventoryID] ON [dbo].[SalesHistory]
(
	[InventoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 75) ON [PRIMARY]
GO

ALTER INDEX [IX_SalesHistory_InventoryID] ON [dbo].[SalesHistory] DISABLE
GO

USE [AutoDealershipDemo]
GO

/****** Object:  Index [IX_SalesHistory_SalesPersonID]    Script Date: 7/14/2019 5:26:35 PM ******/
CREATE NONCLUSTERED INDEX [IX_SalesHistory_SalesPersonID] ON [dbo].[SalesHistory]
(
	[SalesPersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 75) ON [PRIMARY]
GO

ALTER INDEX [IX_SalesHistory_SalesPersonID] ON [dbo].[SalesHistory] DISABLE
GO

USE [AutoDealershipDemo]
GO

/****** Object:  Index [IX_SalesHistory_TransactionDate]    Script Date: 7/14/2019 5:26:41 PM ******/
CREATE NONCLUSTERED INDEX [IX_SalesHistory_TransactionDate] ON [dbo].[SalesHistory]
(
	[TransactionDate] ASC
)
INCLUDE([CustomerID],[InventoryID],[SalesPersonID],[SellPrice]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


DROP INDEX Inventory.IX_Inventory_VIN
GO
CREATE NONCLUSTERED INDEX IX_Inventory_VIN ON dbo.Inventory (VIN)


DROP INDEX SalesHistory.IX_SalesHistory_InventoryID
GO
CREATE NONCLUSTERED INDEX IX_SalesHistory_InventoryID ON dbo.SalesHistory (InventoryID) INCLUDE (SellPrice)
GO
