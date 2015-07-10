ALTER PROCEDURE [dbo].[Task_DailyWinlossSummary]
	@winlostdate datetime
AS
/*
Created:
Date:  
Task: Daily Winloss Summary
DB: DB053.bodb_Summary
Revisions:
    - 20110822@Sophia: Count Negative stake as positive turnover
    - 20111005@Tom: 1. Edit bet type of P2P: 72->1000
					2. Remove parameter @ABSDate '2011-09-01'
	- 20120206@Sophia: Add Sporttype for Live Casino and Number Game
	- 20120807@Sophia: Add Virtual Sports (sporttype = 180 for representing)
 */
SET NOCOUNT ON 

WHILE 1=1
BEGIN
    DELETE TOP(20000) FROM [dbo].sum_winloss_tmp where winlostdate = @winlostdate
    IF @@ROWCOUNT < 20000
        BREAK

END

INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 1,
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend, customer.username,
		SUM(case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then ABS(bettrans.stake/2) else ABS(bettrans.stake) end) TurnOver,
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
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END bettype
	FROM
		bodb02.dbo.customer with (nolock),
		bodb02.dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		bettrans.status not in ('running','waiting','VOID','REJECT','REFUND') and
		bettrans.bettype < 19999
	GROUP BY
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		customer.username,
		CASE
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END


INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 2,
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend, ag.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN bettrans.winlostdate >= @ABSDate 
				THEN case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then ABS(bettrans.stake/2) else ABS(bettrans.stake) end
				ELSE case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then bettrans.stake/2 else bettrans.stake end 
			END
			) as TurnOver,*/
		sum(case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then ABS(bettrans.stake/2) else ABS(bettrans.stake) end) TurnOver,
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
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END bettype
	FROM
		bodb02.dbo.customer with (nolock),
		bodb02.dbo.customer ag with (nolock),
		bodb02.dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		ag.custid=customer.recommend and customer.roleid=1 and ag.roleid=2 and
		bettrans.bettype < 19999
	GROUP BY
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		ag.username,
		CASE
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END


INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 3,
		ma.custid, 0 recommend, customer.mrecommend, customer.srecommend, ma.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN bettrans.winlostdate >= @ABSDate 
				THEN case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then ABS(bettrans.stake/2) else ABS(bettrans.stake) end
				ELSE case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then bettrans.stake/2 else bettrans.stake end 
			END
			) as TurnOver,*/
		sum(case when bettrans.liveawayscore = 0 and bettrans.bettype IN(33,43) then ABS(bettrans.stake/2) else ABS(bettrans.stake) end) TurnOver,
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
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162	
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport		
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END bettype
	FROM
		bodb02.dbo.customer with (nolock),
		bodb02.dbo.customer ma with (nolock),
		bodb02.dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		ma.custid=customer.mrecommend and customer.roleid=1 and ma.roleid=3 and
		bettrans.bettype < 19999
	GROUP BY
		ma.custid, customer.mrecommend, customer.srecommend, 
		ma.username,
		CASE
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END
		
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
	SELECT @winlostdate, 4,
		sa.custid, 0 recommend, 0 mrecommend, customer.srecommend, sa.username,
		/*--sum(CASE WHEN bettype = 33 AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN bettrans.winlostdate >= @ABSDate 
				THEN case when bettrans.liveawayscore = 0 and bettrans.bettype  = 33 then ABS(bettrans.stake/2) else ABS(bettrans.stake) end
				ELSE case when bettrans.liveawayscore = 0 and bettrans.bettype  = 33 then bettrans.stake/2 else bettrans.stake end 
			END
			) as TurnOver,*/
		sum(case when bettrans.liveawayscore = 0 and bettrans.bettype  = 33 then ABS(bettrans.stake/2) else ABS(bettrans.stake) end) TurnOver,
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
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END bettype
	FROM
		bodb02.dbo.customer with (nolock),
		bodb02.dbo.customer sa with (nolock),
		bodb02.dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		sa.custid=customer.srecommend and customer.roleid=1 and sa.roleid=4 and
		bettrans.bettype < 19999
	GROUP BY
		sa.custid, customer.srecommend, 
		sa.username,
		CASE
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 1000 THEN 253
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 81 AND 120 THEN 161
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,1000) THEN bettype ELSE 0 END
		
		
GO