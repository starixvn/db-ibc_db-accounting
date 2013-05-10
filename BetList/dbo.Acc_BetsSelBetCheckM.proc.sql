ALTER PROCEDURE [dbo].[Acc_BetsSelBetCheckM]
	@refno  bigint, -- transid
	@Language NVARCHAR(2) = 'E'
AS

/*
	Created by: [Creator]
	Date: 2008
	Task: Get info of Mix Parlay Bets 
	DB: DB053.BODB02
	Original: Original: SP mteamlist
	
	Revisions: 
		- 20060222@[]: remove refno
		- 20060310@[]: remove odds depend
		- 20090408@PhuongDao: Get checktime as SettleTime 
		- 20090514@Simon: Remove RefNo
		- 20091003@Jamie: Remove comstatus out 
		- 20091125@Henry: Select appropriate info to avoid redundant data
		- 20091128@Daniel: Fix the issue Mix Parlay Tennis - Cross Day - Move Bet problems: get more data in bettransm14 for Refno in Bettrans 
		- 20091204@Henry: Change logic to get data for future Mix Parlay (combine Acc_BetsSelBetCheckM & Acc_BetsSelBetCheckM_History)
		- 20101007@Henry: Change column transid from INT to BIGINT
		- 20110513@Lukas: re-arrange bettype
		- 20110928@Johnson: get column statusid to mark void sub-tickets
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
	
*/

SET NOCOUNT ON

DECLARE @BetListMP TABLE(
	TransID bigint,
	Bettype int,
	HomeID int,
	AwayID int, 
	hdp1 smallmoney, 
	hdp2 smallmoney,
	Odds smallmoney, 
	Betteam nvarchar(20),
	statusid INT,
	Livehomescore smallint,
	Liveawayscore smallint,
	Liveindicator bit,
	LeagueID int,
	Sporttype smallint,
	isNeutral bit,
	matchid int,
	matchcode nvarchar(50)
)


if exists(select 1 from bettransm with (nolock) where refno = @refno)
BEGIN
	INSERT INTO @BetListMP
	SELECT
		bettrans.transid, 
		bettrans.bettype,
		match.homeid,
		match.awayid,
		bettrans.hdp1, 
		bettrans.hdp2, 
		bettrans.odds,
		bettrans.betteam,
		bettrans.statusid,
		bettrans.livehomescore, 
		bettrans.liveawayscore, 
		bettrans.liveindicator, 
		match.leagueid,
		match.sporttype,
		match.isNeutral as IsNeutral,
		match.matchid,
		match.matchcode
	from 
		(SELECT matchid,  Bettype, transid,hdp1, hdp2, odds, betteam, statusid,
				livehomescore,liveawayscore,liveindicator
		FROM BettransM with (nolock)
		WHERE refno=@refno ) AS bettrans
	INNER JOIN match with (nolock) ON bettrans.matchid=match.matchid
END

if exists(select 1 from bettransm14 with (nolock) where refno = @refno)
BEGIN
	INSERT INTO @BetListMP
	SELECT
		bettrans.transid, 
		bettrans.bettype,
		match.homeid,
		match.awayid,
		bettrans.hdp1, 
		bettrans.hdp2, 
		bettrans.odds, 
		bettrans.betteam,
		bettrans.statusid,
		bettrans.livehomescore, 
		bettrans.liveawayscore, 
		bettrans.liveindicator, 
		match.leagueid,
		match.sporttype,
		match.isNeutral as IsNeutral,
		match.matchid,
		match.matchcode
	from 
		(SELECT matchid, Bettype, transid,hdp1, hdp2, odds, betteam, statusid,
				livehomescore,liveawayscore,liveindicator
		FROM BettransM14 with (nolock)
		WHERE refno=@refno) AS bettrans
	INNER JOIN match14 as match with (nolock) ON bettrans.matchid=match.matchid
END


SELECT * FROM @BetListMP
ORDER BY TransID desc
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetCheckM] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetCheckM] TO [vnteam]
