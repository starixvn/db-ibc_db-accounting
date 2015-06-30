--------------------------
--***CustOverride***
--------------------------
------------------------------------------------------------------------------
--MoneyLine Basketball - copied from HDP-Basketball
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, 20, 2, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 2 and bettype = 1
GO

------------------------------------------------------------------------------
--MixParlay-Basketball - Copied from MixParlay-Soccer
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, 9, 2, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 1 and bettype = 9
GO

------------------------------------------------------------------------------
--Fixed Odds (21), sporttype=12 - get from HDP-Basketball
------------------------------------------------------------------------------

insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, 21, 12, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where bettype = 1 and sporttype = 2
GO

------------------------------------------------------------------------------
--Floating Odds (22), sporttype=12 - get from HDP-Basketball
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, 22, 12, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where bettype = 1 and sporttype = 2
GO

------------------------------------------------------------------------------
--Football
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, bettype, 3, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 2 and bettype in (1,2,3,20)
GO

------------------------------------------------------------------------------
--Tennis
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, bettype, 5, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 2
	and bettype in (1,2,3,20)

GO

------------------------------------------------------------------------------
--Golf
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, bettype, 10, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 2
	and bettype in (1,2,3,20)
		
	
GO

------------------------------------------------------------------------------
--Other Sports
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, bettype, 99, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 2
	and bettype in (1,2,3,20)	
GO

------------------------------------------------------------------------------
--Baseball (8) not have Odd/Even (2)
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, bettype, 8, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 2
	and bettype in (1,3,20)

GO

------------------------------------------------------------------------------
--Motorsports (11) not have Over/Under (3), Odd/Even (2)
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, bettype, 11, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where sporttype = 2
	and bettype in (1,20)	
GO

------------------------------------------------------------------------------
--Financial (12) have only Odd/Even (2); Fixed Odds (21), Floating Odds (22) are added above
------------------------------------------------------------------------------
insert into custoverride
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
select custid, bettype, 12, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
from CustOverride
where  sporttype = 2
	and bettype in (2)	
GO

------------------------------------------------------------------------------
--Financial (201) have only Over/Under(3)
------------------------------------------------------------------------------
insert into CustOverride3rd
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
select custid, 3, 201, minpositiontaking, maxpositiontaking
from CustOverride
where  sporttype = 2
	and bettype in (2)	
GO

