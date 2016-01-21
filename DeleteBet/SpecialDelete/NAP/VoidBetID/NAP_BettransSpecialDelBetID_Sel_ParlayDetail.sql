USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_BettransSpecialDelBetID_Sel_ParlayDetail]    Script Date: 01/21/2016 15:38:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_BettransSpecialDelBetID_Sel_ParlayDetail    Script Date: 20/01/2016 2:35:05 PM ******/
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
		- 20150712@Kathy: Database - Change datatype [Redmine: #48660]
		- 20150119@Kathy: Changes for phase 1.2 of PH All in One: add transdesc column [Redmine:#50932]	  					  
	
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
		,Odds MONEY
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
		,transdesc	NVARCHAR(200)
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
			,bettrans.transdesc
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
				,transdesc
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
			,bettrans.transdesc
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
				,transdesc
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