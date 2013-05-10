ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_NumberGame]
	@winlostdate datetime
AS

/*	Creator: Johnson
	Date: 2010-12-04
	Task: Number Game WinLost Summary report
	DB: DBACC/bodb02
	
	Revisions:
		04Dec2010@Viet: separate LIVE and NON-LIVE data.
		16Dec2010@Viet: Correct Turnover's value, will revert back when old data's gone
		- 20110801@Johnson: add more bettype for number game
		- 20110824@Johnson: remove check winlostdate with '16 Dec 2010' for sumary turnover, get from stake instead actual_stake
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
	
*/
SET NOCOUNT ON

SELECT		
		b.liveindicator,
		b.bettype bettype,
		sum((winlost-actual_stake)*virtualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
		sum(scomm*virtualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) RealLineTotal,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) VirtualLineTotal,		
		sum((1-tpositiontaking)*stake*virtualrate) Turnover
FROM	bettrans b WITH (NOLOCK)
WHERE	b.winlostdate = @winlostdate
		AND b.bettype BETWEEN 81 AND 120	
		AND b.ruben = 1		
		--AND b.status != 'DONE'			
		AND b.statusID not in (101,102,103,121)
GROUP BY b.liveindicator,b.Bettype
ORDER BY b.liveindicator,b.Bettype

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_NumberGame] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_NumberGame] TO [vnteam]