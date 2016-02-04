ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostCA_Details14]
	@winlostdate	datetime
AS 
	/*	Creator: Phuong Dao
		Date: 2009-05-06
		Task: Report 2A for Casino 
		DB: DBACC/bodb02 
		Original: 
	
		History:
			- 20090522@PhuongDao: Add TurnOver 
			-- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
			- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
			- 20130703@Kathy: Update matchid for RnG Casino (71) 
			- 20130717@Kathy: Apply Progressive Bonus: add bettype 72 for Casino
			- 20160127@Percy: Expand new range RNG Casino [Redmine: #49134]

		Explanation's Param:

	*/
	SET NOCOUNT ON

	
	SELECT	71 bettype,
			currency,
			currencyName,
			isnull(sum(actual_stake * bettrans.actualrate),0)  Turnover,
			isnull(sum((winlost-actual_stake)*bettrans.actualrate),0)  winlost, 
			isnull(sum((awinlost+mwinlost+swinlost)*bettrans.actualrate),0) pos,
			isnull(sum( scomm*bettrans.actualrate),0) comm,
			isnull(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*bettrans.actualrate),0) as LineTotal			
	FROM	bettrans14 bettrans with (NOLOCK) 
	WHERE	winlostdate = @winlostdate 
			AND ruben = 1 
			AND (bettype in (71, 72) OR bettype BETWEEN 2101 AND 2399)
			AND matchid IN (0, 71, 208, 209, 210)
			AND status NOT in ('VOID','REJECT','done')
			AND statusID NOT IN (101,102,121)
	GROUP BY currency, currencyName 
	ORDER BY currency


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostCA_Details14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_WinlostCA_Details14] TO [VNTeam]
GO