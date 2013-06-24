 ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostSummary_Bettype]
	@sporttype	INT,
	@fromdate	DATETIME,
	@todate		DATETIME
AS
	/*
		Created: Johnson
		Date: 2013-06-24
		Task: Get summary winlost by bet types of sports
		DB: DBRPT/bodb_Report
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	SELECT 
		bettype
		,liveindicator
		,ibc
		,ISNULL(SUM(realWinlost),0) as realWinlost
		,ISNULL(SUM(realPosition),0) as realPosition
		,ISNULL(SUM(realCommission),0) as realCommission
		,ISNULL(SUM(realLineTotal),0) as realLineTotal
		,ISNULL(SUM(virtualLineTotal),0) as virtualLineTotal
		,ISNULL(SUM(realTurnover),0) as realTurnover
		,ISNULL(SUM(virtualTurnover),0) as virtualTurnover
	FROM rptWinlost2 WITH(NOLOCK)
	WHERE winlostdate BETWEEN @fromdate AND @todate
		AND sporttype = @sporttype
	GROUP BY bettype,liveindicator,ibc
	ORDER BY liveindicator,bettype,ibc


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Bettype] TO [bodbAdminNet]
