/*-------------------------------------------------------------------
-- 5 - Scenario #4
-- 
-- OPTIONAL
-- Summary: Do we have to sort?  
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE AutoDealershipDemo
GO


-----
-- SETUP
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_InventoryFlat_DateReceived_VIN')
	DROP INDEX InventoryFlat.IX_InventoryFlat_DateReceived_VIN
GO
DBCC FREEPROCCACHE
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO








-----
-- Ctrl-M: Turn on Actual Execution Plan
SELECT TOP 50000
	InventoryFlat.VIN, InventoryFlat.MakeName, InventoryFlat.ModelName, InventoryFlat.PackageName, InventoryFlat.ColorName, 
	InventoryFlat.PackageCode, InventoryFlat.ColorCode, 
	InventoryFlat.DateReceived, InventoryFlat.Sold, InventoryFlat.SoldPrice
FROM dbo.InventoryFlat
INNER JOIN dbo.Vw_VehiclePackageDetail
	ON InventoryFlat.MakeName = Vw_VehiclePackageDetail.MakeName
	AND InventoryFlat.ModelName = Vw_VehiclePackageDetail.ModelName
	AND InventoryFlat.ColorCode = Vw_VehiclePackageDetail.ColorCode
	AND InventoryFlat.PackageCode = Vw_VehiclePackageDetail.PackageCode
ORDER BY DateReceived, VIN
OPTION(MAXDOP 1);
GO 








-----
-- Removed ORDER BY
SELECT TOP 50000
	InventoryFlat.VIN, InventoryFlat.MakeName, InventoryFlat.ModelName, InventoryFlat.PackageName, InventoryFlat.ColorName, 
	InventoryFlat.PackageCode, InventoryFlat.ColorCode, 
	InventoryFlat.DateReceived, InventoryFlat.Sold, InventoryFlat.SoldPrice
FROM dbo.InventoryFlat
INNER JOIN dbo.Vw_VehiclePackageDetail
	ON InventoryFlat.MakeName = Vw_VehiclePackageDetail.MakeName
	AND InventoryFlat.ModelName = Vw_VehiclePackageDetail.ModelName
	AND InventoryFlat.ColorCode = Vw_VehiclePackageDetail.ColorCode
	AND InventoryFlat.PackageCode = Vw_VehiclePackageDetail.PackageCode
OPTION(MAXDOP 1);
GO








-----
-- Must keep the ORDER BY
--
-- Add a covering index!
CREATE INDEX IX_InventoryFlat_DateReceived_Covering ON InventoryFlat (
		DateReceived, VIN
	) 
INCLUDE (
	MakeName, ModelName, PackageName, ColorName, PackageCode, ColorCode, Sold, SoldPrice
)
GO




-----
-- Re-execute original query here
SELECT TOP 50000
	InventoryFlat.VIN, InventoryFlat.MakeName, InventoryFlat.ModelName, InventoryFlat.PackageName, InventoryFlat.ColorName, 
	InventoryFlat.PackageCode, InventoryFlat.ColorCode, 
	InventoryFlat.DateReceived, InventoryFlat.Sold, InventoryFlat.SoldPrice
FROM dbo.InventoryFlat
INNER JOIN dbo.Vw_VehiclePackageDetail
	ON InventoryFlat.MakeName = Vw_VehiclePackageDetail.MakeName
	AND InventoryFlat.ModelName = Vw_VehiclePackageDetail.ModelName
	AND InventoryFlat.ColorCode = Vw_VehiclePackageDetail.ColorCode
	AND InventoryFlat.PackageCode = Vw_VehiclePackageDetail.PackageCode
ORDER BY DateReceived, VIN
OPTION(MAXDOP 1);
GO 








-----
-- Expanded Views + ORDER BY
SELECT TOP 50000
	InventoryFlat.VIN, InventoryFlat.MakeName, InventoryFlat.ModelName, InventoryFlat.PackageName, InventoryFlat.ColorName, 
	InventoryFlat.PackageCode, InventoryFlat.ColorCode, 
	InventoryFlat.DateReceived, InventoryFlat.Sold, InventoryFlat.SoldPrice
FROM dbo.InventoryFlat
INNER JOIN Vehicle.Make
	ON InventoryFlat.MakeName = Make.MakeName
INNER JOIN Vehicle.Model
	ON InventoryFlat.ModelName = Model.ModelName
INNER JOIN Vehicle.Color
	ON InventoryFlat.ColorCode = Color.ColorCode
INNER JOIN Vehicle.Package
	ON InventoryFlat.PackageCode = Package.PackageCode
ORDER BY DateReceived, VIN
OPTION(MAXDOP 1);
GO 




-----
-- Drop index & re-execute prior query one more time
DROP INDEX InventoryFlat.IX_InventoryFlat_DateReceived_Covering
GO
