ALTER PROCEDURE [dbo].[Admin_Calculate_9]
	@matchid int,  
	@matchdate datetime  
WITH RECOMPILE  
AS  
/*
Created: 
Task : Settle bettrans based on bettransm (for mix parlay)
DB: DB02.bodb02
Original: 

Revisions:
	- 20090423@PhuongDao: Change DB04 to DB042
	- 20091201@Daniel: Check if new winlostdate from settled match > old winlostdate, proceed update with new winlostdate. Otherwise, do not update winlostdate.
	- 20091217@Thien: Discard change of [20091201@Daniel] and update winlostdate as follow
	- 20100517@Henry: Update column StatusID of Bettrans
	- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20100605@Thien: found performance issue with "AND refno IN (SELECT refno FROM @tmp_mrefno)" condition, then change to use INNER JOIN
	- 20100611@Henry: Change mix-parlay match from 0 to 9

Param's Explanation:
• @matchid: matchid of match to be settled
• @matchdate match date
*/

IF @@SERVERNAME not in ('DB04', 'DB042') 
BEGIN  
  
-- GET List of refno concern for this match  
Declare @tmp_mrefno
	TABLE (matchid int, refno bigint, statuswinlost tinyint, isdone bit)  
INSERT INTO @tmp_mrefno (matchid, refno, statuswinlost)   
	SELECT matchid, refno, statuswinlost   
	FROM dbo.bettransm  WITH (NOLOCK)  
	WHERE matchid = @matchid   


CREATE TABLE #temp_bettrans (
	[transid] [int] NOT NULL ,  
	[refno] [bigint] NOT NULL ,  
	[stake] [money] NOT NULL ,  
	[status] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,  
	[winlost] [money] NULL ,  
	[awinlost] [money] NULL ,  
	[mwinlost] [money] NULL ,  
	[swinlost] [money] NULL ,  
	[winlostdate] [smalldatetime] NULL ,  
	[apositiontaking] [smallmoney] NOT NULL ,  
	[mpositiontaking] [smallmoney] NOT NULL ,  
	[spositiontaking] [smallmoney] NOT NULL ,  
	[playerdiscount] [float] NULL ,  
	[discount] [float] NULL ,  
	[adiscount] [float] NULL,  
	[sdiscount] [float] NULL,  
	[playercomm] [money] NULL ,  
	[comm] [money] NULL ,  
	[acomm] [money] NULL,  
	[scomm] [money] NULL,  
	[ruben] [tinyint] NULL ,  
	[modds] [money] null,
	[statusID] [tinyint] NULL
)   
--create index temp_index on #temp_bettrans (TransID)  
-- GET list of concern Ticket  
INSERT INTO #temp_bettrans  
	SELECT
		[transid], b.[refno], [stake], [status],
		[winlost], [awinlost], [mwinlost], [swinlost],
		[winlostdate], [apositiontaking], [mpositiontaking], [spositiontaking],
		[playerdiscount], [discount], [adiscount], [sdiscount],
		[playercomm],  [comm], [acomm], [scomm],
		[ruben], [modds],[statusID]
	FROM dbo.bettrans b with (Nolock)  
		inner join @tmp_mrefno t on b.refno = t.refno
	WHERE 
		 --b.matchid=0 
		 b.matchid = 9
		 AND bettype=9    
		 --AND status NOT IN ('VOID','REJECT')  
		 AND statusID NOT IN (101,102)

-- Results list from both bettransm & bettransm14
Declare @parlay
	TABLE (refno bigint, matchid int, statuswinlost tinyint, statusID int, odds smallmoney, matchdate smalldatetime)
INSERT INTO @parlay
	SELECT refno, matchid, statuswinlost, statusID, odds, matchdate
	FROM dbo.bettransm with (nolock)
	WHERE refno IN (SELECT refno FROM @tmp_mrefno)
INSERT INTO @parlay
	SELECT refno, matchid, statuswinlost, statusID, odds, matchdate
	FROM dbo.bettransm14 with (nolock)
	WHERE refno IN (SELECT refno FROM @tmp_mrefno)

-- CALCULATE effective odds value  
Declare @modds
	TABLE (refno bigint, modds money, NoRefund tinyint)  
INSERT INTO @modds (refno, modds, NoRefund)
	SELECT refno,
		EXP(SUM(LOG(
		case   
			when bm.statuswinlost=0 and bm.statusID<>0 then 1  
			when bm.statuswinlost=1 and bm.statusID<>0 then 1+((bm.odds-1)/2)  
			when bm.statuswinlost=2 and bm.statusID<>0 then bm.odds  
			when bm.statuswinlost=3 and bm.statusID<>0 then 0.5  
			else 1  
		end
		))),
		SUM(
		case 
			when bm.statusID IN(121, 103) then 0			
			else 1
		end
		)
	FROM @parlay bm
	GROUP BY refno  
  
UPDATE #temp_bettrans  
SET modds = m.modds  
FROM @modds m  
WHERE #temp_bettrans.refno=m.refno  
  
