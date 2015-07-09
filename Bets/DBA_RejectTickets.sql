
ALTER PROCEDURE [dbo].[DBA_RejectTickets]
	@TransIDs varchar(8000),--limit to 800 tickets
	@UserID int = 8
AS
/*
create:
task: reject tickets
DB: DBTRANS.bodb02
Revision
	-- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
	-- 20110518@Lukas: Update HomeTotal, AwayTotal to Odds table
*/
CREATE TABLE #BetDelete (transid bigint PRIMARY KEY, CustID int, matchid int, bettype smallint)

INSERT INTO #BetDelete (transid, CustID, matchid, bettype)
SELECT transid, custid, matchid, bettype
FROM BetTrans with (nolock)
WHERE 
	bettrans.transid IN (select convert(bigint, val) from dbo.strSplit(@TransIDs, ',')) 	
	and 
	--status NOT IN('Void', 'Reject')
	statusID NOT IN (101,102)

--backup tickets
insert into zzzbettrans 
	(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
select transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
from  bettrans with (nolock)
where bettrans.transid IN (SELECT transid FROM #BetDelete) 

--void tickets
update  
	bettrans with (ROWLOCK, UPDLOCK)
SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Reject', statusID=101, creator = @UserID,
	awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0
where transid in (SELECT transid FROM #BetDelete)

IF EXISTS (SELECT TOP 1 1 FROM #BetDelete WHERE bettype IN (1,3,7,8))
BEGIN
	-- update totalbets
	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)

	INSERT INTO @Total
	SELECT
		oddsid,
		SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
		SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
	FROM bettrans b WITH (nolock)
		INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
	WHERE bettype in (1,3,7,8) AND ruben = 0 AND oddsid <> 0 and matchid in (SELECT DISTINCT matchid FROM #BetDelete)
	GROUP BY oddsid

	UPDATE odds WITH (rowlock, updlock)
	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	FROM @Total t WHERE odds.oddsid = t.oddsid
END

DROP TABLE #BetDelete

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_RejectTickets] TO [vnteam]