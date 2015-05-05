ALTER PROCEDURE [dbo].[Acc_BetsSelBetCheckM_All]
	@refno  bigint,
	@Language NVARCHAR(2) = 'E'
AS

/*
	Created by: Henry
	Date: 2009-12-05
	Task: Get info of Mix Parlay Bets 
	DB: DBAGE.BODB02
	Original: Acc_BetsSelBetCheckM
	
	Revisions: 
		- 20101007@Henry: Change column transid from INT to BIGINT
		- 20110513@Lukas: re-arrange bettype
		- 20110928@Johnson: get column statusid to mark void sub-ticket
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
		- 20130121@Dan: change linked server DB06 to DBARC		
		- 20141006@Sophia: get Betcheck
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
	matchcode nvarchar(50),
	BetCheck NVarchar(50)
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
		match.isNeutral,
		match.matchid,
		match.matchcode,
		bettrans.BetCheck
	from 
		(SELECT matchid,  Bettype, transid,hdp1, hdp2, odds, betteam, statusid,
				livehomescore,liveawayscore,liveindicator, BetCheck
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
		match.isNeutral,
		match.matchid,
		match.matchcode ,
		bettrans.BetCheck
	from 
		(SELECT matchid, Bettype, transid,hdp1, hdp2, odds, betteam, statusid,
				livehomescore,liveawayscore,liveindicator, BetCheck
		FROM BettransM14 with (nolock)
		WHERE refno=@refno) AS bettrans
	INNER JOIN match14 as match with (nolock) ON bettrans.matchid=match.matchid
END

if exists(select 1 from DBARC.bodb_archive.dbo.BettransM with (nolock) where refno = @refno)
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
		match.isNeutral,
		match.matchid,
		match.matchcode,
		bettrans.BetCheck
	from 
		(SELECT matchid, Bettype, transid,hdp1, hdp2, odds, betteam, statusid,
				livehomescore,liveawayscore,liveindicator, BetCheck
		FROM DBARC.bodb_archive.dbo.BettransM with (nolock)
		WHERE refno=@refno) AS bettrans
	INNER JOIN DBARC.bodb_Archive.dbo.match_bk as match with (nolock) ON bettrans.matchid=match.matchid
END

SELECT * FROM @BetListMP
ORDER BY TransID desc

GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetCheckM_All] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetCheckM_All] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetCheckM_All] TO [vnteam]
