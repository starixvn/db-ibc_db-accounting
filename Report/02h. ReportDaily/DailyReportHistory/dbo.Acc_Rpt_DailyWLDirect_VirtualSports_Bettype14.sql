ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports_Bettype14]
	@winlostdate datetime,
	@sporttype int
AS
SET NOCOUNT ON

/*	Creator: Elodie
	Date: 2012-09-20
	Task: Winloss Summary HIstory of Virtual sports
	DB: DB06.bodb02
	
	Revisions: 
		- 20121102@Elodie: Use actual rate instead of virtural rate for Virtual sport		
		- 20130225@Elodie: Add Virtual Horse Racing report
*/	
	SELECT		
			b.Bettype,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
			sum((1-tpositiontaking)* stake * actualrate) Turnover
	FROM	bettrans14 b WITH (NOLOCK)
			INNER JOIN match14 m on b.matchid = m.matchid
	WHERE
			winlostdate = @winlostdate
			AND b.bettype BETWEEN 1201 AND 1299 AND b.bettype not in (1231, 1232, 1233, 1237, 1238)
			AND b.matchid > 0 			
			AND b.statusID NOT IN (101, 102, 103) --('VOID', 'REJECT','REFUND') 
			AND b.ruben = 1
			and m.sporttype = @sporttype
	GROUP BY b.Bettype

	-- Virtual HR
	UNION ALL 
	SELECT		
			b.Bettype,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
			sum((1-tpositiontaking)* stake * actualrate) Turnover
	FROM	bettrans14 b WITH (NOLOCK)
			INNER JOIN VSRaceInfo r ON r.EventID = b.matchid
	WHERE
			winlostdate = @winlostdate
			AND b.bettype in (1231, 1232, 1233, 1237, 1238)
			AND b.matchid > 0 			
			AND b.statusID NOT IN (101, 102, 103) --('VOID', 'REJECT','REFUND') 
			AND b.ruben = 1			
			and r.sporttype = @sporttype
	GROUP BY b.Bettype
	
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports_Bettype14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports_Bettype14] TO [vnteam] 