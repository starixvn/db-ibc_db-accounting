USE [bodb_report]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailyRptStatement]    Script Date: 01/15/2015 09:35:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Task_DailyRptStatement_Checkdata_Step3]
	@Winlostdate SMALLDATETIME
	,@Movebetday SMALLDATETIME
AS

/*
Created by:[Cody]
Date: 20150115
Task: check and correct data on rptStatement step 3
DB: DBRPT.bodb_Report
Revisions:
	
 */

BEGIN

	SET NOCOUNT ON
	
	IF OBJECT_ID('tempdb..#Statement_tmp') IS NOT NULL
	BEGIN
		DROP TABLE #Statement_tmp
	END

	CREATE TABLE #Statement_tmp(
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
	)
	
	--STEP 03. Check winlost/TO  Data rptStatement and [sum_winloss]
	
		INSERT INTO #Statement_tmp(
			winlostdate
			,custid
			,transferamt
		)
		SELECT 
			rpt.winlostdate
			,rpt.custid
			,tmpTr.TransferAmt
		FROM [bodb_Report].[dbo].[rptStatement] rpt WITH(NOLOCK)
			LEFT JOIN  (SELECT
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
				[bodb02].[dbo].[sum_winloss] tblsum WITH(NOLOCK)
			WHERE
				tblsum.winlostdate = @winlostdate		
			GROUP BY
				tblsum.custid) su  
	ON su.[winlostdate]= rpt.[winlostdate] AND su.custid= rpt.custid 
WHERE rpt.[winlostdate] = @winlostdate
	AND (
		ABS(ISNULL(rpt.[Turnover],0) - ISNULL(su.[Turnover],0))>0.001
		OR ABS(ISNULL(rpt.NetTurnover,0) - ISNULL(su.NetTurnover,0))>0.001
		OR ABS(ISNULL(rpt.Winlost,0) - ISNULL(su.Winlost,0))>0.001
		OR ABS(ISNULL(rpt.comm,0) - ISNULL(su.comm,0))>0.001
		)
		
		IF NOT EXISTS(SELECT TOP 1 1 FROM #Statement_tmp)
		BEGIN
			RETURN
		END
		
		UPDATE rptSt
		SET 
			rptSt.TransferAmt = bt.TransferAmt
			,rptSt.ClosingBalance = ISNULL(rptSt.openingbalance, 0) + ISNULL(bt.TransferAmt, 0) + ISNULL(rptSt.winlost, 0) + ISNULL(rptSt.Comm, 0)
		FROM
			#Statement_tmp bt
			INNER JOIN dbo.rptStatement rptSt WITH(ROWLOCK, UPDLOCK) 
			ON (rptSt.custid = bt.custid AND bt.winlostdate = rptSt.winlostdate)
		WHERE rptSt.winlostdate = @winlostdate
		 
		-- Correct data
		DECLARE @winlostdate_tmp SMALLDATETIME = DATEADD(DD, 1, @winlostdate)
		
		WHILE(@winlostdate_tmp <= @Movebetday)
		BEGIN
			UPDATE rptSt2
			SET
				rptSt2.OpeningBalance = rptSt1.closingBalance
				,rptSt2.ClosingBalance = rptSt1.closingBalance + rptSt2.TransferAmt + rptSt2. winlost + rptSt2.comm
			FROM #Statement_tmp tmp
				INNER JOIN rptStatement rptSt1 WITH(NOLOCK)
				ON tmp.custid = rptSt1.custid
				INNER JOIN rptStatement rptSt2 WITH(NOLOCK)
				ON rptSt1.custid = rptSt2.custid AND rptSt2.winlostdate = DATEADD(DD, 1, rptSt1.winlostdate)
			WHERE rptSt2.winlostdate = @winlostdate_tmp
					
			SELECT @winlostdate_tmp = DATEADD(DD, 1, @winlostdate_tmp)
		END
		
END

