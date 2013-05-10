set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

/****** Object:  Stored Procedure dbo.Task_DailySummary14    Script Date: 11/29/2011 2:16:26 PM ******/
ALTER PROCEDURE [dbo].[Task_DailySummary14]
	@winlostdate datetime
AS
/*
Created:
Date: 
Task: Task_DailySummary14
DB: DBTRANS.BODB02
Revisions:
	- 20110127@Viet: Void tickets from bettrans14 for member B16T53Y1028 [ 1541593 ] dated 21 Jan 2011
	- 20110222@Thien: void ticket for S50RMB0886003, S42CHCH57111
	- 20110620@Viet: correct 1x2 tickets caused by the trouble from placebet procedure.
	- 20110816@Henry: expand bettype Number Game from 81 to 120
	- 20110822@Sophia: Count Negative stake as positive turnover
    - 20111005@Tom: 1. Edit bet type of P2P: 72->1000
					2. Remove parameter @ABSDate '2011-09-01'  
	- 20120206@Sophia: Add Sporttype for Live Casino
	- 20120807@Sophia: Add Virtual Sports (sporttype = 180 for representing)
	- 20120927@Sophia: Add column comstatus when insert into bettrans tabble
	
*/
SET NOCOUNT ON 
-- CORRECT DATA FOR M88's HORSE RACING, custid: 5120145
IF @winlostdate NOT IN ('2012-05-02') RETURN

CREATE TABLE #tmpMember (custid int, roleid tinyint)
CREATE CLUSTERED INDEX IX_2 on #tmpMember (roleid)

if @winlostdate = '2012-05-02'
BEGIN
	INSERT INTO #tmpMember (custid, roleid)
	SELECT distinct custid, 1
	FROM custinfo c (nolock)
	WHERE custid in (4595632)
	UNION ALL
	SELECT distinct recommend, 2
	FROM custinfo c (nolock)
	WHERE custid in (3114360)
	UNION ALL
	SELECT distinct mrecommend, 3
	FROM custinfo c (nolock)
	WHERE custid in (3114337)
	UNION ALL
	SELECT distinct srecommend, 4
	FROM custinfo c (nolock)
	WHERE custid in (3114255)
END
ELSE
BEGIN
	RETURN
END


