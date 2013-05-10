ALTER PROCEDURE [dbo].[Acc_Rpt_MixParlay_Advance]
	@FromDate	datetime,
	@ToDate		datetime,
	@bettype	int
AS
/*	Creator: Sophia
	Date: 20111222
	Task: View Detail of Mix Parlay for 2a, 2h reports.
		  Accounting/ report/ 2a,2h/ Link Mix parlay
	DB: DB06.bodb02

	Revisions: 
		- 20111222@Sophia:
			+ LiveType (Livehomescore):
				0: Non Live : All bets are Dead Ball 
				1: Live: All bets are Live Ball 
				2: Mix Live and Non Live: contains Live and Dead Ball 

			+ SportType (Liveawayscore):
				1: Soccer Sports: soccer only 
				2: Other Sport: Other sport and Multi other sport (not including Soccer)
				3: Multi Sports: include Soccer and Other sports
				
		-20121203@Elodie: Get data between @FromDate AND @ToDate
		- 20121217@Lukas: exclude UUS currency
	Parameter's Explanation:

*/
SET NOCOUNT ON 

DECLARE @_matchid INT

IF @bettype = 9 
	SELECT @_matchid = 9
ELSE IF @bettype = 29 
	SELECT @_matchid = 29

SELECT 
		@bettype bettype, livehomescore as LiveType, liveawayscore as SportType, status, 
		sum((winlost-actual_stake)*actualrate) WinLost,
		SUM(stake*actualrate) turnoverp,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*(ABS(stake)*actualrate)) Turnover	
FROM	bettrans WITH (NOLOCK)
WHERE
		ruben=1 AND
		bettype = @bettype AND
		matchid = @_matchid AND 
		winlostdate between @FromDate AND @ToDate and
		statusID NOT IN (101,102,103) AND
		currency <> 20
GROUP BY  livehomescore, liveawayscore, status
ORDER BY  livehomescore, liveawayscore, status

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_MixParlay_Advance] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_MixParlay_Advance] TO [vnteam]