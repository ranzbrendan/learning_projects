/*
	Data Cleaning Project on Nashville Housing Data using SQL
*/

USE [nashville_housing]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------------------------------------
-- Make New Table For Clean Values

CREATE TABLE [dbo].[housing_data](
	[UniqueID ] [int] NOT NULL,
	[ParcelID] [nvarchar](255) NULL,
	[LandUse] [nvarchar](255) NULL,
	[PropertyAddress] [nvarchar](255) NULL,
	[SaleDate] [date] NULL,
	[SalePrice] [numeric](10,2) NULL,
	[LegalReference] [nvarchar](255) NULL,
	[SoldAsVacant] [nvarchar](255) NULL,
	[OwnerName] [nvarchar](255) NULL,
	[OwnerAddress] [nvarchar](255) NULL,
	[Acreage] [numeric](10,2) NULL,
	[TaxDistrict] [nvarchar](255) NULL,
	[LandValue] [numeric](10,2) NULL,
	[BuildingValue] [numeric](10,2) NULL,
	[TotalValue] [numeric](10,2) NULL,
	[YearBuilt] [numeric](10,2) NULL,
	[Bedrooms] [numeric](10,2) NULL,
	[FullBath] [numeric](10,2) NULL,
	[HalfBath] [numeric](10,2) NULL
) ON [PRIMARY]
GO

----------------------------------------------------------------------------------------------------------------------------
-- Rename Column Names To Better Format

EXEC sp_rename 'housing_data.UniqueID', 'unique_id', 'COLUMN';
EXEC sp_rename 'housing_data.ParcelID', 'parcel_id', 'COLUMN';
EXEC sp_rename 'housing_data.LandUse', 'land_use', 'COLUMN';
EXEC sp_rename 'housing_data.PropertyAddress', 'property_address', 'COLUMN';
EXEC sp_rename 'housing_data.SaleDate', 'sale_date', 'COLUMN';
EXEC sp_rename 'housing_data.SalePrice', 'sale_price', 'COLUMN';
EXEC sp_rename 'housing_data.LegalReference', 'legal_reference', 'COLUMN';
EXEC sp_rename 'housing_data.SoldAsVacant', 'sold_as_vacant', 'COLUMN';
EXEC sp_rename 'housing_data.OwnerName', 'owner_name', 'COLUMN';
EXEC sp_rename 'housing_data.UniqueID', 'unique_id', 'COLUMN';
EXEC sp_rename 'housing_data.OwnerAddress', 'owner_address', 'COLUMN';
EXEC sp_rename 'housing_data.Acreage', 'acreage', 'COLUMN';
EXEC sp_rename 'housing_data.TaxDistrict', 'tax_district', 'COLUMN';
EXEC sp_rename 'housing_data.LandValue', 'land_value', 'COLUMN';
EXEC sp_rename 'housing_data.BuildingValue', 'building_value', 'COLUMN';
EXEC sp_rename 'housing_data.TotalValue', 'total_value', 'COLUMN';
EXEC sp_rename 'housing_data.YearBuilt', 'year_built', 'COLUMN';
EXEC sp_rename 'housing_data.Bedrooms', 'bedrooms', 'COLUMN';
EXEC sp_rename 'housing_data.FullBath', 'full_bath', 'COLUMN';
EXEC sp_rename 'housing_data.HalfBath', 'half_bath', 'COLUMN';

SELECT * FROM housing_data;

----------------------------------------------------------------------------------------------------------------------------
-- Populate New Table With Raw Data.

INSERT INTO housing_data
SELECT * FROM housing_data_raw;

----------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format

SELECT sale_date, CONVERT(DATE, sale_date) AS date
FROM housing_data;

ALTER TABLE housing_data
ALTER COLUMN sale_date DATE;

----------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address Data

SELECT property_address
FROM housing_data
WHERE property_address IS NULL;

