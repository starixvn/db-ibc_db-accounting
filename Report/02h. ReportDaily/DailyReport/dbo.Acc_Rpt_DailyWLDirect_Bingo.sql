CREATE PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Bingo]
	@winlostdate	datetime
AS
	/*	Creator: Henry
		Date: 2010-09-30
		Task: Bingo WinLost Summary report
		DB: DB02.bodb02, DB06.bodb02
		
		Revisions:
			   
   
	*/
BEGIN
	SET NOCOUNT ON
	SELECT		
			b.bettype bettype,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
			0 Turnover
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.winlostdate = @winlostdate
			AND b.bettype = 73
			AND b.matchid = 0  
			AND b.statusID NOT IN (102, 101,121,103) 
			AND b.ruben = 1		
	GROUP BY b.Bettype
	ORDER BY b.Bettype	

END 
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Bingo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Bingo] TO [vnteam]