/*This example query is for data cleaning */
Select * 
From NashvilleHousingDataCleaning.dbo.NashvilleHousing

/*Standardize date format (taking out time)*/
Select ConvertedSaleDate, Convert(Date, SaleDate)
From NashvilleHousingDataCleaning.dbo.NashvilleHousing
/*Convert function from above does not properly take the time out of 
column results. The 2 SQL codes below represent a manual way to format 
just the date without the time and update the table.*/
Alter Table NashvilleHousing
Add ConvertedSaleDate Date;
Update NashvilleHousing
Set ConvertedSaleDate = CONVERT(Date,SaleDate)

/*Populate property address data*/
Select *
From NashvilleHousingDataCleaning..NashvilleHousing
--Where PropertyAddress is null
Order by ParcelID
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousingDataCleaning..NashvilleHousing a
Join NashvilleHousingDataCleaning..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	And a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null
Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousingDataCleaning..NashvilleHousing a
Join NashvilleHousingDataCleaning..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	And a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

/*Breaking out PropertyAddress into indivudal columns (Address, City, State)*/
Select PropertyAddress
From NashvilleHousingDataCleaning..NashvilleHousing
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City
From NashvilleHousingDataCleaning..NashvilleHousing
Alter Table NashvilleHousing
Add PropertyAddressSplit Nvarchar(255);
Update NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)
Alter Table NashvilleHousing
Add PropertyCitySplit Nvarchar(255)
Update NashvilleHousing
Set PropertyCitySplit = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))
Select * 
From NashvilleHousingDataCleaning..NashvilleHousing

/*Second method for breaking cells down using OwnerAddress
ParseName are only used in cases with a period inside the data column.
This can easily be offset by adding context to function*/
Select OwnerAddress
From NashvilleHousingDataCleaning..NashvilleHousing
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From NashvilleHousingDataCleaning..NashvilleHousing
Alter Table NashvilleHousing
Add OwnerAddressSplit Nvarchar(255);
Update NashvilleHousing
SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
Alter Table NashvilleHousing
Add OwnerCitySplit Nvarchar(255);
Update NashvilleHousing
SET OwnerCitySplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
Alter Table NashvilleHousing
Add OwnerStateSplit Nvarchar(255);
Update NashvilleHousing
SET OwnerStateSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
Select *
From NashvilleHousingDataCleaning..NashvilleHousing

/*Change Y and N to Yes and No in "Sold as Vancant" field*/
Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From NashvilleHousingDataCleaning..NashvilleHousing
Group by SoldAsVacant
Order by 2
Select SoldAsVacant,
Case When SoldAsVacant = 'Y' then 'Yes'
	When SoldAsVacant = 'N' then 'No'
	Else SoldAsVacant
	End
From NashvilleHousingDataCleaning..NashvilleHousing;
Update NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' then 'Yes'
	When SoldAsVacant = 'N' then 'No'
	Else SoldAsVacant
	End
From NashvilleHousingDataCleaning..NashvilleHousing

/*Remove Duplicates
Step 1 Write a CTE to find duplicate values*/
With RowNumCTE as(
Select *,
	ROW_NUMBER() OVER (
	Partition By ParcelID,
	PropertyAddress, SalePrice, SaleDate, LegalReference
	Order By UniqueID) row_num
From NashvilleHousingDataCleaning..NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress
/*Step 2 Deleting duplicates*/
With RowNumCTE as(
Select *,
	ROW_NUMBER() OVER (
	Partition By ParcelID,
	PropertyAddress, SalePrice, SaleDate, LegalReference
	Order By UniqueID) row_num
From NashvilleHousingDataCleaning..NashvilleHousing
)
Delete
From RowNumCTE
Where row_num > 1
/*Step 3 Checking for update*/
With RowNumCTE as(
Select *,
	ROW_NUMBER() OVER (
	Partition By ParcelID,
	PropertyAddress, SalePrice, SaleDate, LegalReference
	Order By UniqueID) row_num
From NashvilleHousingDataCleaning..NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

/*Delete unused columns*/
Select *
From NashvilleHousingDataCleaning.dbo.NashvilleHousing
Alter Table NashvilleHousingDataCleaning.dbo.NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress
Alter Table NashvilleHousingDataCleaning.dbo.NashvilleHousing
Drop Column SaleDate