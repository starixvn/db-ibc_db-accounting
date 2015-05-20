--Prepare:
	-- Create MaxPerMatch fields in DB:
		--maxpermatch2
		--maxpermatch3
		--maxpermatch5
		--maxpermatch8
		--maxpermatch10
		--maxpermatch11
		--maxpermatch12
		--maxpermatch99


------------------------------------------------------------------------------
--Update MaxPermatch for custinfo table
------------------------------------------------------------------------------
/*
Update custinfo set maxpermatch2 = maxpermatchb,
	maxpermatch3 = maxpermatchb,
	maxpermatch5 = maxpermatchb,
	maxpermatch8 = maxpermatchb,
	maxpermatch10 = maxpermatchb,
	maxpermatch11 = maxpermatchb,
	maxpermatch12 = maxpermatchb,
	maxpermatch99 = maxpermatchb
*/

--------------------------
--***CustSetting***
--------------------------
------------------------------------------------------------------------------
--MoneyLine Basketball - copied from HDP-Basketball
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)


select 20, 2, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where bettype = 1 and sporttype = 2
GO

------------------------------------------------------------------------------
--MixParlay Basketball - copied from MixParlay-Soccer
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)

select 9, 2, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where bettype = 9 and sporttype = 1
GO

------------------------------------------------------------------------------
--Fixed Odds (21), sporttype=12 - get from HDP-Basketball
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)
select 21, 12, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where bettype = 1 and sporttype = 2
GO

------------------------------------------------------------------------------
--Floating Odds (22), sporttype=12 - get from HDP-Basketball
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)
select 22, 12, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where bettype = 1 and sporttype = 2
GO

------------------------------------------------------------------------------
--Update Commission for MoneyLine, FixOdds, FloatingOdds bettype (20, 21, 22) - Get from CorrectScore-Soccer
------------------------------------------------------------------------------
Update CustSetting set playerdiscount=c2.playerdiscount, discount=c2.discount, 
                      adiscount=c2.adiscount, sdiscount=c2.sdiscount,
                      groupa=c2.groupa, groupb=c2.groupb, groupc=c2.groupc, groupd=c2.groupd, groupe=c2.groupe, groupf=c2.groupf
from CustSetting c1
	inner join (select custid, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf
                from CustSetting
                where sporttype = 1 and bettype = 4) c2
     on c1.custid = c2.custid
where c1.bettype in (20,21,22)

GO

------------------------------------------------------------------------------
--Football (3)
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)                  
select bettype, 3, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where sporttype = 2
	and bettype in (1,2,3,20)
GO

------------------------------------------------------------------------------
--Tennis (5)
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)	                   
select bettype, 5, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where sporttype = 2
	and bettype in (1,2,3,20)
	
GO

------------------------------------------------------------------------------
--Golf (10)
------------------------------------------------------------------------------	
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)

select bettype, 10, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where sporttype = 2
	and bettype in (1,2,3,20)
	
GO

------------------------------------------------------------------------------
--Other Sports (99)
------------------------------------------------------------------------------	
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)
select bettype, 99, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where sporttype = 2
	and bettype in (1,2,3,20)

GO

------------------------------------------------------------------------------
--Baseball (8) not have Odd/Even (2)
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)
select bettype, 8, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where sporttype = 2
	and bettype in (1,3,20)
GO

------------------------------------------------------------------------------
--Motorsports (11) not have Over/Under (3), Odd/Even (2)
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)
select bettype, 11, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where sporttype = 2
	and bettype in (1,20)	
GO

------------------------------------------------------------------------------
--Financial (12) have only Odd/Even (2); FixedOdds (21), FloatingOdds (22) are added above
------------------------------------------------------------------------------
INSERT INTO custSetting
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking)
select bettype, 12, cs.custid, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, autolivepositiontaking, isautopositiontaking, 
                      isautolivepositiontaking
from custsetting cs 
where  sporttype = 2
	and bettype in (2)
GO

------------------------------------------------------------------------------
--Financial (201) have only Over/Under(3) are added above
------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking
from custsetting cs 
where  sporttype = 2
	and bettype in (2)	
GO

------------------------------------------------------------------------------
--Horse Racing (151) have only 31,32 bettype are added above
------------------------------------------------------------------------------
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 31, 151, cs.custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking
                      
from custsetting cs 
where  sporttype = 2
	and bettype in (2)	
	
INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 32, 151, cs.custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking
                      
from custsetting cs 
where  sporttype = 2
	and bettype in (2)	
GO

