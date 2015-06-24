ALTER PROCEDURE [dbo].[Acc_ResetWinning_Sel]
@MoveBetDate	DATETIME,
@Todate			DATETIME,
@CustID			INT = 44621 --'IBC 0506'
WITH RECOMPILE
AS

/*	Creator: Jamie
	Date: 2010-09-16
	Task: Reset Winning - Get all date 
	DB: DB06.BODB02
	
	Revision:

	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON	

	SELECT	b.Winlostdate,
			b.Balance,
			ISNULL(r.isReset,0) isReset  
	FROM(
			SELECT	@MoveBetDate AS Winlostdate,
					ISNULL(SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) Balance
			FROM	bettrans WITH (NOLOCK)
			WHERE	ruben = 1 
					AND winlostdate <=@MoveBetDate 
					AND statusID NOT IN (101,102)
			
			UNION ALL 	
			SELECT	winlostdate,
					ISNULL(SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) Balance
			FROM	bettrans WITH (NOLOCK)
			WHERE	ruben = 1 AND winlostdate > @MoveBetDate 
					AND  winlostdate<=@Todate 
					AND statusID NOT IN (101,102)
			GROUP BY winlostdate 
		)b 
		LEFT JOIN (
			SELECT	DISTINCT winlostdate,
					1 isReset 
			FROM	Bettrans WITH (NOLOCK)
			WHERE	winlostdate > @MoveBetDate
					AND winlostdate <= @Todate
					AND custid = @custid 
		) r ON b.winlostdate = r.winlostdate  
	
	ORDER BY b.winlostdate 

END
GO
GRANT EXECUTE ON [dbo].[Acc_ResetWinning_Sel] TO [bodbAdminNet]
GO 
GRANT EXECUTE ON [dbo].[Acc_ResetWinning_Sel] TO [VNTeam]
GO