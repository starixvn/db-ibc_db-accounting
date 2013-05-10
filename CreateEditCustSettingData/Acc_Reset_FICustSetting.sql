 --============================================================
-- RESET ALL SETTINGS OF FINANCE TO ZERO
--============================================================
--select max(custid) from customer (nolock) --1412252

--------------------------------------------------------------------------
Update custinfo set maxpermatch201 = 0, DisableFinancial = 1

------------------------------------------------------------------------------
--Update Custsetting
------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 1 and 100000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 100001 and 200000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 200001 and 300000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 300001 and 400000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 400001 and 500000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 500001 and 600000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 600001 and 700000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 700001 and 800000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 800001 and 900000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 900001 and 1000000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 1000001 and 1100000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 1100001 and 1200000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 1200001 and 1300000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 1300001 and 1400000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustSetting3rd set 
	minbet = 0,
	maxbet = 0,

	playerdiscount = 0,
	discount = 0,
	adiscount = 0,
	sdiscount = 0,

	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,

	autopositiontaking = 0,
	isautopositiontaking = 0
where  sporttype = 201 and custid between 1400001 and 1500000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------
--Update CustOverride
------------------------------------------------------------------------------

update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 1 and 100000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 100001 and 200000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 200001 and 300000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 300001 and 400000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 400001 and 500000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 500001 and 600000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 600001 and 700000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 700001 and 800000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 800001 and 900000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 900001 and 1000000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 1000001 and 1100000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 1100001 and 1200000

WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 1200001 and 1300000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 1300001 and 1400000
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------
update CustOverride3rd set 
	minpositiontaking = 0, 
	maxpositiontaking = 0
where  sporttype = 201 and custid between 1400001 and 1500000








