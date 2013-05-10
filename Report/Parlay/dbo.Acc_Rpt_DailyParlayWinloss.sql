ALTER PROCEDURE [dbo].[Acc_Rpt_DailyParlayWinloss]
	@FromDate datetime,
	@ToDate datetime
AS
/*	Creator: Elodie
	Date: 20121016
	Task: Daily parlay winloss report
	DB: DB06.bodb02

	Revisions: 		
		- 20121203@Elodie: Get data between @FromDate AND @ToDate
		- 20121217@Lukas: exclude UUS currency
		- 20130402@Dom.Cao: add turnoverp
	Parameter's Explanation:
		- Combinations: Bettrans.betcheck is stored the number of selection by format 'm4', 'm3' ...
		- LiveType (Livehomescore):
			0: Non Live : All bets are Dead Ball 
			1: Live: All bets are Live Ball 
			2: Mix Live and Non Live: contains Live and Dead Ball

*/
SET NOCOUNT ON 
 
SELECT 
		case when betcheck in ('m2','m3','m4','m5') then betcheck else 'm6' end as Combinations, 
		livehomescore as LiveType, status, 
		sum((winlost-actual_stake)*actualrate) WinLost,
		SUM(stake*actualrate) turnoverp,
		count(1) BetCount,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*(ABS(stake)*actualrate)) Turnover	
FROM	bettrans WITH (NOLOCK)
WHERE
		ruben=1 AND
		bettype = 9 AND
		matchid = 9 AND 
		winlostdate between @FromDate AND @ToDate and 
		statusID NOT IN (101,102,103) AND
		currency <> 20
GROUP BY  case when betcheck in ('m2','m3','m4','m5') then betcheck else 'm6' end, livehomescore, status
ORDER BY  case when betcheck in ('m2','m3','m4','m5') then betcheck else 'm6' end, livehomescore, status


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyParlayWinloss] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyParlayWinloss] TO [vnteam] 