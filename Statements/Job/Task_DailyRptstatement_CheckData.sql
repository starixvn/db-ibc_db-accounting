USE [bodb_Report]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailyRptStatement_CheckData]    Script Date: 07/19/2015 22:22:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailyRptStatement_CheckData]
	@winlostdate DATE
	,@isCheckDataOnly BIT
AS
/*  
 Created:	20141202@Tom.Vo
 Task :		check data on rptStatement table
 DB:		DBRPT.bodb_Report
 Original:  
  
 Revisions:
	- @20150311@Tom: Change option ReadPast to NOLOCK when select data on bettrans table
	- @20150402@Tom: Change option NOLOCK to ROWLOCK table hint when select on bettrans to prevent dirty read by NOLOCK
	- 20150727@Sophia: Apply Bettrade, exclude ticket Bettrade Comm (903) for Void/reject [#36905]
	- 20150901@Sophia: Apply Colossus Bets [#42428]
	- 20151019@Sophia: Apply AG Casino - Add table BettransLC [#43810]
					   Apply MGC - RNG Casino - Add table BettransRNG [#43549]						 
	- 20151109@Sophia: Change Sporttype of Microgaming RNG Casino [RedmineId: #46450] 
	- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentBU_Date DATETIME
	DECLARE @CurrentMO_Date DATETIME

	SELECT TOP 1 @CurrentBU_Date = winlostdate
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE matchid = 0
		AND bettype = 20000

	SELECT TOP 1 @CurrentMO_Date =  max(eventdate)
	FROM bodb02.dbo.match14 WITH (NOLOCK)

	IF NOT (@winlostdate >= @CurrentBU_Date 
		AND @winlostdate <= @CurrentMO_Date) 
	BEGIN
		SELECT 999 ErrorCode
			,'Parameter Winlostdate invalid!!!!' ErrorMsg
		RETURN
	END 

	IF OBJECT_ID('tempdb..#tmpCustMiss') IS NOT NULL 
	BEGIN
		DROP TABLE #tmpCustMiss
	END

	CREATE TABLE #tmpCustMiss (
		Custid INT
		,Amount MONEY NULL
		,ErrCode INT --1: Not Exists | 2: Sum WL-TO  | 10: Transfer | 20: Opening Balance | 30: Void/ Cancelled Bet
		)

	CREATE CLUSTERED INDEX ErrCode ON #tmpCustMiss (ErrCode )

	IF OBJECT_ID('tempdb..#tmpOpeningBalance') IS NOT NULL
	BEGIN
		DROP TABLE #tmpOpeningBalance
	END

	CREATE TABLE #tmpOpeningBalance (
		Custid INT
		,OpeningBalance MONEY
		)
	 
	IF OBJECT_ID('tempdb..#tmpStatement') IS NOT NULL
	BEGIN
		DROP TABLE #tmpStatement
	END

	CREATE TABLE #tmpStatement (
			Custid				INT
			,OpeningBalance		MONEY	NULL
			,Turnover			MONEY	NULL
			,netTurnover		MONEY	NULL
			,TransferAmt		MONEY	NULL
			,VoidAmt			MONEY	NULL
			,Winlost			MONEY	NULL
			,Comm				MONEY	NULL
			,ClosingBalance		MONEY	NULL
			,GrandPrize			MONEY	NULL
			,ErrCode			INT
		)

	--STEP 01. Check Data sum_winloss and [rptStatement]
		
	IF OBJECT_ID('tempdb..#tmpSumWL') IS NOT NULL
	BEGIN
		DROP TABLE #tmpSumWL
	END

	CREATE TABLE #tmpSumWL (
		Custid				INT
		,Turnover			MONEY	NULL
		,netTurnover		MONEY	NULL
		,Winlost			MONEY	NULL
		,Comm				MONEY	NULL
	)

	-- 1: get sum data from Bettrans into rptStatement
	-- Member
	INSERT INTO #tmpSumWL(
		Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
	)
	SELECT
		custid
		,SUM(CASE WHEN statusID NOT IN(103) 
			  THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END 
			  ELSE 0 END) AS Turnover
		,0 AS netTurnover
		,SUM(winlost - actual_stake) AS winlost
		,SUM(playercomm) AS comm
	FROM
		bodb02.dbo.Bettrans14 bt WITH(NOLOCK)	
	WHERE
		winlostdate = @Winlostdate
		AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bettype <= 19999
		AND ruben = 1
	GROUP BY
		custid
		
	-- Agent
	INSERT INTO #tmpSumWL(
		Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
	)
	SELECT
		cu.recommend
		,SUM(CASE WHEN bt.statusID NOT IN(103) 
			  THEN CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake)/2 ELSE ABS(bt.stake) END
			  ELSE 0 END) AS Turnover
		,SUM(CASE WHEN bt.statusID NOT IN(103) 
			  THEN CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake*bt.apositiontaking)/2 ELSE ABS(bt.stake*bt.apositiontaking) END 
			  ELSE 0 END) AS netTurnover
		,SUM(bt.awinlost) AS winlost
		,SUM(bt.comm - bt.playercomm) AS comm
	FROM
		bodb02.dbo.Bettrans14 bt WITH(NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo cu WITH(NOLOCK)	ON bt.CustID = cu.CustID
	WHERE
		bt.winlostdate = @Winlostdate
		AND bt.statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bt.bettype <= 19999
		AND bt.ruben = 1
	GROUP BY
		cu.recommend

	-- Master
	INSERT INTO #tmpSumWL(
		Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
	)
	SELECT
		cu.mrecommend
		,SUM(CASE WHEN bt.statusID NOT IN(103) 
			  THEN CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake)/2 ELSE ABS(bt.stake) END 
			  ELSE 0 END) AS Turnover
		,SUM(CASE WHEN bt.statusID NOT IN(103) 
			  THEN CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake*bt.mpositiontaking)/2 ELSE ABS(bt.stake*bt.mpositiontaking) END 
			  ELSE 0 END) AS netTurnover
		,SUM(bt.mwinlost) AS winlost
		,SUM(bt.acomm - bt.comm) AS comm			
	FROM
		bodb02.dbo.Bettrans14 bt WITH(NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo cu WITH(NOLOCK)	ON bt.CustID = cu.CustID
	WHERE
		bt.winlostdate = @Winlostdate
		AND bt.statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bt.bettype <= 19999
		AND bt.ruben = 1
	GROUP BY
		cu.mrecommend

	-- Super
	INSERT INTO #tmpSumWL(
		Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
	)
	SELECT
		cu.srecommend
		,SUM(CASE WHEN bt.statusID NOT IN(103) 
			  THEN CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake)/2 ELSE ABS(bt.stake) END
			  ELSE 0 END) AS Turnover
		,SUM(CASE WHEN bt.statusID NOT IN(103) 
			  THEN CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake*bt.spositiontaking)/2 ELSE ABS(bt.stake*bt.spositiontaking) END 
			  ELSE 0 END) AS netTurnover
		,SUM(bt.swinlost) AS winlost
		,SUM(bt.scomm - bt.acomm) AS comm
	FROM
		bodb02.dbo.Bettrans14 bt WITH(NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo cu WITH(NOLOCK)	ON bt.CustID = cu.CustID
	WHERE
		bt.winlostdate = @Winlostdate
		AND bt.statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bt.bettype <= 19999
		AND bt.ruben = 1
	GROUP BY
		cu.srecommend

	INSERT INTO #tmpCustMiss (
		Custid
		,ErrCode
		)
	SELECT su.Custid
		,1 ErrCode
	FROM #tmpSumWL su
		LEFT JOIN [dbo].[rptStatement] rpt WITH (NOLOCK) ON @Winlostdate= rpt.[winlostdate]
		AND su.custid = rpt.custid
	WHERE rpt.Custid IS NULL 
	GROUP BY su.Custid
	 
	INSERT INTO #tmpCustMiss (
		Custid
		,ErrCode
		)
	SELECT su.Custid
		,2 ErrCode
	FROM #tmpSumWL su
		LEFT JOIN [dbo].[rptStatement] rpt WITH (NOLOCK) ON @Winlostdate = rpt.[winlostdate]
		AND su.custid = rpt.custid	
		LEFT JOIN #tmpCustMiss tmpCust ON su.custid = tmpCust.custid
		AND tmpCust.ErrCode = 1
	WHERE tmpCust.CustID IS NULL
		AND (
			ABS(ISNULL(rpt.[Turnover], 0) - ISNULL(su.[Turnover], 0)) > 0
			OR ABS(ISNULL(rpt.NetTurnover, 0) - ISNULL(su.NetTurnover, 0)) > 0
			OR ABS(ISNULL(rpt.Winlost, 0) - ISNULL(su.Winlost, 0)) > 0
			OR ABS(ISNULL(rpt.comm, 0) - ISNULL(su.comm, 0)) > 0
			OR rpt.Custid IS NULL
			)

	--STEP 02. Check TransferAmt Data rptStatement and [sum_winloss] 
	INSERT INTO #tmpCustMiss (
		Custid
		,Amount
		,ErrCode
		)
	SELECT tmpTr.Custid
		,tmpTr.TransferAmt Amount
		,10 ErrCode
	FROM (
		SELECT @winlostdate winlostdate
			,custid
			,SUM(winlost - actual_stake) AS TransferAmt
		FROM bodb02.dbo.bettrans WITH (ROWLOCK)
		WHERE matchid = 0
			AND bettype > 20000
			AND bettype NOT IN (23001, 23002, 23101, 23102, 23201, 23202)
			AND winlostdate = @winlostdate
		GROUP BY custid
		) tmpTr
		LEFT JOIN [dbo].[rptStatement] rpt WITH (NOLOCK) 
			ON tmpTr.[winlostdate] = rpt.[winlostdate]
				AND tmpTr.custid = rpt.custid
	WHERE  (
			ABS(ISNULL(rpt.TransferAmt, 0) - ISNULL(tmpTr.TransferAmt, 0)) > 0
			OR rpt.TransferAmt IS NULL
			)

	--STEP 03. Check Opening Balance
	IF (@Winlostdate = @CurrentBU_Date)
	BEGIN
		INSERT INTO #tmpOpeningBalance (
			Custid
			,OpeningBalance
			)
		SELECT bt.custid
			,SUM(winlost - actual_stake) AS OpeningBalance
		FROM bodb02.dbo.bettrans bt WITH (ROWLOCK)
		WHERE winlostdate = @CurrentBU_Date
			AND bettype = 20000
		GROUP BY bt.custid
	END
	ELSE -- winlostdate > CurrentBU_Date
	BEGIN
		-- Opening Balance for Member
		INSERT INTO #tmpOpeningBalance (
			Custid
			,OpeningBalance
			)
		SELECT bt.custid
			,SUM(winlost - actual_stake + playercomm) AS OpeningBalance
		FROM bodb02.dbo.bettrans bt WITH (ROWLOCK)
		WHERE ruben = 1
			AND bt.winlostdate >= @CurrentBU_Date
			AND bt.winlostdate < @Winlostdate
			AND bt.custid <> bt.recommend
			AND bt.custid <> bt.mrecommend
			AND bt.custid <> bt.srecommend
		GROUP BY bt.custid

		-- Opening Balance for Agent
		INSERT INTO #tmpOpeningBalance (
			Custid
			,OpeningBalance
			)
		SELECT bt.recommend
			,SUM(CASE 
					WHEN bt.custid = recommend THEN winlost - actual_stake
					ELSE awinlost + comm - playercomm
					END) AS OpeningBalance
		FROM bodb02.dbo.bettrans bt WITH (ROWLOCK)
		WHERE ruben = 1
			AND bt.winlostdate >= @CurrentBU_Date
			AND bt.winlostdate < @Winlostdate
		GROUP BY bt.recommend

		-- Opening Balance for Master
		INSERT INTO #tmpOpeningBalance (
			Custid
			,OpeningBalance
			)
		SELECT bt.mrecommend
			,SUM(CASE 
					WHEN bt.custid = mrecommend THEN winlost - actual_stake
					ELSE mwinlost + acomm - comm
					END) AS OpeningBalance
		FROM bodb02.dbo.bettrans bt WITH (ROWLOCK)
		WHERE ruben = 1
			AND bt.winlostdate >= @CurrentBU_Date
			AND bt.winlostdate < @Winlostdate
		GROUP BY bt.mrecommend

		-- Opening Balance for Super
		INSERT INTO #tmpOpeningBalance (
			Custid
			,OpeningBalance
			)
		SELECT bt.srecommend
			,SUM(CASE 
					WHEN bt.custid = srecommend THEN winlost - actual_stake
					ELSE swinlost + scomm - acomm
					END) AS OpeningBalance
		FROM bodb02.dbo.bettrans bt WITH (ROWLOCK)
		WHERE ruben = 1
			AND bt.winlostdate >= @CurrentBU_Date
			AND bt.winlostdate < @Winlostdate
		GROUP BY bt.srecommend
	END

	CREATE CLUSTERED INDEX CustId ON #tmpOpeningBalance (CustId)	
	------------------------------------------------------------

	INSERT INTO #tmpCustMiss (
		Custid
		,Amount
		,ErrCode
		)
	SELECT DISTINCT tmpCust.Custid
		,ISNULL(tmpOP.OpeningBalance,0) OpeningBalance
		,3 ErrCode
	FROM #tmpCustMiss tmpCust
		LEFT JOIN  #tmpOpeningBalance tmpOP
		ON tmpOP.Custid = tmpCust.Custid 
	WHERE tmpCust.ErrCode <> 3


	INSERT INTO #tmpCustMiss (
		Custid
		,Amount
		,ErrCode
		)
	SELECT  tmp.Custid
		,tmp.OpeningBalance
		,20 ErrCode
	FROM #tmpOpeningBalance tmp
		LEFT JOIN [dbo].[rptStatement] rpt WITH (NOLOCK) ON tmp.custid = rpt.custid
		AND rpt.[winlostdate] = @winlostdate
		LEFT JOIN #tmpCustMiss tmpO ON tmpO.Custid = tmp.Custid AND tmpO.ErrCode = 3
	WHERE ABS(ISNULL(tmp.OpeningBalance, 0) - ISNULL(rpt.OpeningBalance, 0)) > 0
		AND tmpO.Custid IS NULL

	INSERT INTO #tmpCustMiss (
		Custid
		,Amount
		,ErrCode
		)
	SELECT  rpt.Custid
		,ISNULL(tmp.OpeningBalance,0) OpeningBalance
		,20 ErrCode
	FROM [dbo].[rptStatement] rpt WITH (NOLOCK)
		LEFT JOIN #tmpOpeningBalance tmp ON tmp.custid = rpt.custid	
		LEFT JOIN #tmpCustMiss tmpO ON tmpO.Custid = rpt.Custid AND tmpO.ErrCode = 3
	WHERE rpt.[winlostdate] = @winlostdate
		AND ABS(ISNULL(tmp.OpeningBalance, 0) - ISNULL(rpt.OpeningBalance, 0)) > 0
		AND tmpO.Custid IS NULL

	IF OBJECT_ID('tempdb..#tmpOpeningBalance') IS NOT NULL
	BEGIN
		DROP TABLE #tmpOpeningBalance
	END 

	--STEP 04: Void/ Cancelled Bet - get data from Bettrans14
	INSERT INTO #tmpCustMiss (
		Custid
		,Amount
		,ErrCode
		)
	SELECT tmpVoid.Custid
		,tmpVoid.VoidAmt Amount
		,30 ErrCode
	FROM 
		(
		SELECT 
			bt.custid custid
			,SUM(CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake)/2 ELSE ABS(bt.stake) END) AS VoidAmt
		FROM 
			bodb02.dbo.Bettrans14  bt WITH(NOLOCK)
			--INNER JOIN bodb02.dbo.match14 match (nolock)
			--	ON bt.matchid = match.matchid				
		WHERE 
			bt.bettype <= 19000
			AND bt.bettype <> 903
			AND bt.winlostdate = @winlostdate
			AND bt.statusID in (101, 102) -- 'VOID','REJECT'
		GROUP BY custid
		) tmpVoid 
	LEFT JOIN [dbo].[rptStatement] rpt WITH (NOLOCK) 	
		ON rpt.Custid = tmpVoid.Custid
			AND rpt.winlostdate = @winlostdate
	WHERE ABS(ISNULL(tmpVoid.VoidAmt, 0) - ISNULL(rpt.VoidAmt, 0)) > 0
		
		

	--STEP 05: Grand Prize
	INSERT INTO #tmpCustMiss (
		Custid
		,Amount
		,ErrCode
		)
	SELECT tmpGrandPrize.Custid
		,tmpGrandPrize.GrandPrize AS Amount
		,40 ErrCode
	FROM 
		(
			--SELECT 
			--	bt.custid custid
			--	,SUM(bm.winlost - bm.stake) AS GrandPrize
			--FROM 
			--	bodb02.dbo.Bettrans14 bt WITH(NOLOCK)
			--	INNER JOIN bodb02.dbo.bettransM14 bm (nolock)
			--		ON bt.RefNo = bm.RefNo				
			--WHERE 
			--	bt.bettype = 18000
			--	AND bt.winlostdate = @winlostdate
			--	AND bt.statusID in (101, 102) -- 'VOID','REJECT'
			--	AND bm.statuswinlost <> 0
			--GROUP BY bt.custid

			--UNION ALL

			SELECT  custid
					,SUM(WinAmount) AS GrandPrize
			FROM	DBACC.bodb02.dbo.PayoutTrans WITH(NOLOCK) 
			WHERE	winlostdate = @Winlostdate	
					AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'			
			GROUP BY custid

		) tmpGrandPrize 
	LEFT JOIN [dbo].[rptStatement] rpt WITH (NOLOCK) 	
		ON rpt.Custid = tmpGrandPrize.Custid
			AND rpt.winlostdate = @winlostdate
	WHERE ABS(ISNULL(tmpGrandPrize.GrandPrize, 0) - ISNULL(rpt.GrandPrize, 0)) > 0




	/*Insert data into tmpStatement temp table*/
	
	INSERT INTO #tmpStatement (
		Custid
		,OpeningBalance
		,Turnover
		,netTurnover
		,TransferAmt
		,Winlost
		,Comm
		,ClosingBalance
		,ErrCode
	)
	SELECT 	tmp.Custid	
		,ISNULL(tmpO.Amount,0) OpeningBalance
		,tblsum.Turnover
		,tblsum.netTurnover
		,NULL TransferAmt
		,tblsum.Winlost
		,tblsum.Comm
		,NULL ClosingBalance 
		,1 ErrCode
	FROM #tmpCustMiss tmp
	INNER JOIN #tmpSumWL tblsum ON tblsum.custid = tmp.custid
	LEFT JOIN #tmpCustMiss tmpO 
		ON tmpO.custid = tmp.custid AND tmpO.ErrCode = 3
	WHERE tmp.ErrCode IN  (1, 2 ) 

	IF OBJECT_ID('tempdb..#tmpSumWL') IS NOT NULL
	BEGIN
		DROP TABLE #tmpSumWL
	END	

	INSERT INTO #tmpStatement (
		Custid
		,TransferAmt
		,ErrCode
	)
	SELECT 	tmp.Custid	
		,Amount
		,10 ErrCode
	FROM #tmpCustMiss tmp
	WHERE tmp.ErrCode IN  (10)

	INSERT INTO #tmpStatement (
		Custid
		,OpeningBalance
		,ErrCode
	)
	SELECT 	tmp.Custid	
		,Amount
		,20 ErrCode
	FROM #tmpCustMiss tmp
	WHERE tmp.ErrCode IN  (20 )

	INSERT INTO #tmpStatement (
		Custid
		,VoidAmt
		,ErrCode
	)
	SELECT 	tmp.Custid	
		,Amount
		,30 ErrCode
	FROM #tmpCustMiss tmp
	WHERE tmp.ErrCode IN  (30 )

	INSERT INTO #tmpStatement (
		Custid
		,GrandPrize
		,ErrCode
	)
	SELECT 	tmp.Custid	
		,Amount
		,40 ErrCode
	FROM #tmpCustMiss tmp
	WHERE tmp.ErrCode IN  (40)


	IF OBJECT_ID('tempdb..#tmpCustMiss') IS NOT NULL 
	BEGIN
		DROP TABLE #tmpCustMiss
	END
	 
	CREATE CLUSTERED INDEX ErrCode ON #tmpStatement (ErrCode)
	CREATE NONCLUSTERED INDEX CustId ON #tmpStatement (CustId)
	
	--Show up data 
	IF @isCheckDataOnly = 1
	BEGIN
		IF EXISTS(SELECT TOP 1 1FROM #tmpStatement tmpSta
					WHERE tmpSta.ErrCode  IN (1,40))
		BEGIN
			SELECT 
				'Wrong W/L-TO-Grand Prize' Reason
				,Custid
				,OpeningBalance
				,Turnover
				,netTurnover
				,Winlost
				,Comm
				,TransferAmt
				,ClosingBalance
				,GrandPrize 
			FROM #tmpStatement tmpSta
			WHERE tmpSta.ErrCode IN (1,40)
		END 
			
		IF EXISTS(SELECT TOP 1 1FROM #tmpStatement tmpSta
					WHERE tmpSta.ErrCode = 10)
		BEGIN
			SELECT 
				'Wrong Transfer' Reason
				,tmpSta.Custid
				,tmpSta.TransferAmt TransferAmt_after
				,rpt.TransferAmt	TransferAmt_before
			FROM #tmpStatement tmpSta
				LEFT JOIN [dbo].[rptStatement] rpt WITH(NOLOCK)
				ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID
			WHERE tmpSta.ErrCode = 10
		END 
			
		IF EXISTS(SELECT TOP 1 1FROM #tmpStatement tmpSta
				INNER JOIN [dbo].[rptStatement] rpt WITH(NOLOCK)
					ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID AND tmpSta.ErrCode = 20
					)
		BEGIN	
			SELECT 
				'Wrong Opening Balance' Reason
				,tmpSta.Custid
				,tmpSta.OpeningBalance	OpeningBalance_After
				,rpt.OpeningBalance	OpeningBalance_before
			FROM #tmpStatement tmpSta
				INNER JOIN [dbo].[rptStatement] rpt WITH(NOLOCK)
				ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID AND tmpSta.ErrCode = 20
		END 	
			
		IF EXISTS(SELECT TOP 1 1FROM #tmpStatement tmpSta
					WHERE tmpSta.ErrCode = 30)
		BEGIN	
			SELECT 
				'Wrong Void/Delete/Cancel' Reason
				,tmpSta.Custid
				,tmpSta.VoidAmt VoidAmt_after
				,rpt.VoidAmt	VoidAmt_before
			FROM #tmpStatement tmpSta
				LEFT JOIN [dbo].[rptStatement] rpt WITH(NOLOCK)
				ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID
			WHERE tmpSta.ErrCode = 30
		END
		
	END

	--Correct data 
	IF @isCheckDataOnly = 0
	BEGIN
		UPDATE rpt
		SET rpt.OpeningBalance = tmpSta.OpeningBalance 
			,rpt.Turnover = tmpSta.Turnover 
			,rpt.netTurnover = tmpSta.netTurnover 
			,rpt.Winlost = tmpSta.Winlost 
			,rpt.Comm = tmpSta.Comm 
			,rpt.ClosingBalance = ISNULL(tmpSta.OpeningBalance,0) +ISNULL(rpt.TransferAmt,0) +ISNULL(tmpSta.Winlost,0) +ISNULL(tmpSta.Comm,0)
		FROM [dbo].[rptStatement] rpt WITH(ROWLOCK,UPDLOCK)
		INNER JOIN   #tmpStatement tmpSta
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID AND tmpSta.ErrCode = 1

		INSERT INTO [dbo].[rptStatement] (
			WinlostDate
			,Custid
			,OpeningBalance
			,Turnover
			,netTurnover
			,Winlost
			,Comm
			,ClosingBalance
		)
		SELECT 
			@WinlostDate WinlostDate
			,tmpSta.Custid
			,ISNULL(tmpSta.OpeningBalance,0) OpeningBalance
			,tmpSta.Turnover
			,tmpSta.netTurnover
			,tmpSta.Winlost
			,tmpSta.Comm
			,ISNULL(tmpSta.OpeningBalance,0) +ISNULL(tmpSta.Winlost,0) +ISNULL(tmpSta.Comm,0) AS ClosingBalance
		FROM   #tmpStatement tmpSta	
			LEFT JOIN [dbo].[rptStatement] rpt WITH(ROWLOCK,UPDLOCK)	
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID
		WHERE rpt.CustID IS NULL AND tmpSta.ErrCode = 1
		 
		UPDATE rpt
		SET rpt.TransferAmt = tmpSta.TransferAmt  
			,rpt.ClosingBalance = ISNULL(rpt.OpeningBalance,0)  +ISNULL(tmpSta.TransferAmt,0) +ISNULL(rpt.Winlost,0) +ISNULL(rpt.Comm,0)
		FROM [dbo].[rptStatement] rpt WITH(ROWLOCK,UPDLOCK)
		INNER JOIN   #tmpStatement tmpSta
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID AND tmpSta.ErrCode = 10

		INSERT INTO [dbo].[rptStatement] (
			WinlostDate
			,OpeningBalance
			,Custid
			,TransferAmt
			,ClosingBalance
		)
		SELECT 
			@WinlostDate WinlostDate
			,0 OpeningBalance
			,tmpSta.Custid
			,tmpSta.TransferAmt
			,tmpSta.TransferAmt AS ClosingBalance
		FROM   #tmpStatement tmpSta	
			LEFT JOIN [dbo].[rptStatement] rpt WITH(ROWLOCK,UPDLOCK)	
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID
		WHERE rpt.CustID IS NULL AND tmpSta.ErrCode = 10	

		UPDATE rpt
		SET rpt.ClosingBalance =  ISNULL(tmpSta.OpeningBalance,0)  +ISNULL(rpt.TransferAmt,0) +ISNULL(rpt.Winlost,0) +ISNULL(rpt.Comm,0)
			,rpt.OpeningBalance = tmpSta.OpeningBalance  
		FROM [dbo].[rptStatement] rpt WITH(ROWLOCK,UPDLOCK)
		INNER JOIN   #tmpStatement tmpSta
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID AND tmpSta.ErrCode = 20

		IF	DATEPART(DW,@WinlostDate)=7
		BEGIN
			INSERT INTO [dbo].[rptStatement] (
				WinlostDate
				,OpeningBalance
				,Custid
				,ClosingBalance
			)
			SELECT 
				@WinlostDate WinlostDate
				,tmpSta.OpeningBalance
				,tmpSta.Custid
				,tmpSta.OpeningBalance AS ClosingBalance
			FROM   #tmpStatement tmpSta	
				LEFT JOIN [dbo].[rptStatement] rpt
				ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID
			WHERE rpt.CustID IS NULL 
				AND tmpSta.ErrCode = 20
		END
		
				
		UPDATE rpt
		SET rpt.VoidAmt = tmpSta.VoidAmt  
		FROM [dbo].[rptStatement] rpt WITH(ROWLOCK,UPDLOCK)
		INNER JOIN   #tmpStatement tmpSta
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID AND tmpSta.ErrCode = 30


		INSERT INTO [dbo].[rptStatement] (
			WinlostDate
			,OpeningBalance
			,Custid
			,ClosingBalance
		)
		SELECT 
			@WinlostDate WinlostDate
			,tmpSta.OpeningBalance
			,tmpSta.Custid
			,tmpSta.OpeningBalance AS ClosingBalance
		FROM   #tmpStatement tmpSta	
			LEFT JOIN [dbo].[rptStatement] rpt
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID
		WHERE rpt.CustID IS NULL 
			AND tmpSta.ErrCode = 20
			AND tmpSta.Custid IN (SELECT Custid FROM #tmpStatement tmpSta WHERE tmpSta.ErrCode = 30)
	
	
		---------
		UPDATE rpt
		SET rpt.GrandPrize = tmpSta.GrandPrize  
		FROM [dbo].[rptStatement] rpt WITH(ROWLOCK,UPDLOCK)
		INNER JOIN   #tmpStatement tmpSta
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID AND tmpSta.ErrCode = 40

			
		INSERT INTO [dbo].[rptStatement] (
			WinlostDate
			,Custid
			,GrandPrize
		)
		SELECT 
			@WinlostDate WinlostDate
			,tmpSta.Custid
			,tmpSta.GrandPrize AS GrandPrize
		FROM   #tmpStatement tmpSta	
			LEFT JOIN [dbo].[rptStatement] rpt
			ON rpt.WinlostDate = @WinlostDate AND rpt.CustID = tmpSta.CustID
		WHERE rpt.CustID IS NULL 
			  AND tmpSta.ErrCode = 40
			
		
	END
	 
	IF OBJECT_ID('tempdb..#tmpStatement') IS NOT NULL
	BEGIN
		DROP TABLE #tmpStatement
	END
END
GO
