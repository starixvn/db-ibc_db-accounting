ALTER PROCEDURE [dbo].[NAP_BettransSpecialDelBetID_Sel_ParlayDetail]
	@refno  BIGINT
AS

/*
	Created by: Jamie
	Date: 20140911
	Task: Get info of Mix Parlay Bets 
	DB: DBTXN/BODB02
	Original: Acc_BetsSelBetCheckM
	
	Revisions: 
		- 20141125@Kathy: Add betcheck column [Redmine:#26489]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @BetListMP TABLE (
		TransID BIGINT
		,Bettype INT
		,HomeID INT
		,AwayID INT
		,hdp1 SMALLMONEY
		,hdp2 SMALLMONEY
		,Odds SMALLMONEY
		,Betteam NVARCHAR(20)
		,statusid INT
		,Livehomescore SMALLINT
		,Liveawayscore SMALLINT
		,Liveindicator BIT
		,LeagueID INT
		,Sporttype SMALLINT
		,isNeutral BIT
		,matchid INT
		,matchcode NVARCHAR(50)
		,betcheck	NVARCHAR(50)
		)

	IF EXISTS (
			SELECT 1
			FROM bettransm WITH (NOLOCK)
			WHERE refno = @refno
			)
	BEGIN
		INSERT INTO @BetListMP
		SELECT bettrans.transid
			,bettrans.bettype
			,match.homeid
			,match.awayid
			,bettrans.hdp1
			,bettrans.hdp2
			,bettrans.odds
			,bettrans.betteam
			,bettrans.statusid
			,bettrans.livehomescore
			,bettrans.liveawayscore
			,bettrans.liveindicator
			,match.leagueid
			,match.sporttype
			,match.isNeutral AS IsNeutral
			,match.matchid
			,match.matchcode
			,bettrans.betcheck
		FROM (
			SELECT matchid
				,Bettype
				,transid
				,hdp1
				,hdp2
				,odds
				,betteam
				,statusid
				,livehomescore
				,liveawayscore
				,liveindicator
				,betcheck
			FROM BettransM WITH (NOLOCK)
			WHERE refno = @refno
			) AS bettrans
			INNER JOIN match WITH (NOLOCK) ON bettrans.matchid = match.matchid
	END

	IF EXISTS (
			SELECT 1
			FROM bettransm14 WITH (NOLOCK)
			WHERE refno = @refno
			)
	BEGIN
		INSERT INTO @BetListMP
		SELECT bettrans.transid
			,bettrans.bettype
			,match.homeid
			,match.awayid
			,bettrans.hdp1
			,bettrans.hdp2
			,bettrans.odds
			,bettrans.betteam
			,bettrans.statusid
			,bettrans.livehomescore
			,bettrans.liveawayscore
			,bettrans.liveindicator
			,match.leagueid
			,match.sporttype
			,match.isNeutral AS IsNeutral
			,match.matchid
			,match.matchcode
			,bettrans.betcheck
		FROM (
			SELECT matchid
				,Bettype
				,transid
				,hdp1
				,hdp2
				,odds
				,betteam
				,statusid
				,livehomescore
				,liveawayscore
				,liveindicator
				,betcheck
			FROM BettransM14 WITH (NOLOCK)
			WHERE refno = @refno
			) AS bettrans
			INNER JOIN match14 AS match WITH (NOLOCK) ON bettrans.matchid = match.matchid
	END

	SELECT * FROM @BetListMP
	ORDER BY TransID desc
END
GO
GRANT EXECUTE ON [dbo].[NAP_BettransSpecialDelBetID_Sel_ParlayDetail] TO [bodbAdminNet] AS [dbo]