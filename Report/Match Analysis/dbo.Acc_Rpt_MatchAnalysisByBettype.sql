ALTER PROCEDURE dbo.[Acc_Rpt_MatchAnalysisByBettype]
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
	Task: Match Analysis By Bet type
	DB: DBACC/bodb02	
		
	History:
		- 20120405@Dan: add @liveindicator and @bettypes parameter for more filters. Support to get data from bettran_bk
		- 20120920@Sophia: support only Sportsbook
		- 20121123@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20120215@Elodie: Change linked server DB06 to DBARC
		- 20150529@Jim: add Metric Gaming and apply sport-bettype matrix
		- 20150728@Jim: apply Bettrade (Feature #38815)
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
	
	DECLARE @SportBettype TABLE(ProductID INT,Bettype INT,EventType INT,SubProduct VARCHAR(200))
	INSERT INTO @SportBettype
	EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=5
	
	DELETE 	@SportBettype WHERE bettype IN (901,902,903)
	
	IF (@eventdate>@MoveBetsDay)
	BEGIN	
		SELECT 	
				b.bettype,
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
				INNER JOIN @SportBettype s ON b.bettype = s.bettype
		WHERE			
				matchid = @matchid
				--support only sportbook
				AND s.ProductID =1 
				AND s.EventType NOT IN (0,2)				
				AND statusID = CASE WHEN @statusID = 0 THEN statusID		
									ELSE @statusID 	END
				--AND status NOT IN ('VOID', 'REJECT','REFUND') 			
				AND b.statusID IN (111,112,113)
				AND (@liveindicator IS NULL or liveindicator = @liveindicator)
				AND (@bettypes IS NULL OR b.bettype IN (SELECT val FROM @tmp))
				AND ruben = 1
				AND Currency <> 20		
		GROUP BY b.bettype
	END
	ELSE IF (@eventdate>=@BalanceUpDay)
	BEGIN
		SELECT 	
				b.bettype,
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
				INNER JOIN @SportBettype s ON b.bettype = s.bettype
		WHERE			
				matchid = @matchid
				--support only sportbook
				AND s.ProductID =1 
				AND s.EventType NOT IN (0,2)	
				AND statusID = CASE WHEN @statusID = 0 THEN statusID		
									ELSE @statusID 	END
				--AND status NOT IN ('VOID', 'REJECT','REFUND') 
				AND b.statusID IN (111,112,113)
				AND (@liveindicator IS NULL or liveindicator = @liveindicator)
				AND (@bettypes IS NULL OR b.bettype IN (SELECT val FROM @tmp))
				AND ruben = 1
				AND Currency <> 20		
		GROUP BY b.bettype		
	END
	ELSE
	BEGIN
		SELECT 	
				b.bettype,
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
				INNER JOIN @SportBettype s ON b.bettype = s.bettype
		WHERE			
				winlostdate = @eventdate
				AND matchid = @matchid
				--support only sportbook
				AND s.ProductID =1 
				AND s.EventType NOT IN (0,2) 
				--AND statusID = CASE WHEN @statusID = 0 THEN statusID	ELSE @statusID 	END
				AND status = CASE WHEN @statusID = 0 THEN status		
								WHEN @statusID = 111 THEN 'DRAW'
								WHEN @statusID = 112 THEN 'WON'
								WHEN @statusID = 113 THEN 'LOSE'
								END
				AND status IN ('DRAW', 'WON','LOSE') 
				--AND b.statusID IN (111,112,113)
				AND (@liveindicator IS NULL or liveindicator = @liveindicator)
				AND (@bettypes IS NULL OR b.bettype IN (SELECT val FROM @tmp))
				AND ruben = 1
				AND Currency <> 20		
		GROUP BY b.bettype
	END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_MatchAnalysisByBettype] TO [bodbAdminNet]

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_MatchAnalysisByBettype] TO [vnteam]