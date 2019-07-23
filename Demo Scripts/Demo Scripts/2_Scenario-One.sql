/*-------------------------------------------------------------------
-- 2 - Scenario #1
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE AutoDealershipDemo
GO

-----
-- SETUP
/* IX_Inventory_VIN may not exist OR may be DISABLED - verify */
-- CREATE NONCLUSTERED INDEX IX_Inventory_VIN ON dbo.Inventory (VIN)
--ALTER INDEX IX_Inventory_VIN ON dbo.Inventory REBUILD
--GO
/* IX_SalesHistory_InventoryID may not exist OR may be DISABLED - verify */
-- CREATE NONCLUSTERED INDEX IX_SalesHistory_InventoryID ON dbo.SalesHistory (InventoryID) INCLUDE (SellPrice)
--ALTER INDEX IX_SalesHistory_InventoryID ON dbo.SalesHistory REBUILD
--GO


-- Ctrl-M: Turn on Actual Execution Plan
SET STATISTICS IO ON








-----
-- Example #1
SELECT 
	Inventory.VIN,
	Inventory.InvoicePrice,
	Inventory.MSRP,
	Inventory.TrueCost,
	SalesHistory.SellPrice,
	Customer.State,
	Inventory.DateReceived
FROM dbo.Inventory
INNER JOIN dbo.SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE VIN IN ('JT2SN8PSS9E314550')
GO








-----
-- What about multiple VINs?
SELECT 
	Inventory.VIN,
	Inventory.InvoicePrice,
	Inventory.MSRP,
	Inventory.TrueCost,
	SalesHistory.SellPrice,
	Customer.State,
	Inventory.DateReceived
FROM dbo.Inventory
INNER JOIN dbo.SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID
INNER JOIN dbo.Customer
	ON SalesHistory.CustomerID = Customer.CustomerID
WHERE VIN IN (
	'JT2AXNPAA9E369804','JT2C8JGCC9E368936','JT2DCOLDD9E313115','JT223I0229E357472','JT2WFWSWW9E383098',
	'JT2YLTBYY9E377103','JT2OCILOO9E394364','JT2XDG6XX9E327368','JT222GM229E394746','JT27P43779E311577',
	'JT26421669E369496','JT21ECS119E349766','JT2254G229E396119','JT20F5H009E327398','JT21W8C119E363436',
	'JT23CS0339E347868','JT24SM4449E321041','JT26AWH669E343585','JT27Q7O779E339372','JT298QI999E317532',
	'JT2AOXJAA9E383768','JT28DKX889E322948','JT29UBE999E388316','JT2BBJNBB9E384676','JT2CRBLCC9E372959',
	'JT2HAZ7HH9E340741','JT2K9LAKK9E335699','JT2KR4MKK9E394358','JT2CRB5CC9E314213','JT245CM449E378975',
	'JT2AJLMAA9E331828','JT2DIAZDD9E349741','JT2GH1OGG9E304901','JT2JECFJJ9E336631','JT2MBF9MM9E367214',
	'JT2P9HVPP9E371455','JT2SB66SS9E338757','JT2WQ22WW9E377987','JT20RJ2009E369032','JT23R6W339E367740',
	'JT26QJD669E384920','JT222T3229E308999','JT251RY559E368806','JT280G3889E319176','JT2AXQFAA9E355199',
	'JT2T1CQTT9E393155','JT2XGMVXX9E310362','JT21AEN119E379785','JT248U2449E397126','JT2768F779E315383',
	'JT2OX79OO9E370407','JT2RTK7RR9E340289','JT2N8ECNN9E384837','JT2Q6VVQQ9E360002','JT2TRAOTT9E362651'
)
OPTION(MAXDOP 1);
GO 

-- Logical reads:








-----
-- Add covering indexes
-- Let's see what indexes already exist
EXEC sp_helpindex 'dbo.Inventory';








-- Or even better!  Thanks Kimberly Tripp!
EXEC sp_SQLskills_helpindex 'dbo.Inventory';








-----
-- Create our indexes
CREATE NONCLUSTERED INDEX IX_Inventory_VIN_Covering 
	ON dbo.Inventory (
		VIN
	) 
	INCLUDE (
		InvoicePrice, MSRP, TrueCost, DateReceived
	);
GO
CREATE NONCLUSTERED INDEX IX_SalesHistory_InventoryID_Covering 
	ON dbo.SalesHistory (
		InventoryID
	) 
	INCLUDE (
		SellPrice, CustomerID
	);
GO


-- Execute below in a new window
-- Then re-run above
/*
EXEC AutoDealershipDemo.Workload.sp_RandomVINLookupBatch
GO 1000
*/








-- S1: think in volume




-----
-- Clean up
DROP INDEX SalesHistory.IX_SalesHistory_InventoryID_Covering;
GO
DROP INDEX Inventory.IX_Inventory_VIN_Covering;
GO
--ALTER INDEX IX_Inventory_VIN ON dbo.Inventory DISABLE
--GO
--ALTER INDEX IX_SalesHistory_InventoryID ON dbo.SalesHistory DISABLE
--GO


