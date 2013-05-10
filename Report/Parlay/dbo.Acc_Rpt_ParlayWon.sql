ALTER PROCEDURE [dbo].[Acc_Rpt_ParlayWon]
	@WinlostDate	DATETIME,
	@Bettype		INT = 9,
    @IsSoccer		BIT	= 0,    
	@MoveBetsDay	SMALLDATETIME,
	@BalanceUpDay	SMALLDATETIME
AS  

/*
Created: 20120821@Sophia
Task : List of users won Parlay of others sport
	   Note: CompanyWinlost no need to get commission

DB: DB053.bodb02
Original: Acc_Rpt_MixParlayWon

Revisions:
		
Param's Explanation:
	• @WinlostDate:
		- Date of Win lost
	• @IsSoccer
		- 1: Get WON mix parlay tickets of soccer
		- 0: Get WON mix parlay tickets of other sports
	• @Bettype = 9 Mix Parlay
			   = 29 Combination mix parlay
*/

SET NOCOUNT ON

DECLARE @_matchid INT

IF @bettype = 9
	SELECT @_matchid = 9
ELSE IF @bettype = 29 
	SELECT @_matchid = 29

IF @IsSoccer = 1
BEGIN
	IF @WinlostDate > @MoveBetsDay
	BEGIN
		SELECT b.transid, b.username, b.currencyname Currency, b.actualrate AS exchange,
			b.stake, b.actual_stake, b.winlost-b.actual_stake AS Winlost,
			b.stake*b.actualrate AS stake_RM, b.actual_stake*b.actualrate AS actual_stake_RM, (b.winlost-b.actual_stake)*b.actualrate AS Winlost_RM,
			b.stake*(1-b.tpositiontaking)*b.actualrate AS CompanyStake_RM, b.actual_stake*(1-b.tpositiontaking)*b.actualrate AS CompanyActual_stake_RM, (b.winlost-b.actual_stake)*(1-b.tpositiontaking)*b.actualrate AS CompanyWinlost_RM,
			COUNT(1) selection, b.odds, b.modds
		FROM bettrans b WITH (nolock)
			INNER join bettransm bm WITH (nolock) ON b.refno = bm.refno
			INNER JOIN match m WITH(NOLOCK) ON bm.matchid = m.matchid
		WHERE b.bettype = @bettype 
			AND b.matchid = @_matchid
			AND b.statusID = 112 -- WON
			AND b.Currency <> 20
			AND b.winlostdate = @WinlostDate
		GROUP BY
			b.transid, b.username, b.currencyname, b.actualrate,
			b.stake, b.winlost, b.actual_stake, b.odds, b.modds , b.refno, b.tpositiontaking
		HAVING MIN(m.sporttype) = 1
		ORDER BY b.transid
	END
	ELSE
	BEGIN
		SELECT b.transid, b.username, b.currencyname AS Currency, b.actualrate AS exchange,
			b.stake, b.actual_stake, b.winlost-b.actual_stake AS Winlost,
			b.stake*b.actualrate AS stake_RM, b.actual_stake*b.actualrate AS actual_stake_RM, (b.winlost-b.actual_stake)*b.actualrate AS Winlost_RM,
			b.stake*(1-b.tpositiontaking)*b.actualrate AS CompanyStake_RM, b.actual_stake*(1-b.tpositiontaking)*b.actualrate AS CompanyActual_stake_RM, (b.winlost-b.actual_stake)*(1-b.tpositiontaking)*b.actualrate AS CompanyWinlost_RM,
			COUNT(1) selection, b.odds , b.modds
		FROM bettrans14 b WITH (nolock)
			INNER join bettransm14 bm WITH (nolock) ON b.refno = bm.refno
			INNER JOIN match14 m WITH(NOLOCK) ON bm.matchid = m.matchid
		WHERE b.bettype = @bettype 
			AND b.matchid = @_matchid 
			AND b.statusID = 112 -- WON
			AND b.Currency <> 20
			AND b.winlostdate = @WinlostDate
		GROUP BY
			b.transid, b.username, b.currencyname, b.actualrate,
			b.stake, b.winlost, b.actual_stake, b.odds, b.modds , b.refno, b.tpositiontaking
		HAVING MIN(m.sporttype) = 1
		ORDER BY b.transid
	END
END
ELSE
BEGIN
	IF @WinlostDate > @MoveBetsDay
	BEGIN
		SELECT b.transid, b.username, b.currencyname Currency, b.actualrate AS exchange,
			b.stake, b.actual_stake, b.winlost-b.actual_stake AS Winlost,
			b.stake*b.actualrate AS stake_RM, b.actual_stake*b.actualrate AS actual_stake_RM, (b.winlost-b.actual_stake)*b.actualrate AS Winlost_RM,
			b.stake*(1-b.tpositiontaking)*b.actualrate AS CompanyStake_RM, b.actual_stake*(1-b.tpositiontaking)*b.actualrate AS CompanyActual_stake_RM, (b.winlost-b.actual_stake)*(1-b.tpositiontaking)*b.actualrate AS CompanyWinlost_RM,
			COUNT(1) selection, b.odds, b.modds
		FROM bettrans b WITH (nolock)
			INNER join bettransm bm WITH (nolock) ON b.refno = bm.refno
			INNER JOIN match m WITH(NOLOCK) ON bm.matchid = m.matchid
		WHERE b.bettype = @bettype
			AND b.matchid = @_matchid
			AND b.statusID = 112 -- WON
			AND b.Currency <> 20
			AND b.winlostdate = @WinlostDate
		GROUP BY
			b.transid, b.username, b.currencyname, b.actualrate,
			b.stake, b.winlost, b.actual_stake, b.odds , b.modds, b.refno, b.tpositiontaking
		HAVING MIN(m.sporttype) <> 1
		ORDER BY b.transid
	END
	ELSE
	BEGIN
		SELECT b.transid, b.username, b.currencyname Currency, b.actualrate AS exchange,
			b.stake, b.actual_stake, b.winlost-b.actual_stake AS Winlost,
			b.stake*b.actualrate AS stake_RM, b.actual_stake*b.actualrate AS actual_stake_RM, (b.winlost-b.actual_stake)*b.actualrate AS Winlost_RM,
			b.stake*(1-b.tpositiontaking)*b.actualrate AS CompanyStake_RM, b.actual_stake*(1-b.tpositiontaking)*b.actualrate AS CompanyActual_stake_RM, (b.winlost-b.actual_stake)*(1-b.tpositiontaking)*b.actualrate AS CompanyWinlost_RM,
			COUNT(1) selection, b.odds , b.modds
		FROM bettrans14 b WITH (nolock)
			INNER join bettransm14 bm WITH (nolock) ON b.refno = bm.refno
			INNER JOIN match14 m WITH(NOLOCK) ON bm.matchid = m.matchid
		WHERE b.bettype = @bettype 
			AND b.matchid = @_matchid 
			AND b.statusID = 112 -- WON
			AND b.Currency <> 20
			AND b.winlostdate = @WinlostDate
		GROUP BY
			b.transid, b.username, b.currencyname, b.actualrate,
			b.stake, b.winlost, b.actual_stake, b.odds , b.modds, b.refno, b.tpositiontaking
		HAVING MIN(m.sporttype) <> 1
		ORDER BY b.transid
	END
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_ParlayWon] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_ParlayWon] TO [vnteam]