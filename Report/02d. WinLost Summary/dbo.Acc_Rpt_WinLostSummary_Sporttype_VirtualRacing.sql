 ALTER PROCEDURE [dbo].[Acc_Rpt_WinLostSummary_Sporttype_VirtualRacing]
	@fromdate	DATETIME,
	@todate		DATETIME,
	@sporttype	INT 
 AS	
	/*
		Created: Johnson
		Date: 2013-06-26
		Task: Get summary winlost report by match for virtual racing
		DB: DBRPT/bodb_report
		
		Revisions:
		
		Parameter's Explanation	
	*/
SET NOCOUNT ON
	SELECT r.leagueid
		,b.bettype
		,r.eventtime as race
		,ISNULL(SUM(realWinlost),0) as realWinlost
		,ISNULL(SUM(realPosition),0) as realPosition
		,ISNULL(SUM(realCommission),0) as realCommission
		,ISNULL(SUM(realLineTotal),0) as realLineTotal
		,ISNULL(SUM(realTurnover),0) as realTurnover
	FROM rptWinlost2 b WITH(NOLOCK)
		INNER JOIN bodb02.dbo.VSRaceInfo r WITH(NOLOCK) ON b.matchid = r.eventid
	WHERE b.winlostdate between @fromdate and @todate
		AND b.sporttype = @sporttype
	GROUP BY r.leagueid, b.bettype, r.eventtime
	ORDER BY r.leagueid, b.bettype, r.eventtime
	

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLostSummary_Sporttype_VirtualRacing] TO [bodbAdminNet]