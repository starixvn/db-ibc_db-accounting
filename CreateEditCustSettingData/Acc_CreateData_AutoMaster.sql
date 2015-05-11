--Financial 

--DB02 create structure update maxpermatch

Update custinfo set maxpermatch201 = 0
update custinfo set disablefinancial = isnull(disablefinancial,0)
update custinfo set disablehorseracing = isnull(disablehorseracing,0)

--Server DB07
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, 0 as apositiontaking, 0 as mpositiontaking, 0 as spositiontaking, 
					0 as
					playerdiscount,
					0 as
					discount, 
                    0 as 
                    adiscount,
                    0 as 
                    sdiscount,                   
                    0 as minbet, 0 as maxbet, 0 as autopositiontaking, 0 as isautopositiontaking
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1
GO
--Cust Override
insert into CustOverride3rd
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
select custid, 3, 201, 0 as minpositiontaking, 0.9 as maxpositiontaking
from CustOverride with(nolock)
where  sporttype = 2 and bettype = 1




--Horse Racing
--Prepare:
-- Create MaxPerMatch151, DisableHorseRacing fields in DB

--DB02
Update custinfo set maxpermatch151 = 0

--------------------------
--***CustSetting***
--------------------------
------------------------------------------------------------------------------
--Win Horseracing - copied from HDP-Basketball
------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	0, 0, 0,0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2

INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 32, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount
	0, 0, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2	