-- =====================
-- DELETE EXIST SUM TRANSACTIONS
-- =====================
DELETE FROM bettrans
WHERE winlostdate=@winlostdate
	AND custid in (select custid from #tmpMember where roleid = 1)
	and bettype = 19999

DELETE FROM bettranssum WHERE winlostdate=@winlostdate

-- =====================
-- Daily Summary Process
-- =====================

-- Get Exchange Rate
DECLARE @Exchange TABLE (currency tinyint, actualrate float, CurrencyName nvarchar(50))
INSERT INTO @Exchange (currency, actualrate)
SELECT DISTINCT currency, actualrate
FROM dbo.bettrans14 with (nolock)
WHERE winlostdate = @winlostdate AND bettype < 19999
	AND custid in (select custid from #tmpMember where roleid = 1)

UPDATE @Exchange
SET CurrencyName = e.currency
FROM @Exchange ex, dbo.exchange e with (nolock)
WHERE ex.currency = e.exchangeid

-- Generate SUM record
INSERT INTO dbo.bettranssum
	(custid, currency, recommend, mrecommend, srecommend,
	winlostdate, stake, actual_stake,
	winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm)
SELECT
	custid, currency, recommend, mrecommend, srecommend,
	winlostdate, sum(stake) stake, sum(actual_stake) actual_stake,
	sum(winlost) winlost, sum(awinlost) awinlost, sum(mwinlost) mwinlost, sum(swinlost) swinlost,
	sum(playercomm) playercomm, sum(comm) comm, sum(acomm) acomm, sum(scomm) scomm
FROM
	bettrans14 with (paglock)
WHERE
	winlostdate=@winlostdate and
	bettype < 19999 and 
	[status] NOT IN ('VOID', 'REJECT')
	 AND custid in (select custid from #tmpMember where roleid = 1)
GROUP BY
	custid, currency, recommend, mrecommend, srecommend, winlostdate

insert into bettrans
	(ruben, [status], statusID, matchid, bettype, refno, creator, transdate,
	custid, currency, recommend, mrecommend, srecommend,
	winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
	actual_stake, playercomm, comm, acomm, scomm, 
	apositiontaking, mpositiontaking, spositiontaking, tpositiontaking,
	actualrate, virtualrate, Username, CurrencyName, comstatus)
select
	1, 'SUM', 142, 0, 19999, refno, 8, winlostdate,  -- 20110524@Jamie: change bettype from 99 - 19999
	b.custid, b.currency, b.recommend, b.mrecommend, b.srecommend,
	winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
	actual_stake, playercomm, comm, acomm, scomm,
	0, 0, 0, 0,
	e.actualrate, e.actualrate, c.username, e.CurrencyName, '0'
from 
	bettranssum b with (nolock)
	INNER JOIN @Exchange e ON b.currency = e.currency
	INNER JOIN dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
where
	winlostdate=@winlostdate


-- =====================
-- 20100914@Jamie: Modify for Bingo and Number Game 
-- Member level
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 1,
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend, customer.username,
		/*---sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,		*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		--sum(scomm / (1-tpositiontaking)) grosscomm,
		sum(isnull(comm/(1-apositiontaking),0)) grosscomm, --from 01-Dec-2009, apply gross commission by level
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END bettype
	FROM
		dbo.customer with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND') and
		bettrans.statusID NOT IN (0,1,102,101,103) and 
		bettrans.bettype < 19999
		AND customer.custid in (select custid from #tmpMember where roleid = 1)
	GROUP BY
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		customer.username,
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END

--AGENT LEVEL
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 2,
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend, ag.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end) as TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		--sum(scomm / (1-tpositiontaking)) grosscomm,
		sum(isnull(acomm/(1-apositiontaking - mpositiontaking),0)) grosscomm, --from 01-Dec-2009, apply gross commission by level
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END bettype
	FROM
		dbo.customer with (nolock),
		dbo.customer ag with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and 
		ag.custid=customer.recommend and customer.roleid=1 and ag.roleid=2 and
		bettrans.bettype < 19999
		AND ag.custid in (select custid from #tmpMember where roleid = 2)
	GROUP BY
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		ag.username,
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END

--MASTER LEVEL
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 3,
		ma.custid, 0 recommend, customer.mrecommend, customer.srecommend, ma.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end) as TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		sum(scomm / (1-tpositiontaking)) grosscomm,
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END bettype
	FROM
		dbo.customer with (nolock),
		dbo.customer ma with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and
		ma.custid=customer.mrecommend and customer.roleid=1 and ma.roleid=3 and
		bettrans.bettype < 19999
		AND ma.custid in (select custid from #tmpMember where roleid = 3)
	GROUP BY
		ma.custid, customer.mrecommend, customer.srecommend, 
		ma.username,
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END

--20100601: Arrange sum_winloss data for Super Level.
--SUPER LEVEL
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 4,
		sa.custid, 0 recommend, 0 mrecommend, customer.srecommend, sa.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		sum(scomm / (1-tpositiontaking)) grosscomm,
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END bettype
	FROM
		dbo.customer with (nolock),
		dbo.customer sa with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and
		sa.custid=customer.srecommend and customer.roleid=1 and sa.roleid=4 and
		bettrans.bettype < 19999
		and sa.custid in (select custid from #tmpMember where roleid = 4)
	GROUP BY
		sa.custid, customer.srecommend, 
		sa.username,
		CASE
			WHEN bettype = 71 THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype = 73 THEN 252 --Bingo
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162  --- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,73,1000) THEN bettype ELSE 0 END

-- =====================

SET NOCOUNT ON

WHILE 1=1
BEGIN
	DELETE TOP(280) FROM dbo.sum_winloss
	WHERE winlostdate = @winlostdate
		and custid in (select custid from #tmpMember)

	IF @@ROWCOUNT < 280
		BREAK

	WAITFOR DELAY '000:00:01.4'
END

WHILE 1=1
BEGIN
	DELETE TOP(280) FROM dbo.sum_winloss_tmp
	WHERE winlostdate = @winlostdate
	
	IF @@ROWCOUNT < 280
		BREAK

	WAITFOR DELAY '000:00:01.4'
END

SET NOCOUNT OFF

DROP TABLE #tmpMember

PRINT CONVERT(varchar(10), @winlostdate, 120)

GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailySummary14] TO [vnteam]



