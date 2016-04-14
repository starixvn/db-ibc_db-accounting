USE bodb_report 

--TRUNCATE TABLE [dbo].[rptStatement_Old]

GO
SET NOCOUNT ON

BEGIN

	DECLARE @FromDate DATETIME='2014-9-5 00:00:00.000'
		,@ToDate DATETIME
		
	SELECT @ToDate ='2014-12-20 00:00:00.000'

	-- Opening Balance for rptStatement
	DECLARE @CurrentBU_Date DATETIME

	SELECT TOP 1 @CurrentBU_Date = WinlostDate  
	FROM bodb02.dbo.bettrans WITH(NOLOCK) 
	WHERE matchid = 0 AND bettype = 20000	

	IF @ToDate > @CurrentBU_Date
	BEGIN
		SET @ToDate = @CurrentBU_Date
	END

	DECLARE
		@winlostdate DATETIME=@FromDate
		,@date_7 DATE=DATEADD(DD, - 7, @FromDate)
		,@date_yesterday DATE=DATEADD(DD, - 1, @FromDate)

	DECLARE @Step INT

	SELECT @Step = 0 --0: ALL 1: Winloss 2:Void/Cancel 3: Opening Balance 4: Transfers
  
	IF OBJECT_ID('tempdb..#rptStatementTable') IS NOT NULL
	BEGIN
		DROP TABLE #rptStatementTable
	END

	CREATE TABLE #rptStatementTable (
		Winlostdate DATE
		,Custid INT
		,Openingbalance MONEY NULL
		,Voidamt MONEY NULL
		,Turnover MONEY NULL
		,NetTurnover MONEY NULL
		,Transferamt MONEY NULL
		,Winlost MONEY NULL
		,Comm MONEY NULL
		,ClosingBalance MONEY NULL
		,BetCount INT NULL
	)

	WHILE( @winlostdate <= @ToDate)
	BEGIN
		IF DATEPART(DW, @winlostdate) <> 7
		BEGIN
			SELECT @CurrentBU_Date = DATEADD(DD, - DATEPART(DW, @winlostdate), @winlostdate)
		END		

		--1: Winloss
		IF (@Step = 1 OR @Step = 0)
		BEGIN
			-- get SUM data from SUM_winloss into rptStatement
			INSERT INTO #rptStatementTable(
				Winlostdate
				,Custid
				,Turnover
				,NetTurnover
				,Winlost
				,Comm
				,BETCOUNT
			)

			SELECT
				@winlostdate winlostdate
				,tblsum.custid
				,SUM(tblsum.Turnover) AS Turnover
				,SUM(tblsum.NetTurnover) AS NetTurnover
				,SUM(CASE WHEN tblsum.roleid = 1 THEN tblsum.winlost 
						  WHEN tblsum.roleid = 2 THEN tblsum.awinlost 
						  WHEN tblsum.roleid = 3 THEN tblsum.mwinlost 
						  ELSE tblsum.swinlost 
					END) AS Winlost
				,SUM(CASE WHEN tblsum.roleid = 1 THEN tblsum.playercomm 
						  WHEN tblsum.roleid = 2 THEN tblsum.comm - tblsum.playercomm
						  WHEN tblsum.roleid = 3 THEN tblsum.acomm - tblsum.comm
						  ELSE tblsum.scomm - tblsum.acomm
					END) AS comm
				,SUM(betcount) AS betcount
			FROM
				DBSUM.bodb_Summary.dbo.[sum_winloss_old] tblsum WITH(NOLOCK)
			WHERE
				tblsum.winlostdate = @winlostdate 		
			GROUP BY
				tblsum.custid

		END
		
		--2:Void/Cancel
		IF (@Step = 2 OR @Step = 0)
		BEGIN
			--Get Sum data Member
			INSERT INTO #rptStatementTable(
				Winlostdate
				,Custid
				,Voidamt
				,BETCOUNT
			)
			SELECT @winlostdate Winlostdate
				,bt.custid
				,SUM(CASE WHEN bt.liveawayscore = 0 AND bt.bettype IN(33,43) THEN ABS(bt.stake)/2 ELSE ABS(bt.stake) END) AS Voidamt
				,COUNT(1) BETCOUNT
			FROM
				bodb_archive.dbo.bettrans_bk bt WITH(NOLOCK)
			WHERE 
				bt.winlostdate = @winlostdate
				AND bt.statusID IN(101,102) 
			GROUP BY
				bt.custid 
			
		END		

		--3: Opening Balance
		IF (@Step = 3 OR @Step = 0)
		BEGIN
			--Get data source from rptStatement_Old
			IF EXISTS(SELECT TOP 1 1 FROM [dbo].[rptStatement_Old] WITH(NOLOCK))
			BEGIN
				INSERT INTO #rptStatementTable(
					Winlostdate
					,Custid
					,Openingbalance
				)
				SELECT @winlostdate Winlostdate
					,rpt.custid Custid
					,rpt.[ClosingBalance] Openingbalance
				FROM dbo.[rptStatement_Old] rpt WITH (NOLOCK)
					INNER JOIN (
						SELECT MAX(rpt.Winlostdate) [WinlostDate]
							,rpt.custid
						FROM dbo.[rptStatement_Old] rpt WITH (NOLOCK)
						WHERE  rpt.Winlostdate BETWEEN @date_7 AND @date_yesterday
						GROUP BY rpt.custid
						) tmpRpt ON tmpRpt.[WinlostDate] = rpt.[WinlostDate]
						AND tmpRpt.Custid = rpt.CustID			
				WHERE rpt.[WinlostDate]  BETWEEN @date_7 AND @date_yesterday
			END
			ELSE
			BEGIN
				--GET last Balance day 
				IF DATEPART(DW, @winlostdate) <> 7
				BEGIN
					SELECT @CurrentBU_Date = DATEADD(DD, - DATEPART(DW, @winlostdate), @winlostdate)

					INSERT INTO #rptStatementTable(
						Winlostdate
						,Custid
						,Openingbalance
					)
					SELECT @winlostdate Winlostdate
						,sta.custid Custid
						,SUM(sta.totalamt) Openingbalance
					FROM dbo.[Statement] sta WITH (NOLOCK)
						INNER JOIN (
						SELECT MAX(sta.accdate) accdate
							,sta.custid
						FROM dbo.[Statement] sta WITH (NOLOCK)
						WHERE sta.accdate <= @winlostdate
							AND sta.accdate >= @CurrentBU_Date
							AND sta.transtype = N'BAL'
						GROUP BY sta.custid
						) stb ON sta.accdate >= stb.accdate
						AND sta.custid = stb.custid
						AND sta.accdate < @winlostdate
					GROUP BY sta.Custid
				END
				ELSE
				BEGIN
					SElECT @CurrentBU_Date = @winlostdate
					
					INSERT INTO #rptStatementTable(
						Winlostdate
						,Custid
						,Openingbalance
					)
					SELECT @winlostdate Winlostdate
						,sta.custid Custid
						,sta.totalamt Openingbalance
					FROM dbo.[Statement] sta WITH (NOLOCK)
					WHERE sta.accdate = @winlostdate
						AND sta.transtype = N'BAL'
				END				
			END
		END
	
		--Transfer Archive 
		IF @Step = 4 OR @Step = 0
		BEGIN
			--Get Transfer data Member & SMA
			INSERT INTO #rptStatementTable(
				Winlostdate
				,Custid
				,[TransferAmt]
				,[BetCount]
			)
			SELECT  @winlostdate Winlostdate
				,tf.Custid 
				,SUM(Credit - Debit) [TransferAmt]
				,COUNT(1) [BetCount]
			FROM bodb_archive.dbo.Transfer_BK tf WITH(NOLOCK)
			WHERE tf.winlostdate = @winlostdate
			GROUP BY tf.custid
		END

		IF EXISTS(SELECT  TOP 1 1 FROM [dbo].[rptStatement_Old] WITH(NOLOCK) WHERE [WinlostDate] = @winlostdate )
		BEGIN
			DELETE [dbo].[rptStatement_Old]
			WHERE [WinlostDate] = @winlostdate
		END

		INSERT INTO [dbo].[rptStatement_Old]
		  ([WinlostDate]
		  ,[Custid]
		  ,[OpeningBalance]
		  ,[VoidAmt]
		  ,[Turnover]
		  ,[NetTurnover]
		  ,[TransferAmt]
		  ,[Winlost]
		  ,[Comm]
		  ,[ClosingBalance]
		)

		SELECT 
			tmp.Winlostdate
			,tmp.Custid
			,SUM(ISNULL(tmp.Openingbalance, 0)) [OpeningBalance]
			,SUM(tmp.Voidamt) [VoidAmt]
			,SUM(tmp.Turnover) [Turnover]
			,SUM(tmp.Netturnover) [NetTurnover]
			,SUM(tmp.Transferamt) [TransferAmt]
			,SUM(tmp.Winlost) [Winlost]
			,SUM(tmp.Comm) [Comm]
			,SUM(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) ClosingBalance
		FROM 
			#rptStatementTable tmp
 		GROUP BY 
			tmp.Winlostdate
			,tmp.Custid
		HAVING  DATEPART(DW,tmp.Winlostdate)=7 
			OR (
				SUM(ISNULL(tmp.Voidamt,0)
				+ISNULL(tmp.BetCount,0)
				+ISNULL(tmp.Transferamt,0)) <>0)
		
		TRUNCATE TABLE #rptStatementTable

		SELECT @winlostdate = DATEADD(DD,1,@winlostdate)
		SELECT @date_7 =DATEADD(DD, - 7, @winlostdate)
			,@date_yesterday=DATEADD(DD, - 1, @winlostdate)
	END

	IF OBJECT_ID('tempdb..#rptStatementTable') IS NOT NULL
	BEGIN
		DROP TABLE #rptStatementTable
	END

END