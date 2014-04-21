ALTER PROCEDURE [dbo].[Acc_Rpt_RNGCasinoAutomail]
	@amount MONEY = 5000,
	@fromdate DATETIME,
	@todate DATETIME
	
AS
/*
	Created: Dom
	Date: 20140125
	Task : RNG Casino Automail report
	DB: DBACC.bodb02
	Original:

	Revisions:
		
	Param's Explanation:
	
*/
SELECT username,
		recommend,
		currency,
		SUM((winlost-actual_stake)*actualrate) winlost_rm,
		SUM(winlost-actual_stake) winlost
INTO #temp
FROM bettrans(NOLOCK)
WHERE transdate between @FromDate and @ToDate
AND bettype=71 
AND matchid=0
AND statusID in(112,113) 
AND srecommend not in (select custid from Dep_CustSuper(NOLOCK))
GROUP BY username,recommend,currency
HAVING ABS(SUM((winlost-actual_stake)*actualrate)) >= @amount

SELECT t.username member,ca.currency,ca.username agent,winlost,winlost_rm
FROM #temp t
INNER JOIN custInfo(NOLOCK) ca ON ca.custid = t.recommend

DROP TABLE #temp


GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_RNGCasinoAutomail] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_RNGCasinoAutomail] TO [vnteam] AS [dbo]
GO


