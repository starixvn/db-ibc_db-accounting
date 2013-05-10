
ALTER PROCEDURE [dbo].[Acc_Rpt_WinLossDaily_SAgEx14]
@winlostdate	DATETIME,
@custID			INT
AS
/*
	Created by:Jamie
	Date: 2010-06-05
	Task: Daily WinLoss for Site by Currency 
	DB: DB06.BODB02
	Revisions:
		- 20110516@Lukas: re-arrange bettype
		- 20110823@Elly: - Correct Turnover of sports book since Sep 01, 2011
		- 20120206@Sophia:	Get Stake for Turnover instead of actual_stake. 
							Remove @NegativeBetEffectiveDate

	Param's Explanation:
		@currency: 43 - THB 
		@custID: Super ID 
*/
BEGIN
	SET NOCOUNT ON

	SELECT	b.MRecommend CustID,
			ci.username,
			SUM(CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END) totalTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*(1 - b.tpositiontaking)) ComTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*b.spositiontaking) SAgTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*b.mpositiontaking) MAgTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*b.apositiontaking) AgTO,
			
			-SUM(b.winlost - b.actual_stake + b.awinlost + b.mwinlost + b.swinlost + b.scomm) ComWinlost,
			SUM(b.swinlost + b.scomm - b.acomm) SAgWinlost,
			SUM(b.mwinlost + b.acomm - b.comm) MAgWinlost,
			SUM(b.awinlost + b.comm - b.playercomm) AgWinlost

	FROM	Bettrans14 b WITH (NOLOCK)
			INNER JOIN custinfo ci WITH (NOLOCK) ON b.Mrecommend = ci.custID 
	WHERE	b.winlostdate = @winlostdate
			AND b.srecommend = @CustID 
			AND b.ruben = 1
			AND b.bettype < 19999
			AND b.statusID NOT IN (101,102,103,121)
	GROUP BY b.MRecommend, ci.username 
	ORDER BY ci.username
	
END


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLossDaily_SAgEx14] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLossDaily_SAgEx14] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_WinLossDaily_SAgEx14] TO [vnteam]