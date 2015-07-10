--MAX CUSTID = 1200937
DELETE AFTER MAX FIRST
THEN INSERT AGAIN WHEN LAUNCH

1134657

--Prepare:
	-- Create MaxPerMatch151, DisableHorseRacing fields in DB
	
------------------------------------------------------------------------------
--create setting for Horseracing (allowed currency)
insert into systemsettings(VName, VValue)
values('HRAllowed_Curr', 'US$,EURO,GBP,RM,SD$,RMB,HK$')

update custinfo set disablehorseracing = isnull(disablehorseracing,0)

------------------------------------------------------------------------------
--Update MaxPermatch, DisableHorseRacing for custinfo table
------------------------------------------------------------------------------
--Get from BasketBall setting
Update custinfo set maxpermatch151 = maxpermatch2

Update custinfo set disablehorseracing = 1
where currency not in (1,2,3,5,6,12,13)
--
--------------------------
--***CustSetting***
--------------------------
------------------------------------------------------------------------------
--Win Horseracing - copied from HDP-Basketball
------------------------------------------------------------------------------

delete CustSetting3rd where sporttype = 151

--Partial insert 100,000 records for each bettype 31,32

--====================insert bettype 31===============================================================================

INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1 and 100000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 100001 and 200000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 200001 and 300000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 300001 and 400000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 400001 and 500000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 500001 and 600000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 600001 and 700000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 700001 and 800000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 800001 and 900000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 900001 and 1000000

--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1000001 and 1100000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1100001 and 1200000
--------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1200001 and 1300000

--======================================================================================================================
--====================insert bettype 32===============================================================================


INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1 and 100000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 100001 and 200000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 200001 and 300000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 300001 and 400000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 400001 and 500000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 500001 and 600000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 600001 and 700000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 700001 and 800000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 800001 and 900000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 900001 and 1000000

--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1000001 and 1100000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1100001 and 1200000
--------------------------------------------------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid between 1200001 and 1300000




--------will use to re-setting value when the client require-------------

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1 and 100000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1 and 100000
	
	
--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 100001 and 200000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 100001 and 200000
	
--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 200001 and 300000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 200001 and 300000
	
--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 300001 and 400000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 300001 and 400000

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 400001 and 500000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 400001 and 500000

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 500001 and 600000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 500001 and 600000

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 600001 and 700000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 600001 and 700000

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 700001 and 800000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 700001 and 800000

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 800001 and 900000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 800001 and 900000

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 900001 and 1000000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 900001 and 1000000

--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1000001 and 1100000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1000001 and 1100000
	
--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1100001 and 1200000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1100001 and 1200000	
	
--Update CustSetting3rd
--set sdiscount =  --UK meeting
--where bettype = 31 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1200001 and 1300000
	

--Update CustSetting3rd
--set sdiscount =  --Other meetings
--where bettype = 32 and sporttype = 151 
	--and custid IN(select custid from customer with (nolock) where roleid = 4 and currency in (1,2,3,5,6,12,13)) and custid between 1200001 and 1300000	