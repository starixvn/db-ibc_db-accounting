--Create new row in table Sporttype, Bettype for new sporttype 201,151 bettype 31,32,33,51,52


------------------------------------------------------------------------------
--Update MaxPermatch, DisableFinancial for custinfo table
------------------------------------------------------------------------------
--server DB02
Update custinfo set maxpermatch201 = maxpermatch2
--Update custinfo set disablefinancial = 0

--update custinfo set disablefinancial = isnull(disablefinancial,0)

--------------------------
--***CustSetting***
--------------------------
------------------------------------------------------------------------------
--Financial - copied from HDP-Basketball
------------------------------------------------------------------------------

delete CustSetting3rd where sporttype = 201

delete CustOverride3rd where sporttype = 201

------------------------------------------------------------------------------
--Financial (201) have only Over/Under(3) are added above
------------------------------------------------------------------------------

--Partial insert 100,000 records


--Server DB07
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

WAITFOR DELAY '000:00:10'
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

WAITFOR DELAY '000:00:10'
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

WAITFOR DELAY '000:00:10'
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

WAITFOR DELAY '000:00:10'
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
WAITFOR DELAY '000:00:10'
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
WAITFOR DELAY '000:00:10'
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
WAITFOR DELAY '000:00:10'
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
WAITFOR DELAY '000:00:10'
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
WAITFOR DELAY '000:00:10'
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
WAITFOR DELAY '000:00:10'
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

WAITFOR DELAY '000:00:10'
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

WAITFOR DELAY '000:00:10'
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
WAITFOR DELAY '000:00:10'
GO
--------------------------------------------------------------------------------------------------------------------------------





--------------------------------------------------------------------------------------------------------------------------------
WAITFOR DELAY '000:00:10'
GO
--Cust Override
insert into CustOverride3rd
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
select custid, 3, 201, minpositiontaking, maxpositiontaking
from CustOverride with(nolock)
where  sporttype = 2 and bettype = 1



