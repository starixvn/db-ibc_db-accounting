-- select max(custid) from custinfo with(nolocK)
DECLARE @maxcustid INT
SELECT @maxcustid= xxxxx --8414563
	
DELETE TOP(10000) CustSetting3rd WITH(ROWLOCK,UPDLOCK)
WHERE custid > @maxcustid
	and bettype = 1201 AND sporttype = 180	
	
DELETE TOP(10000) CustOverride3rd WITH(ROWLOCK,UPDLOCK)
WHERE custid > @maxcustid
	and bettype = 1201 AND sporttype = 180		
	
DELETE TOP(10000) Dep_CustSetting3rd WITH(ROWLOCK,UPDLOCK)
WHERE custid > @maxcustid
	and bettype = 1201 AND sporttype = 180		
	
-- insert min PT
INSERT INTO CustOverride3rd([custId], [bettype], [sporttype], minpositiontaking, maxpositiontaking,minlivepositiontaking,maxlivepositiontaking)			
SELECT co.CustID, 1201, 180, minpositiontaking, 
		case when roleid = 4 then maxpositiontaking
			else 0.9 end as maxpositiontaking, 
		0 as minlivepositiontaking,0 as maxlivepositiontaking
FROM custinfo ci WITH (NOLOCK) JOIN 
	custOverride3rd co WITH(NOLOCK)	ON ci.custid=co.custid 		
WHERE co.custid > @maxcustid
	AND co.bettype = 81 AND co.sporttype = 161		
	
-- insert PT
INSERT INTO CustSetting3rd([custId], [bettype], [sporttype], [apositiontaking], [mpositiontaking], [spositiontaking],  [playerdiscount], [discount], [adiscount], [sdiscount], [Minbet], [Maxbet], autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
SELECT cs.custid, 1201, 180, [apositiontaking], [mpositiontaking], [spositiontaking],  0 as [playerdiscount], 0 as [discount], 0 as [adiscount], 0 as [sdiscount], [Minbet], [Maxbet], autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, 0 as alivepositiontaking,0 as mlivepositiontaking,0 as  slivepositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking, 0 as autolivempositiontaking, 0 as isautolivempositiontaking
FROM CustSetting3rd cs WITH(NOLOCK)			
WHERE cs.custid > @maxcustid
	AND cs.bettype = 81 AND cs.sporttype = 161	
	
INSERT INTO Dep_CustSetting3rd
		([custid]
       ,[bettype]
       ,[sporttype]
       ,[islive]
       ,[apositiontaking]
       ,[mpositiontaking]
       ,[spositiontaking]
       ,[playerdiscount]
       ,[discount]
       ,[adiscount]
       ,[sdiscount]
       ,[minbet]
       ,[maxbet])
SELECT 				
	[custid]
   ,1201 as [bettype]
   ,180 as [sporttype]
   ,[islive]
   ,[apositiontaking]
   ,[mpositiontaking]
   ,[spositiontaking]
   ,0 as [playerdiscount]
   ,0 as [discount]
   ,0 as [adiscount]
   ,0 as [sdiscount]
   ,[minbet]
   ,[maxbet]		
FROM dbo.Dep_CustSetting3rd cs WITH(NOLOCK)			
WHERE cs.custid > @maxcustid
	AND cs.bettype = 81 AND cs.sporttype = 161	AND cs.islive=0	

-- enable all
UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
SET  HideVirtualSports= 0,
	DisableVirtualSports=1,
	maxpermatch180 = maxpermatch161
WHERE custid > @maxcustid

-- hide for 789y
UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
SET  HideVirtualSports= 1		
WHERE custid IN (
				SELECT custid
				FROM dbo.Customer c WITH (NOLOCK)
				WHERE custid > @maxcustid
					AND srecommend IN (SELECT custid FROM customer WITH(NOLOCK) WHERE site = '789y' AND roleid = 4)
				UNION 
				SELECT custid
				FROM customer WITH(NOLOCK)
				WHERE srecommend <= 100
					--AND mrecommend IN (SELECT custid FROM customer WITH(NOLOCK) WHERE site = '789y' AND roleid = 3 AND srecommend <= 100)
					AND mrecommend IN (6525,	--	MVN
										14396,	--	AE
										105371,	--	BEE
										12754,	--	A8
										1276306	--	M922U
										)	
					AND custid > 	@maxcustid				
				UNION 
				SELECT custid
				FROM customer WITH(NOLOCK)
				WHERE srecommend <= 100
					--AND mrecommend IN (SELECT custid FROM customer WITH(NOLOCK) WHERE site = '789y' AND roleid = 3 AND srecommend <= 100)
					AND recommend IN (
										select custid
										from Customer with(nolock)
										where srecommend <= 100
										and roleid = 2 and site = '789y'
									)
					AND custid > 	@maxcustid
