 CREATE PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino]
	@winlostdate datetime
AS

/*	Creator: Sophia
	Date: 2012-02-31
	Task: Live Casino WinLost Summary report
	DB: DBACC/bodb02
	
	Revisions:
		- 20130731@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)				
		
	
*/
SET NOCOUNT ON

SELECT	b.bettype bettype,
		case when dep.custid is null then 1 else 2 end as site,
		sum((winlost-actual_stake)*actualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*stake*actualrate) Turnover
FROM	bettrans b WITH (NOLOCK)
	LEFT JOIN (select custid from f_DepSuper_1('All')) dep ON b.srecommend = dep.custid
WHERE	b.winlostdate = @winlostdate
		AND b.bettype BETWEEN 1101 AND 1199	
		AND b.ruben = 1		
		AND b.statusID not in (101,102,103,121)
GROUP BY b.Bettype, case when dep.custid is null then 1 else 2 end 
ORDER BY b.Bettype, site

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino] TO [vnteam]