 ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostSummary_Sporttype]
	@fromdate	DATETIME,
	@todate		DATETIME
AS
	/*
		Created: Johnson
		Date: 2013-06-20
		Task: summary winlost by sporttype
		DB: DBRPT/bodb_Report
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
		SELECT sporttype
			,ibc		
			,ISNULL(SUM(realWinlost),0) as realWinlost
			,ISNULL(SUM(realPosition),0) as realPosition
			,ISNULL(SUM(realcommission),0) as realCommission
			,ISNULL(SUM(realLineTotal),0) as realLineTotal
			,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
			,ISNULL(SUM(realTurnover),0) as realTurnover
			,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND (sporttype < 91 OR sporttype = 161)
		GROUP BY sporttype, ibc
	UNION ALL
		--Casino
		SELECT 251 as sporttype
			,ibc
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,0 as virtualLineTotal
			,0 as realTurnover
			,0 as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype = 71
	UNION ALL
		--Bingo
		SELECT 252 as sporttype
			,ibc
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,0 as virtualLineTotal
			,0 as realTurnover
			,0 as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype = 73
	UNION ALL
		--P2P
		SELECT 253 as sporttype
			,ibc
			,ISNULL(SUM(realWinlost),0)
			,0 as realPosition
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,0 as virtualLineTotal
			,0 as realTurnover
			,0 as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype = 1000
	UNION ALL
		--Live casino
		SELECT 162 as sporttype
			,ibc
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0) 
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,0 as virtualLineTotal
			,ISNULL(SUM(realTurnover),0)
			,0 as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype between 1101 and 1199
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Sporttype] TO [bodbAdminNet]