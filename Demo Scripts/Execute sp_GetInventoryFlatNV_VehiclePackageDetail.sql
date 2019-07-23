USE AutoDealershipDemo;
GO

CREATE TABLE #tmpInvFlat (
	VIN NVARCHAR(500),
	MakeName NVARCHAR(500),
	ModelName NVARCHAR(500),
	PackageName NVARCHAR(500),
	ColorName NVARCHAR(500),
	PackageCode NVARCHAR(500),
	ColorCode NVARCHAR(500),
	DateReceived DATETIME,
	Sold INT,
	SoldPrice DECIMAL(28, 4)
);
GO
INSERT INTO #tmpInvFlat
EXEC Workload.sp_GetInventoryFlatNV_VehiclePackageDetail;
GO