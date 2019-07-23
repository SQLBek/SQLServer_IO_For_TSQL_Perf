/*-------------------------------------------------------------------
-- 4 - Scenario #3
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE AutoDealershipDemo
GO




-----
-- Show SQL Server Max Memory
SELECT 
	name,
	value_in_use
FROM sys.configurations
WHERE name = 'max server memory (MB)';
GO


-- Show OS level Memory
SELECT	
	total_physical_memory_kb / 1020.0 AS total_physical_memory_mb,
	available_physical_memory_kb / 1024.0 AS available_physical_memory_mb
FROM sys.dm_os_sys_memory;
GO








-----
-- Spin up workload
--
-- D:\Cloud Drives\Google Drive\Presentations-SQLBek\Source\SQL Server IO To Improve T-SQL Performance\Demo Scripts\0-Havok_Execute sp_GetInventoryFlatNV_VehiclePackageDetail Workload Script Bat x5.bat








-----
-- Let's run a query
-- Use a new window for this
SELECT 
	InventoryFlatNVarchar.VIN, InventoryFlatNVarchar.MakeName, InventoryFlatNVarchar.ModelName, 
	InventoryFlatNVarchar.PackageName, InventoryFlatNVarchar.ColorName, InventoryFlatNVarchar.PackageCode, 
	InventoryFlatNVarchar.ColorCode, InventoryFlatNVarchar.DateReceived, InventoryFlatNVarchar.Sold, 
	InventoryFlatNVarchar.SoldPrice
FROM dbo.InventoryFlatNVarchar
INNER JOIN dbo.Vw_VehiclePackageDetail
	ON InventoryFlatNVarchar.MakeName = Vw_VehiclePackageDetail.MakeName
	AND InventoryFlatNVarchar.ModelName = Vw_VehiclePackageDetail.ModelName
	AND InventoryFlatNVarchar.ColorCode = Vw_VehiclePackageDetail.ColorCode
	AND InventoryFlatNVarchar.PackageCode = Vw_VehiclePackageDetail.PackageCode
ORDER BY DateReceived, VIN;
GO









-----
-- Hey Andy - why's my query running slow?
-- Let's see what's going on
EXEC sp_whoisactive @delta_interval = 3
GO








-----
-- DMV to show memory grants
--
-- request_time: The time when the request for Query Memory was made
-- grant_time: The time when the request for Query Memory was fulfilled by SQL Server
-- requested_memory_kb: How much Query Memory the query requested
-- granted_memory_kb: How much Query Memory the query got from SQL Server
-- query_cost: The costs of the Execution Plan
-- Resource: https://www.sqlpassion.at/archive/2018/10/16/query-memory-grants-and-resource-semaphores-in-sql-server/
SELECT 
	session_id,
	request_time,
	grant_time,
	requested_memory_kb,
	granted_memory_kb,
	query_cost,
	resource_semaphore_id, 
	pool_id
FROM sys.dm_exec_query_memory_grants;
GO


-----
-- DMV to show server limits
--
-- max_target_memory_kb: How much Query Memory one query can get
-- available_memory_kb: How much Query Memory is currently available by that Resource Semaphore
-- granted_memory_kb: How much Query memory is currently granted by that Resource Semaphore
-- Resource: https://www.sqlpassion.at/archive/2018/10/16/query-memory-grants-and-resource-semaphores-in-sql-server/
SELECT 
	resource_semaphore_id, 
	pool_id,
	max_target_memory_kb,
	available_memory_kb,
	granted_memory_kb,
	waiter_count
FROM sys.dm_exec_query_resource_semaphores;
GO








-----
-- First Kill Workload
EXEC sp_whoisactive 
GO








-----
-- Copy & run in another window
-- Ctrl-M: Turn on Actual Execution Plan
SELECT 
	InventoryFlatNVarchar.VIN, InventoryFlatNVarchar.MakeName, InventoryFlatNVarchar.ModelName, 
	InventoryFlatNVarchar.PackageName, InventoryFlatNVarchar.ColorName, InventoryFlatNVarchar.PackageCode, 
	InventoryFlatNVarchar.ColorCode, InventoryFlatNVarchar.DateReceived, InventoryFlatNVarchar.Sold, 
	InventoryFlatNVarchar.SoldPrice
FROM dbo.InventoryFlatNVarchar
INNER JOIN dbo.Vw_VehiclePackageDetail
	ON InventoryFlatNVarchar.MakeName = Vw_VehiclePackageDetail.MakeName
	AND InventoryFlatNVarchar.ModelName = Vw_VehiclePackageDetail.ModelName
	AND InventoryFlatNVarchar.ColorCode = Vw_VehiclePackageDetail.ColorCode
	AND InventoryFlatNVarchar.PackageCode = Vw_VehiclePackageDetail.PackageCode
ORDER BY DateReceived, VIN;
GO

-- Memory Grant: XXX
-- Query Cost: XXX


-----
-- Check memory grant
SELECT 
	requested_memory_kb / 1024.0 / 1024.0 AS requested_mem_gb,
	granted_memory_kb / 1024.0 / 1024.0 AS requested_mem_gb,
	query_cost,
	requested_memory_kb,
	granted_memory_kb,
	request_time,
	grant_time,
	session_id,
	resource_semaphore_id, 
	pool_id
FROM sys.dm_exec_query_memory_grants;
GO








-----
-- Check Datatypes
EXEC sp_help 'dbo.InventoryFlatNVarchar';
GO




-- Why can't I just use NVARCHAR(MAX) everywhere?  Who cares?








-- Compare
EXEC sp_help 'dbo.InventoryFlat';
GO








-----
-- Expand query
SELECT 
	InventoryFlat.VIN, InventoryFlat.MakeName, InventoryFlat.ModelName, 
	InventoryFlat.PackageName, InventoryFlat.ColorName, InventoryFlat.PackageCode, 
	InventoryFlat.ColorCode, InventoryFlat.DateReceived, InventoryFlat.Sold, 
	InventoryFlat.SoldPrice
FROM dbo.InventoryFlat
INNER JOIN (
	-- SELECT #2
	SELECT DISTINCT    
		Inventory.BaseModelID, Inventory.PackageID, 
		Vw_VehicleBaseModel.MakeName, Vw_VehicleBaseModel.ModelName, 
		Vw_VehicleBaseModel.ColorName, Vw_VehicleBaseModel.ColorCode,  
		Package.PackageName, Package.PackageCode, Package.Description,  
		Package.TrueCost, Package.InvoicePrice, Package.MSRP  
	FROM dbo.Inventory    
	INNER JOIN (
		-- SELECT #3
		SELECT     
			BaseModel.BaseModelID, 
			Make.MakeName, Model.ModelName,    
			Color.ColorName, Color.ColorCode    
		FROM Vehicle.BaseModel
		INNER JOIN Vehicle.Make    
			ON BaseModel.MakeID = Make.MakeID    
		INNER JOIN Vehicle.Model    
			ON BaseModel.ModelID = Model.ModelID    
		INNER JOIN Vehicle.Color    
			ON BaseModel.ColorID = Color.ColorID
	) AS Vw_VehicleBaseModel
		ON Inventory.BaseModelID = Vw_VehicleBaseModel.BaseModelID    
	INNER JOIN Vehicle.Package    
		ON Inventory.PackageID = Package.PackageID
) AS Vw_VehiclePackageDetail
	ON InventoryFlat.MakeName = Vw_VehiclePackageDetail.MakeName
	AND InventoryFlat.ModelName = Vw_VehiclePackageDetail.ModelName
	AND InventoryFlat.ColorCode = Vw_VehiclePackageDetail.ColorCode
	AND InventoryFlat.PackageCode = Vw_VehiclePackageDetail.PackageCode
ORDER BY DateReceived, VIN;
GO



-----
-- Changed datatypes & expanded views
-- Run in another window
SELECT 
	InventoryFlat.VIN, InventoryFlat.MakeName, InventoryFlat.ModelName, 
	InventoryFlat.PackageName, InventoryFlat.ColorName, InventoryFlat.PackageCode, 
	InventoryFlat.ColorCode, InventoryFlat.DateReceived, InventoryFlat.Sold, 
	InventoryFlat.SoldPrice
FROM dbo.InventoryFlat
INNER JOIN Vehicle.Make
	ON InventoryFlat.MakeName = Make.MakeName
INNER JOIN Vehicle.Model
	ON InventoryFlat.ModelName = Model.ModelName
INNER JOIN Vehicle.Color
	ON InventoryFlat.ColorCode = Color.ColorCode
INNER JOIN Vehicle.Package
	ON InventoryFlat.PackageCode = Package.PackageCode
ORDER BY DateReceived, VIN;
GO 

-- Memory Grant: XXX
-- Query Cost: XXX



-----
-- Check memory grant
SELECT 
	requested_memory_kb / 1024.0 / 1024.0 AS requested_mem_gb,
	granted_memory_kb / 1024.0 / 1024.0 AS requested_mem_gb,
	query_cost,
	requested_memory_kb,
	granted_memory_kb,
	request_time,
	grant_time,
	session_id,
	resource_semaphore_id, 
	pool_id
FROM sys.dm_exec_query_memory_grants;
GO




-----
-- First Kill Workload
EXEC sp_whoisactive 
GO


