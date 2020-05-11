USE AutoDealershipDemo
GO

/*******************************************************
*** 1. RUN RESET 
*** 2. TURN ON SENTRYONE
*** 3. EXECUTE THIS WORKLOAD
-- Execute in a new window
EXEC AutoDealershipDemo.Workload.sp_RandomVINLookupBatch
GO 1000
*******************************************************/

EXEC dbo.sp_DropAllNCIs @PrintOnly = 0, @RestoreBaseNCIs = 0;

---- Reset indexes
--IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_InventoryFlat_DateReceived_VIN')
--	DROP INDEX InventoryFlat.IX_InventoryFlat_DateReceived_VIN
--GO
--IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesHistory_InventoryID')
--	DROP INDEX SalesHistory.IX_SalesHistory_InventoryID
--GO
--IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesHistory_InventoryID_Covering')
--	DROP INDEX SalesHistory.IX_SalesHistory_InventoryID_Covering
--GO
--IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_Inventory_VIN_Covering')
--	DROP INDEX Inventory.IX_Inventory_VIN_Covering
--GO
--IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_Customer_State')
--	DROP INDEX Customer.IX_Customer_State
--GO

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

-----
-- dbo.Inventory
-- Should only have: IX_Inventory_DateReceived & IX_Inventory_VIN


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



-----
-- dbo.SalesHistory
-- Should only have: IX_SalesHistory_TransactionDate 

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


DROP INDEX SalesHistory.IX_SalesHistory_InventoryID
GO
CREATE NONCLUSTERED INDEX IX_SalesHistory_InventoryID ON dbo.SalesHistory (InventoryID) INCLUDE (SellPrice)
GO

-----
-- SETUP for Scenario One
-- IX_Inventory_VIN should be enabled!
/* IX_SalesHistory_InventoryID may not exist OR may be DISABLED - verify */
-- CREATE NONCLUSTERED INDEX IX_SalesHistory_InventoryID ON dbo.SalesHistory (InventoryID) INCLUDE (SellPrice)
-- ALTER INDEX IX_SalesHistory_InventoryID ON dbo.SalesHistory REBUILD
-- GO

-- Need this for range scan example
CREATE NONCLUSTERED INDEX IX_InventoryFlat_SoldPrice
	ON dbo.InventoryFlat (
		SoldPrice
	);


-- Used for Scenario-Five
CREATE NONCLUSTERED INDEX IX_InventoryFlat_ModelName_Demo
	ON dbo.InventoryFlat (
		ModelName
	)
	INCLUDE (
		VIN, InventoryFlatID
	);


EXEC sp_configure N'show advanced options', 1
RECONFIGURE
GO

EXEC dbo.sp_DropAllNCIs @PrintOnly = 1;
