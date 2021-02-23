--Bettrans
UPDATE bettrans with (ROWLOCK, UPDLOCK) 
SET spositiontaking = cs.spositiontaking - b.mpositiontaking - b.apositiontaking,
	tpositiontaking = cs.spositiontaking
from bettrans b	
inner join custsetting cs with (nolock) on b.srecommend = cs.custid and cs.sporttype = 1 and cs.bettype = 1
where transid in (721691418,721731454,721935968,722784960,722787431,722851011,722911985,722936506,723057355,722821081,722914510,722913638,723024146,723110456,723091243,723068558,723060937,723054413,721843215,721845615,721593034,721643197,721643389,722761883,722789227,723704113,723096598,722450428,723545500,723637259,723782215,723780538,723792588,723737658,723713192,723702254,722284395,721983053,722715680,721986526,722169561,722169000,722185821,722178697,722767974)


UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK) SET
sWinLost = CASE
	WHEN modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -spositiontaking
	WHEN modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -spositiontaking * 0.5
	WHEN modds =  0    	THEN 0
	WHEN modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
	WHEN modds < -0.25 	THEN actual_stake * spositiontaking
	END,

sComm = CASE
	WHEN modds >  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	WHEN modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN modds =  0    	THEN 0
	WHEN modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN modds < -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	END
	
where transid in (721691418,721731454,721935968,722784960,722787431,722851011,722911985,722936506,723057355,722821081,722914510,722913638,723024146,723110456,723091243,723068558,723060937,723054413,721843215,721845615,721593034,721643197,721643389,722761883,722789227,723704113,723096598,722450428,723545500,723637259,723782215,723780538,723792588,723737658,723713192,723702254,722284395,721983053,722715680,721986526,722169561,722169000,722185821,722178697,722767974)
	AND [status] NOT IN (N'VOID', N'REJECT')

----------------------------------------------------------------------

--Bettrans14 and winlostdate = '2008-12-04'
UPDATE bettrans14 with (ROWLOCK, UPDLOCK) 
SET spositiontaking = cs.spositiontaking - b.mpositiontaking - b.apositiontaking,
	tpositiontaking = cs.spositiontaking
from bettrans14 b	
inner join custsetting cs with (nolock) on b.srecommend = cs.custid and cs.sporttype = 1 and cs.bettype = 1
where transid in (720818752,720751730,720616499,720983843,720957760,720996027,721002973,720957810,720957967,720852279,720853072,720810486,720894307,720811447,720831523,720895144,720812703,720912661,720847014,720911180,720773034,720895759,720895971,720895266,720824127,720785584,720793413)


UPDATE dbo.bettrans14 with (ROWLOCK, UPDLOCK) SET
sWinLost = CASE
	WHEN modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -spositiontaking
	WHEN modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -spositiontaking * 0.5
	WHEN modds =  0    	THEN 0
	WHEN modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
	WHEN modds < -0.25 	THEN actual_stake * spositiontaking
	END,

sComm = CASE
	WHEN modds >  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	WHEN modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN modds =  0    	THEN 0
	WHEN modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN modds < -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	END
	
where transid in (720818752,720751730,720616499,720983843,720957760,720996027,721002973,720957810,720957967,720852279,720853072,720810486,720894307,720811447,720831523,720895144,720812703,720912661,720847014,720911180,720773034,720895759,720895971,720895266,720824127,720785584,720793413)
	AND [status] NOT IN (N'VOID', N'REJECT')
