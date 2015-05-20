ALTER Procedure DBA_CreateData_HRFICustSetting_Member
    @custid int
AS
/*
Created: 
Task : 
DB: DBTRANS.bodb02
Original:

Revisions:
    - 20091203@Kiwi: move to use CustSetting3rd table.
*/




delete CustSetting3rd where sporttype = 151 and bettype in (31,32) and custid = @custid

INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0,
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from CustSetting3rd cs with (nolock)
where bettype = 1 and sporttype = 2 and custid = @custid

INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 32, 151, cs.custid, 0, 0, 0, 
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid = @custid

--------------------------------------


delete CustSetting3rd where sporttype = 201 and bettype = 3 and custid = @custid


Update custinfo set maxpermatch201 = maxpermatch2 where custid = @custid

------------------------------------------------------------------------------
--Financial (201) have only Over/Under(3) are added above
------------------------------------------------------------------------------

INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking,  playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,  					
					playerdiscount,					
					discount,                     
                    adiscount,					
                    sdiscount,                                        
                    minbet, maxbet, autopositiontaking, isautopositiontaking 
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid = @custid