ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports]
	@winlostdate	datetime
AS
SET NOCOUNT ON

/*	Creator: Elodie
	Date: 2012-09-19
	Task: Winloss Summary of Virtual sports
	DB: DB06.bodb02
	
	Revisions: 
		- 20121102@Elodie: Use actual rate instead of virtural rate for Virtual sport		
		- 20130225@Elodie: Add Virtual Horse Racing report
*/
SELECT
		m.sporttype SportType,
		sum((winlost-actual_stake)*actualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*stake*actualrate) Turnover
FROM	bettrans b WITH (NOLOCK)
		INNER JOIN match m on b.matchid = m.matchid
WHERE
		b.winlostdate = @winlostdate
		AND b.bettype BETWEEN 1201 AND 1299 and b.bettype not in (1231, 1232, 1233, 1237, 1238)
		AND b.matchid > 0 		
		AND b.statusID NOT IN (101, 102,103) --('VOID', 'REJECT','REFUND') 
		AND b.ruben = 1		
GROUP BY m.sporttype

-- Virtual HR
UNION ALL
SELECT
		r.SportType SportType,
		sum((winlost-actual_stake)*actualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*stake*actualrate) Turnover
FROM	bettrans b WITH (NOLOCK)		
		INNER JOIN VSRaceInfo r ON b.matchid = r.EventID
WHERE
		b.winlostdate = @winlostdate
		AND b.bettype in (1231, 1232, 1233, 1237, 1238)
		AND b.matchid > 0 		
		AND b.statusID NOT IN (101, 102,103) --('VOID', 'REJECT','REFUND') 
		AND b.ruben = 1	
			
GROUP BY r.sporttype
ORDER BY SportType		

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports] TO [vnteam]

 