------------------------------------------------------------  
------------------------------------------------------------  
/* Step of calculation  
1. Calculate WON result  
2. Update status to LOSE (win less than stake), DRAW (win = stake)
3. Reset to RUNNING for ticket contain "running" selection  
4. Reset to LOSE for ticket contain "lose" selection  
5. Reset to Refund for ticket which NoRefund = 0
*/  
-- 1. WON : cal value for win ticket  
UPDATE #temp_bettrans  
SET status='WON',  
	statusID = 112,
	ruben=1,  
	winlostdate=@matchdate,  
	winlost    =  stake*modds,   
	awinlost   = -stake*apositiontaking*(modds-1),   
	mwinlost   = -stake*mpositiontaking*(modds-1),  
	swinlost   = -stake*spositiontaking*(modds-1),  
	playercomm =  stake*playerdiscount,  
	comm  = discount*stake*(1-apositiontaking),  
	acomm =adiscount*stake*(1-apositiontaking-mpositiontaking),  
	scomm =sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)  
-------------------------------------------------------------------------------------  
-- 2. LOSE/DRAW : update status/value for LOSE/DRAW ticket 
UPDATE #temp_bettrans  
SET status='LOSE'  , statusID = 113
WHERE 
--status = 'WON' 
statusID = 112
AND winlost < stake

UPDATE #temp_bettrans  
SET status='DRAW',
	statusID = 111,
	playercomm=0,
	comm =0,
	acomm=0,
	scomm=0
WHERE 
--status = 'WON' 
statusID = 112
AND winlost = stake
-------------------------------------------------------------------------------------  

UPDATE #temp_bettrans  
SET status ='running',  
	statusID = 0,
	ruben=0,  
	modds=0,  
	winlost=0,  
	awinlost=0,  
	mwinlost=0,  
	swinlost=0,  
	playercomm=0,  
	comm =0,  
	acomm=0,  
	scomm=0
WHERE refno IN (  
	SELECT bm.refno  
	FROM dbo.bettransm bm WITH (nolock)  
	INNER JOIN @tmp_mrefno tr ON bm.refno = tr.refno  
	WHERE bm.statusID = 0
	) 

-------------------------------------------------------------------------------  
-- 4. LOSE : Ticket which lose, set value  
UPDATE #temp_bettrans  
SET status='LOSE',   
	statusID = 113,
	ruben=1,  
	winlostdate=@matchdate,  
	modds=0,  
	winlost=0,  
	awinlost=stake*apositiontaking,  
	mwinlost=stake*mpositiontaking,  
	swinlost=stake*spositiontaking,  
	playercomm=stake*playerdiscount,  
	comm = discount*stake*(1-apositiontaking),  
	acomm=adiscount*stake*(1-apositiontaking-mpositiontaking),  
	scomm=sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)  
WHERE refno IN (  
	SELECT bm.refno  
	FROM @parlay bm
	INNER JOIN @tmp_mrefno tr ON bm.refno = tr.refno  
	WHERE bm.statuswinlost = 4
	)  
-------------------------------------------------------------------------------  
-- 5. REFUND : Ticket which all details is refund (NoRefund = 0)
UPDATE #temp_bettrans  
SET status ='Refund',  
	statusID = 103,
	playercomm=0,  
	comm =0,  
	acomm=0,  
	scomm=0  
WHERE refno IN (  
	SELECT m.refno  
	FROM @modds m
	WHERE m.NoRefund = 0
	)  
-------------------------------------------------------------------------------------  
  
-- UPDATE BACK TO BETTRANS  
-- ONLY for ticket which result change OR winlost amount change
-- ONLY update winlostdate when
	--+new status is "RUNNING" --> update to max_matchdate
	--+current status is RUNNING (ruben = 0) and new status is NOT RUNNING --> update to @matchdate

--Update MAX matchdate for RUNNING tickets
UPDATE #temp_bettrans
SET winlostdate = matchdate_max
FROM 
(
	SELECT refno, MAX(matchdate) matchdate_max
	FROM @parlay
	GROUP BY refno
) bm
WHERE #temp_bettrans.refno = bm.refno
	--and #temp_bettrans.status = 'running'
	AND #temp_bettrans.statusID = 0

Declare @ruben bit
UPDATE dbo.bettrans with (UPDLOCK)  
SET status = s.status ,  
	statusID = s.statusID,
	@ruben = bettrans.ruben,
	/*
	winlostdate =	case when s.status = 'running' then s.winlostdate --max_matchdate
						when @ruben = 0 and s.status <> 'running' then @matchdate
					else bettrans.winlostdate
					end,		
	*/
	winlostdate = 	case when s.statusID = 0 then s.winlostdate --max_matchdate
						when @ruben = 0 and s.statusID <> 0 then @matchdate
					else bettrans.winlostdate
					end,					
	ruben = s.ruben,
	modds = s.modds,  
	winlost  = s.winlost,  
	awinlost = s.awinlost,  
	mwinlost = s.mwinlost,  
	swinlost = s.swinlost,  
	playercomm = s.playercomm,  
	comm  = s.comm,  
	acomm = s.acomm,  
	scomm = s.scomm  
FROM #temp_bettrans s   
WHERE bettrans.transid = s.transid  
	AND bettrans.bettype = 9 
	--AND bettrans.matchid = 0  
	AND bettrans.matchid = 9
	AND (bettrans.status <> s.status OR bettrans.winlost <> s.winlost)  
---------------------------------------------------------------  
UPDATE dbo.bettrans with (UPDLOCK)  
SET ruben=1  
WHERE 
--[status] <> N'running' 
statusID <> 0
and ruben=0 
--and matchid=0 
and matchid = 9
AND bettype=9   
---------------------------------------------------------------  
  
END -- IF @@SERVERNAME <> 'DB04'

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_9] TO [vnteam]