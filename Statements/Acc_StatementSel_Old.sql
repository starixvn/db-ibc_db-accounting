SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_StatementSel_Old]
	@fromdate DATE
	,@todate DATE
	,@custid INT
AS

/*
Created by:[Cody]
Date: 20141219
Task: get statement report
DB: DBRPT.bodb_Report
Revisions:
	
 */
BEGIN
		SET NOCOUNT ON

		SELECT
			Winlostdate
			,Custid
			,OpeningBalance
			,VoidAmt
			,NULL AS Oustanding
			,Turnover
			,TransferAmt
			,Winlost
			,Comm
			,ClosingBalance
		FROM
			dbo.rptStatement_Old WITH(NOLOCK)
		WHERE
			winlostdate BETWEEN @fromdate AND @todate
			AND custid = @custid
END
GO
