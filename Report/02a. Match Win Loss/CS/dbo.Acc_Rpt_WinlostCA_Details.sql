ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostCA_Details]
	@winlostdate	datetime
AS 
	/*	Creator: Phuong Dao
		Date: 2009-05-06
		Task: Report 2A for Casino 
		DB:  DB06.bodb02
		Original: 
	
		History:
			- 20090522@PhuongDao: Add TurnOver 
			- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
			- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino

		Explanation's Param:

	*/
	SET NOCOUNT ON

	SELECT	bettype,
			currency,
			currencyName,
			isnull(sum(actual_stake * bettrans.actualrate),0) Turnover,
			isnull(sum((winlost-actual_stake)*bettrans.actualrate),0)  winlost, 
			isnull(sum((awinlost+mwinlost+swinlost)*bettrans.actualrate),0) pos,
			isnull(sum( scomm*bettrans.actualrate),0) comm,
			isnull(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*bettrans.actualrate),0) as LineTotal			
	FROM	bettrans with (NOLOCK) 
	WHERE	winlostdate = @winlostdate 
			AND ruben = 1 
			AND bettrans.bettype = 71								--20120405@Hurri
			AND bettrans.matchid = 0 
			--AND status NOT in ('VOID','REJECT','done')
			AND statusID NOT IN (101,102,121)
	GROUP BY bettype, currency, currencyName 
	ORDER BY bettype, currency

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostCA_Details] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_WinlostCA_Details] TO [VNTeam]