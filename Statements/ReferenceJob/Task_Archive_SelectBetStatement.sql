
USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBetStatement]    Script Date: 05/23/2013 00:00:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBetStatement]
AS

/*
	Created: unknown
	Task: Archive old statement into table Statement
	DB: DBTXN.bodb02
	Revisions:
		- 20150831@Sophia: Apply Colossus Bets - get Grand Prize [#42428] 
		- 20151113@Sophia: Add Grand Prize for Microgaming - Table PayoutTrans [RedmineId: #46450] 
		- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
	
 */

BEGIN 
	SET NOCOUNT ON 

	Declare @min_winlostdate smalldatetime,
			@max_winlostdate smalldatetime
	SELECT
		@min_winlostdate = MIN(winlostdate),
		@max_winlostdate = MAX(winlostdate)
	FROM dbo.Task_ArchiveDate

	-- custid, accdate, totalamt, transtype, transdesc
	-- Member - winlost & commission & Grand Prize
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select custid,winlostdate accdate,sum(winlost-actual_stake) totalamt,'BET' transtype, 'Betting' transdesc
		from bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,custid
		--HAVING sum(winlost-actual_stake) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select custid,winlostdate accdate,sum(playercomm) totalamt,'COM' transtype, 'Commission' transdesc
		from bettrans14 bettrans  with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,custid
		HAVING sum(playercomm) <> 0

	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
	SELECT custid, accdate, SUM(totalamt) as totalamt, 'GP' AS transtype, 'Grand Prize' AS transdesc
	FROM (
			--SELECT b.custid, b.winlostdate AS accdate, SUM(bm.winlost - bm.stake) AS totalamt
			--FROM bettrans14 b WITH (NOLOCK)
			--	INNER JOIN bettransm14 bm WITH (NOLOCK)
			--		ON b.refno = bm.refno
			--WHERE b.bettype = 18000
			--	AND b.winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
			--	AND bm.statuswinlost <> 0
			--GROUP BY b.winlostdate, b.custid
			--HAVING SUM(bm.winlost - bm.stake) <> 0

			--UNION ALL
			SELECT b.custid, b.winlostdate AS accdate, SUM(b.WinAmount) AS totalamt
			FROM dbo.PayoutTrans b WITH(NOLOCK) 
			WHERE b.winlostdate BETWEEN @min_winlostdate AND @max_winlostdate	
				  AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'			
			GROUP BY b.winlostdate, b.custid
			HAVING SUM(b.WinAmount) <> 0
		) GP
	GROUP BY custid, accdate

		

	UNION ALL
	-- Agent - position & commission
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select recommend,winlostdate accdate,sum(awinlost) totalamt,'POS' transtype, 'Position' transdesc
		from bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,recommend
		HAVING sum(awinlost) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select recommend,winlostdate accdate,sum(comm-playercomm) totalamt,'COM' transtype, 'Commission' transdesc
		from bettrans14 bettrans  with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,recommend
		HAVING sum(comm-playercomm) <> 0
	UNION ALL
	-- Master - position & commission
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select mrecommend,winlostdate accdate,sum(mwinlost) totalamt,'POS' transtype, 'Position' transdesc
		from bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,mrecommend
		HAVING sum(mwinlost) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select mrecommend,winlostdate accdate,sum(acomm-comm) totalamt,'COM' transtype, 'Commission' transdesc
		from bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,mrecommend
		HAVING sum(acomm-comm) <> 0
	UNION ALL
	-- Super - position & commission
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select srecommend,winlostdate accdate,sum(swinlost) totalamt,'POS' transtype, 'Position' transdesc
		from bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,srecommend
		HAVING sum(swinlost) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select srecommend,winlostdate accdate,sum(scomm-acomm) totalamt,'COM' transtype, 'Commission' transdesc
		from bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,srecommend
		HAVING sum(scomm-acomm) <> 0

END 
GO
