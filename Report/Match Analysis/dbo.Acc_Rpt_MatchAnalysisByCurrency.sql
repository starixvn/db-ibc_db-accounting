ALTER PROCEDURE dbo.[Acc_Rpt_MatchAnalysisByCurrency]
	@eventdate datetime,	
	@matchid int,
	@liveindicator smallint = NULL,
	@bettypes VARCHAR(4000) = NULL,
	@statusid tinyint = 0,
	@MoveBetsDay	SMALLDATETIME,
	@BalanceUpDay	SMALLDATETIME			
AS

/*	Creator: Dan
	Date: 20120228
	Task: Match Analysis By Currency
	DB: DBACC/bodb02	
		
	History:
		- 20120405@Dan: add @liveindicator and @bettypes parameter for more filters. Support to get data from bettran_bk
		- 20120920@Sophia: support only Sportsbook
		- 20121123@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20120215@Elodie: Change linked server DB06 to DBARC
	Explanation's Param:
		- @matchid: the id of match
		- @statusid: the status of tickets --> ALL/DRAW/WON/LOSE  (0/111/112/113)
*/
	SET NOCOUNT ON
	
	IF 	(@statusid NOT IN (0,111,112,113))
		RETURN
	
	DECLARE @tmp TABLE (val INT)

	IF (@bettypes IS NOT NULL)
		INSERT INTO @tmp(val) SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,',')
		
	IF (@eventdate>@MoveBetsDay)
	BEGIN	
		SELECT 	
				currency,
				COUNT(transid) betcount,
				--MEMBER
				ISNULL(SUM(ABS(stake)* b.actualrate),0) AS MemberTurnover,
				ISNULL(SUM((winlost-actual_stake + playercomm)* b.actualrate),0) AS MemberWinLost,
				-- COMPANY
				ISNULL(SUM((1-tpositiontaking)*ABS(stake)* b.actualrate),0) AS HouseTurnover,	
				ISNULL(SUM(-(winlost-actual_stake  + swinlost + awinlost + mwinlost + scomm) * b.actualrate),0)  AS HouseWinloss, --Company	
				-- SA + MA + AG
				ISNULL(SUM(tpositiontaking*ABS(stake)* b.actualrate),0) AS SMATurnover,
				ISNULL(SUM((swinlost + scomm + awinlost + mwinlost - playercomm)* b.actualrate),0) AS SMAWinLost
				
		FROM	bettrans b WITH (NOLOCK)				
		WHERE			
				matchid = @matchid
				--support only sportbook
				AND (b.bettype < 31 OR b.Bettype BETWEEN 121 AND 999 or b.bettype BETWEEN 1301 and 1334) 
				AND	b.bettype NOT IN (9,29,10) 
				AND statusID = CASE WHEN @statusID = 0 THEN statusID		
									ELSE @statusID 	END
				--AND status NOT IN ('VOID', 'REJECT','REFUND') 
				AND b.statusID IN (111,112,113)
				AND (@liveindicator IS NULL or liveindicator = @liveindicator)
				AND (@bettypes IS NULL OR bettype IN (SELECT val FROM @tmp))
				AND ruben = 1
				AND Currency <> 20		
		GROUP BY b.currency--, currencyname
		--ORDER BY currencyname
	END
	ELSE IF (@eventdate>=@BalanceUpDay)
	BEGIN
		SELECT 	
				currency,
				COUNT(transid) betcount,
				--MEMBER
				ISNULL(SUM(ABS(stake)* b.actualrate),0) AS MemberTurnover,
				ISNULL(SUM((winlost-actual_stake + playercomm)* b.actualrate),0) AS MemberWinLost,
				-- COMPANY
				ISNULL(SUM((1-tpositiontaking)*ABS(stake)* b.actualrate),0) AS HouseTurnover,	
				ISNULL(SUM(-(winlost-actual_stake  + swinlost + awinlost + mwinlost + scomm) * b.actualrate),0)  AS HouseWinloss, --Company	
				-- SA + MA + AG
				ISNULL(SUM(tpositiontaking*ABS(stake)* b.actualrate),0) AS SMATurnover,
				ISNULL(SUM((swinlost + scomm + awinlost + mwinlost - playercomm)* b.actualrate),0) AS SMAWinLost
				
		FROM	bettrans14 b WITH (NOLOCK)				
		WHERE			
				matchid = @matchid
				--support only sportbook
				AND (b.bettype < 31 OR b.Bettype BETWEEN 121 AND 999 or b.bettype BETWEEN 1301 and 1334) 
				AND	b.bettype NOT IN (9,29,10) 				

				AND statusID = CASE WHEN @statusID = 0 THEN statusID		
									ELSE @statusID 	END
				--AND status NOT IN ('VOID', 'REJECT','REFUND') 
				AND b.statusID IN (111,112,113)
				AND (@liveindicator IS NULL or liveindicator = @liveindicator)
				AND (@bettypes IS NULL OR bettype IN (SELECT val FROM @tmp))
				AND ruben = 1		
				AND Currency <> 20		
		GROUP BY b.currency --, currencyname
		--ORDER BY currencyname
	END
	ELSE 
	BEGIN
		SELECT 	
				currency,
				COUNT(transid) betcount,
				--MEMBER
				ISNULL(SUM(ABS(stake)* b.actualrate),0) AS MemberTurnover,
				ISNULL(SUM((winlost-actual_stake + playercomm)* b.actualrate),0) AS MemberWinLost,
				-- COMPANY
				ISNULL(SUM((1-tpositiontaking)*ABS(stake)* b.actualrate),0) AS HouseTurnover,	
				ISNULL(SUM(-(winlost-actual_stake  + swinlost + awinlost + mwinlost + scomm) * b.actualrate),0)  AS HouseWinloss, --Company	
				-- SA + MA + AG
				ISNULL(SUM(tpositiontaking*ABS(stake)* b.actualrate),0) AS SMATurnover,
				ISNULL(SUM((swinlost + scomm + awinlost + mwinlost - playercomm)* b.actualrate),0) AS SMAWinLost
				
		FROM	DBARC.bodb_archive.dbo.bettrans_bk b WITH (NOLOCK)				
		WHERE
				winlostdate = @eventdate			
				AND matchid = @matchid
				--support only sportbook
				AND (b.bettype < 31 OR b.Bettype BETWEEN 121 AND 999 or b.bettype BETWEEN 1301 and 1334) 
				AND	b.bettype NOT IN (9,29,10) 				
				--AND statusID = CASE WHEN @statusID = 0 THEN statusID	ELSE @statusID 	END
				AND status = CASE WHEN @statusID = 0 THEN status
								WHEN @statusID = 111 THEN 'DRAW'
								WHEN @statusID = 112 THEN 'WON'
								WHEN @statusID = 113 THEN 'LOSE'
								END
				AND status IN ('DRAW', 'WON','LOSE') 
				--AND b.statusID IN (111,112,113)				
				AND (@liveindicator IS NULL or liveindicator = @liveindicator)
				AND (@bettypes IS NULL OR bettype IN (SELECT val FROM @tmp))
				AND ruben = 1		
				AND Currency <> 20		
		GROUP BY b.currency --, currencyname
		--ORDER BY currencyname
	END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_MatchAnalysisByCurrency] TO [bodbAdminNet]

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_MatchAnalysisByCurrency] TO [vnteam]