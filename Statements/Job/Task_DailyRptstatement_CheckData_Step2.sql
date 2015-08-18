USE [bodb_report]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailyRptStatement]    Script Date: 01/15/2015 09:35:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailyRptStatement_Checkdata_Step2]
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
		,Transferamt MONEY NULL
	)
	
	--STEP 02. Check TransferAmt Data rptStatement
	
		INSERT INTO #Statement_tmp(
			winlostdate
			,custid
			,transferamt
		)
		SELECT 
			rpt.winlostdate
			,rpt.custid
			,tmpTr.TransferAmt
		FROM (SELECT 
			@winlostdate winlostdate
			,custid
			,SUM(winlost - actual_stake) AS TransferAmt
		FROM  
			bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE  
			matchid = 0 
			AND bettype > 20000  
			AND bettype NOT IN (23001,23002,23101,23102,23201,23202)
			AND winlostdate = @winlostdate
		GROUP BY   custid) tmpTr 
			  LEFT JOIN [bodb_Report].[dbo].[rptStatement] rpt WITH(NOLOCK) 
			  ON tmpTr.[winlostdate] = rpt.[winlostdate] AND tmpTr.custid = rpt.custid 
		WHERE rpt.[winlostdate] = @winlostdate
				AND ABS(ISNULL(rpt.TransferAmt,0) - ISNULL(tmpTr.TransferAmt,0)) > 0.001
		
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
				,rptSt2.ClosingBalance = ISNULL(rptSt1.closingBalance, 0) + ISNULL(rptSt2.TransferAmt, 0) 
										+ ISNULL(rptSt2. winlost, 0) + ISNULL(rptSt2.comm, 0)
			FROM #Statement_tmp tmp
				INNER JOIN rptStatement rptSt1 WITH(NOLOCK)
				ON tmp.custid = rptSt1.custid
				INNER JOIN rptStatement rptSt2 WITH(NOLOCK)
				ON rptSt1.custid = rptSt2.custid AND rptSt2.winlostdate = DATEADD(DD, 1, rptSt1.winlostdate)
			WHERE rptSt2.winlostdate = @winlostdate_tmp
					
		END
		
END

