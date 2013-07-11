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
			,case when bettype in (1,3,7,8) then bettype else 19999 end as bettype
			,liveindicator
			,ibc
			,'' status		
			,ISNULL(SUM(realWinlost),0) as realWinlost
			,ISNULL(SUM(realPosition),0) as realPosition
			,ISNULL(SUM(realcommission),0) as realCommission
			,ISNULL(SUM(realLineTotal),0) as realLineTotal
			,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
			,ISNULL(SUM(realTurnover),0) as realTurnover
			,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND (sporttype BETWEEN 1 and 99 OR sporttype = 161)
		GROUP BY sporttype,liveindicator ,ibc
			,case when bettype in (1,3,7,8) then bettype else 19999 end		
	UNION ALL
		--Casino
		SELECT 251 as sporttype
			,bettype
			,0 as liveindicator
			,0 as ibc
			,'' status
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal --copy data from actual value
			,0 as realTurnover
			,NULL as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype = 71
		GROUP BY bettype
	UNION ALL
		--Bingo
		SELECT 252 as sporttype
			,bettype
			,0 as liveindicator
			,0 as ibc
			,'' status
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
			,0 as realTurnover
			,NULL as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype = 73
		GROUP BY bettype
	UNION ALL
		--Live casino
		SELECT 162 as sporttype
			,bettype
			,0 as liveindicator
			,0 as ibc
			,'' status
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0) 
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(realTurnover),0) as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype between 1101 and 1199
		GROUP BY bettype
	UNION ALL
		SELECT 97 -- mix parlay
			,9 as bettype
			,0 as liveindicator
			,0 as ibc
			,status
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0) 
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(virtualLineTotal),0)
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(virtualTurnover),0)
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype = 9
		GROUP BY status
	UNION ALL
		SELECT 98 --system parlay
			,29 as bettype
			,0 as liveindicator
			,0 as ibc
			,status
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0) 
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(virtualLineTotal),0)
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(virtualTurnover),0)
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype = 29
		GROUP BY status
	UNION ALL
		--racing
		SELECT sporttype
			,0 as bettype
			,0 as liveindicator
			,0 as ibc
			,'' as status
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0) 
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
			, 0 as realTurnover
			,0 as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype BETWEEN 31 AND 33
		GROUP BY sporttype
	UNION ALL
		--virtual sports
		SELECT sporttype
			,0 as bettype
			,0 as liveindicator
			,0 as ibc
			,'' as status
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0) 
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(realTurnover),0) as virtualTurnover
		FROM rptWinlost2 WITH(NOLOCK)
		WHERE winlostdate BETWEEN @fromdate AND @todate
			AND bettype BETWEEN 1201 AND 1299
		GROUP BY sporttype
	ORDER BY 1,3 DESC,2,4
	
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Sporttype] TO [bodbAdminNet]