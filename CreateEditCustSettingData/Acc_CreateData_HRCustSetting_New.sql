ALTER PROCEDURE [dbo].[ExecRep_07]	
AS

if NOT exists (select * from dbo.sysobjects where name = 'CustSetting3rd')
BEGIN
	RETURN
END

delete CustSetting3rd where sporttype = 151 and bettype in (31,32) and custid > 1200937

INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount,minbet, maxbet, autopositiontaking, isautopositiontaking)

select 31, 151, cs.custid, 0, 0, 0,
	0,--playerdiscount
	0,--discount
	0,--adiscount
	0,--sdiscount 
	minbet, maxbet, 0, 0
from custsetting cs with (nolock)
where bettype = 1 and sporttype = 2 and custid > 1200937

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
where bettype = 1 and sporttype = 2 and custid > 1200937