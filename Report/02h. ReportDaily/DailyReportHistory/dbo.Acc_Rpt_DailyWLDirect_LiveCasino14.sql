 CREATE PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino14]
	@winlostdate datetime
AS

/*	Creator: Sophia
	Date: 2012-02-31
	Task: Live Casino WinLost Summary report
	DB: DB06.bodb02
	
	Revisions:
		
	
*/
SET NOCOUNT ON

SELECT	b.bettype bettype,
		sum((winlost-actual_stake)*actualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*stake*actualrate) Turnover
FROM	bettrans14 b WITH (NOLOCK)
WHERE	b.winlostdate = @winlostdate
		AND b.bettype BETWEEN 1101 AND 1199	
		AND b.ruben = 1		
		AND b.statusID not in (101,102,103,121)
GROUP BY b.Bettype
ORDER BY b.Bettype

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino14] TO [vnteam]