CREATE PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Bingo14]
	@winlostdate	datetime
AS
	/*	Creator: Henry
		Date: 2010-09-30
		Task: Bingo WinLost Summary report
		DB: DB06.bodb02
		
		Revisions:
		- 20130705@Kathy: Update matchid for Bingo (73)	
		- 20130801@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)			
		
	*/
BEGIN
	SET NOCOUNT ON
	SELECT		
			b.bettype bettype,
			case when dep.custid is null then 1 else 2 end as site,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
			0 Turnover
	FROM	bettrans14 b WITH (NOLOCK)
		LEFT JOIN  (select custid from f_DepSuper_1('All')) dep ON b.srecommend = dep.custid 		
	WHERE	b.winlostdate = @winlostdate
			AND b.bettype = 73
			AND b.matchid in (0, 73)  
			AND b.statusID NOT IN (101, 102,103,121) 
			AND b.ruben = 1		
	GROUP BY b.Bettype, case when dep.custid is null then 1 else 2 end
	ORDER BY b.Bettype, site	

END 
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Bingo14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Bingo14] TO [vnteam]