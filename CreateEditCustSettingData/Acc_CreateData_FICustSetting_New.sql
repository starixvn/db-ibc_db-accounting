ALTER PROCEDURE [dbo].[ExecRep_07]	
AS

--Pay attention to deploy Aff_CustomerInsAffiliate_1 and Dot_Dep_CustomerInsMember_Ag

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

delete CustSetting3rd where sporttype = 201 and bettype = 3

delete CustOverride3rd where sporttype = 201 and bettype = 3

------------------------------------------------------------------------------
--Financial (201) have only Over/Under(3) are added above
------------------------------------------------------------------------------

INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 1 and 100000

WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 100001 and 200000

WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 200001 and 300000

WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 300001 and 400000

WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 400001 and 500000
WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 500001 and 600000
WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 600001 and 700000
WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 700001 and 800000
WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 800001 and 900000
WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 900001 and 1000000
WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 1000001 and 1100000

WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 1100001 and 1200000

WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,   
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,
                    minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid between 1200001 and 1300000
WAITFOR DELAY '000:00:03'
GO
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
WAITFOR DELAY '000:00:03'
GO
--Cust Override
insert into CustOverride3rd
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
select custid, 3, 201, minpositiontaking, maxpositiontaking
from CustOverride with(nolock)
where  sporttype = 2 and bettype = 1


Declare @temp_comm smallmoney

update cs set
	@temp_comm = groupa,
	sdiscount = @temp_comm,
	playerdiscount = 0, 
	discount =0 ,
	adiscount =0
from CustSetting3rd cs 
where cs.sporttype = 201 and cs.bettype = 3	and custid in (select custid from custinfo with (nolock) where roleid = 4)

update cs set
	@temp_comm = groupa,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount =@temp_comm
from CustSetting3rd cs 
where cs.sporttype = 201 and cs.bettype = 3	and custid in (select custid from custinfo with (nolock) where roleid = 3)

update cs set
	@temp_comm = groupa,
	sdiscount = 0,
	playerdiscount = 0, 
	discount = @temp_comm ,
	adiscount = 0
from CustSetting3rd cs 
where cs.sporttype = 201 and cs.bettype = 3	and custid in (select custid from custinfo with (nolock) where roleid = 2)

GO