-- Check count of each property address per parcel id.
SELECT DISTINCT parcel_id, property_address, COUNT(*) OVER(PARTITION BY parcel_id) AS count
FROM housing_data;

SELECT 
	h1.parcel_id, 
	h1.property_address, 
	h2.parcel_id, 
	h2.property_address,
	ISNULL(h1.property_address, h2.property_address)
FROM housing_data AS h1
INNER JOIN housing_data AS h2
	ON	h1.parcel_id = h2.parcel_id
	AND h1.unique_id <> h2.unique_id
WHERE h1.property_address IS NULL;

-- Update property address

UPDATE h1
SET property_address = ISNULL(h1.property_address, h2.property_address)
FROM housing_data AS h1
INNER JOIN housing_data AS h2
	ON h1.parcel_id = h2.parcel_id
	AND h1.unique_id <> h2.unique_id
WHERE h1.property_address IS NULL;


----------------------------------------------------------------------------------------------------------------------------
-- Split Property Address Into Address and City columns

-- Check property_address values and format
SELECT property_address
FROM housing_data;


EXEC sp_rename 'housing_data.property_address', 'property_address_old', 'COLUMN';

ALTER TABLE housing_data
ADD property_address NVARCHAR(255);

UPDATE housing_data
SET property_address = SUBSTRING(property_address_old, 1, CHARINDEX(',', property_address_old) - 1);

ALTER TABLE housing_data
ADD property_city NVARCHAR(255);

UPDATE housing_data
SET property_city = SUBSTRING(property_address_old, CHARINDEX(',', property_address_old) + 1, LEN(property_address_old));

SELECT * 
FROM housing_data;


----------------------------------------------------------------------------------------------------------------------------
-- Split Owner Address Into Address, City, and State Columns

SELECT owner_address
FROM housing_data;

EXEC sp_rename 'housing_data.owner_address', 'owner_address_old', 'COLUMN';

ALTER TABLE housing_data
ADD owner_address NVARCHAR(255);

ALTER TABLE housing_data
ADD owner_city NVARCHAR(255);

ALTER TABLE housing_data
ADD owner_state NVARCHAR(255);

UPDATE housing_data
SET owner_address = PARSENAME(REPLACE(owner_address_old, ',' , '.') , 3),
	owner_city = PARSENAME(REPLACE(owner_address_old, ',' , '.') , 2),
	owner_state = PARSENAME(REPLACE(owner_address_old, ',' , '.') , 1);

SELECT *
FROM housing_data;


----------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in sold_as_vacant field

SELECT 
	sold_as_vacant,
	CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
		 WHEN sold_as_vacant = 'N' THEN 'No'
		 ELSE sold_as_vacant
		 END AS new
FROM
	housing_data;

UPDATE housing_data
SET sold_as_vacant = CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
		 WHEN sold_as_vacant = 'N' THEN 'No'
		 ELSE sold_as_vacant
		 END;

SELECT DISTINCT sold_as_vacant
FROM housing_data;


----------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates

-- write CTE to make a query with row_number window function to check duplicates.

WITH temp AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY parcel_id,
				 land_use,
				 property_address_old,
				 sale_date,
				 sale_price,
				 legal_reference,
				 sold_as_vacant,
				 owner_name,
				 owner_address_old,
				 acreage,
				 tax_district,
				 land_value,
				 building_value,
				 total_value,
				 year_built,
				 bedrooms,
				 full_bath,
				 half_bath,
				 property_address,
				 property_city,
				 owner_address,
				 owner_city,
				 owner_state
	ORDER BY unique_id) AS row_num
FROM housing_data
) 

DELETE FROM housing_data
WHERE unique_id IN (
	SELECT unique_id
	FROM temp
	WHERE row_num <> 1);



----------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

SELECT * FROM housing_data;

-- Delete the old columns
ALTER TABLE housing_data
DROP COLUMN property_address_old, owner_address_old

SELECT * FROM housing_data;