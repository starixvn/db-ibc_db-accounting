ALTER PROCEDURE [dbo].[DBA_VoidTickets14]
	@UserID int = 360418,--dbaThien
	@TransIDs varchar(8000),--limit to 800 tickets
	@MatchID int
AS
/*
Created: 
DB: DBTRANS.bodb02
Revisions:
	- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20120604@Sophia: Update credit/debit balance
Param's Explanation:
*/


CREATE TABLE #BetDelete (transid bigint PRIMARY KEY, CustID int)

INSERT INTO #BetDelete (transid, CustID)
SELECT transid, custid
FROM BetTrans14 with (nolock)
WHERE 
	transid IN (select convert(bigint, val) from dbo.strSplit(@TransIDs, ',')) 	
	and matchid = @MatchID 	
	and statusID NOT IN (101,102)

--backup tickets
insert into zzzbettrans 
	(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
select transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
from  bettrans14 with (nolock)
where bettrans14.transid IN (SELECT transid FROM #BetDelete) 



---- create balance temp table
CREATE TABLE #BeforeUpd (
		custid		 INT,
		balance		 MONEY)
	
CREATE TABLE #AfterUpd(
			custid		 INT,
			balance		 MONEY)
			
--Get data before update
INSERT INTO #BeforeUpd (custid, balance)
SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
FROM	bettrans14 b WITH (NOLOCK)
WHERE	b.transid in (SELECT transid FROM #BetDelete)
GROUP BY b.CustID
	
--void tickets
update  
	bettrans14 with (ROWLOCK, UPDLOCK)
SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', statusID=102, creator = @UserID,
	awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0
where transid in (SELECT transid FROM #BetDelete)


--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans14 b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID

	---insert data into pending balance table 
		INSERT INTO BalancePendingCredit (custid,Balance)
		SELECT		a.custid, (a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) > 0

		INSERT INTO BalancePendingDebit (custid,Balance)
		SELECT		a.custid, ABS(a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) < 0
		
DROP TABLE #BetDelete

GO
GRANT EXECUTE ON [dbo].[DBA_VoidTickets14] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_VoidTickets14] TO [vnteam]