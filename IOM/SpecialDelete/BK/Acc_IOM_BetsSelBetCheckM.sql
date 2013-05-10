 ALTER PROCEDURE [dbo].[Acc_IOM_BetsSelBetCheckM]
	@refno  bigint, -- transid
	@Language NVARCHAR(2) = 'E'
AS
/*
	Created by: Elodie
	Date: 20120704
	Task: Get info of Mix Parlay Bets 
	DB: DB053.BODB02
	Original: Acc_BetsSelBetCheckM
	
	Revisions: 
		
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
GRANT EXECUTE ON [dbo].[Acc_IOM_BetsSelBetCheckM] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BetsSelBetCheckM] TO [vnteam]
