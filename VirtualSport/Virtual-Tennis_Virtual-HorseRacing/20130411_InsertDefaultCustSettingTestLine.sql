 
SELECT custid INTO #tmp
FROM custInfo WITH(NOLOCK)
WHERE recommend = 68290

INSERT INTO #tmp
SELECT 68287 -- ITmaster
UNION ALL
SELECT 20 -- SA-UUS

DELETE FROM #tmp
WHERE custid IN (SELECT custid 
				 FROM custsetting3rd WITH(NOLOCK)
				 WHERE custid in (SELECT * FROM #tmp)
					AND sporttype = 186
				)


--- insert default setting for virtual racing from virtual soccer
INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
SELECT custid, 1231, 181, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
FROM custsetting3rd WITH(NOLOCK)
WHERE custid IN (SELECT * FROM #tmp)
	AND sporttype = 180 and bettype = 1201
	
--- insert default setting for virtual tennis from virtual soccer
INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
SELECT custid, 1220, 186, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
FROM custsetting3rd WITH(NOLOCK)
WHERE custid IN (SELECT * FROM #tmp)
	AND sporttype = 180 and bettype = 1201
	
	



------------------------------------------

INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
SELECT custid, 1231, 181, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
FROM custoverride3rd with(nolock)
WHERE custid in (68290,20,68287)
and sporttype = 180 and bettype = 1201


INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
SELECT custid, 1220, 186, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
FROM custoverride3rd with(nolock)
WHERE custid in (68290,20,68287)
and sporttype = 180 and bettype = 1201