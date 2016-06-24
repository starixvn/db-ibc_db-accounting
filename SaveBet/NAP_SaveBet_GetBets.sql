USE [bodb_ACC]
GO
/****** Object:  StoredProcedure [dbo].[NAP_SaveBet_GetBets]    Script Date: 06/15/2016 06:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_SaveBet_GetBets    Script Date: 10/6/2015 5:38:24 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SaveBet_GetBets    Script Date: 10/6/2015 1:28:38 PM ******/

/****** Object:  Stored Procedure dbo.NAP_SaveBet_GetBets    Script Date: 9/10/2014 3:22:02 PM ******/
ALTER PROCEDURE [dbo].[NAP_SaveBet_GetBets] 
	@matchid int,
	@bettype smallint,
	@liveindicator bit
AS

/*
	Created by: Dom
	Date:2014-05-06
	Task: Get Bets Report 
	DB: DB06.BODB_ACC
	
	Revisions:
		- 20150728@Jim: apply Bettrade (Feature #38815)
		- 20151001@Jim:support MO (Feature #41935)
		- 20160615@Jim: support to show TEAM statistic figures for Metric Gaming (HotFix #59341)
		
*/

-- original is Dot_Admin_cteamlist
	DECLARE @MetricBettype AS TABLE (bettype INT)
	INSERT INTO @MetricBettype (bettype)
	SELECT   distinct bettype
	 FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
	 WHERE SportType = 1 and SubProduct = 'MG-SuperLive'

IF @bettype IN (901,902,903)
	BEGIN 
		SELECT N'This report does not support bettrade ticket !'
		RETURN
	END 
IF EXISTS (SELECT matchid FROM bodb02.dbo.match WHERE matchid = @matchid)
	SELECT
		0 positiontaking, 
		0 comm,
		0 awinlost,
		b.livehomescore, 
		b.liveawayscore,
		CASE
			WHEN b.status = 'reject' THEN '(reject) ' + cr.username
			WHEN b.status = 'void' THEN '(void) ' + cr.username
			WHEN b.custid <> b.creator THEN cr.username
			ELSE '' END creator, 
		c.username,
		b.odds, 
		b.CurrencyName Currency, 
		b.stake,
		b.hdp1,
		b.hdp2, 
		b.transdate, 
		b.transid, 
		'' typenamee, 
		CASE WHEN ISNULL(t.bettype,0)<> 0 THEN b.transdesc ELSE  b.betteam  END betteam ,
		b.betfrom
		,b.stake * (1- b.tpositiontaking) cpstake
		,CAST(b.actualrate as DECIMAL(9,6)) actualrate
		,CAST(b.virtualrate as DECIMAL(9,6)) virtualrate
		,b.oddsspread
	FROM 
	bodb02.dbo.bettrans b with (nolock)
	INNER JOIN bodb02.dbo.customer c with (nolock) ON b.custid = c.custid
	INNER JOIN bodb02.dbo.customer cr with (nolock) ON b.creator = cr.custid
	LEFT JOIN @MetricBettype t ON b.bettype = t.bettype
	--INNER JOIN bettype bt with(nolock) ON b.bettype = bt.typeid
	WHERE
		b.matchid = @matchid 
		AND b.bettype = @bettype
		AND b.liveindicator = @liveindicator
--AND b.bettype in (1,2,3,4,5,6,7,8,12,15,20)
--AND b.bettype = @bettype 
--AND b.betteam = @betteam
--select * from bettype (nolock)
-- exec Save_BetList 419522
	ORDER BY b.betteam, b.transid
ELSE
	SELECT
		0 positiontaking, 
		0 comm,
		0 awinlost,
		b.livehomescore, 
		b.liveawayscore,
		CASE
			WHEN b.status = 'reject' THEN '(reject) ' + cr.username
			WHEN b.status = 'void' THEN '(void) ' + cr.username
			WHEN b.custid <> b.creator THEN cr.username
			ELSE '' END creator, 
		c.username,
		b.odds, 
		b.currencyname Currency, 
		b.stake,
		b.hdp1,
		b.hdp2, 
		b.transdate, 
		b.transid, 
		'' typenamee, 
		CASE WHEN ISNULL(t.bettype,0)<> 0 THEN b.transdesc ELSE  b.betteam  END betteam ,
		b.betfrom
		,b.stake * (1- b.tpositiontaking) cpstake
		,CAST(b.actualrate as DECIMAL(9,6)) actualrate
		,CAST(b.virtualrate as DECIMAL(9,6)) virtualrate
		,b.oddsspread
	FROM 
	bodb02.dbo.bettrans14 b with (nolock)
	INNER JOIN bodb02.dbo.customer c with (nolock) ON b.custid = c.custid
	INNER JOIN bodb02.dbo.customer cr with (nolock) ON b.creator = cr.custid
	LEFT JOIN @MetricBettype t ON b.bettype = t.bettype
	--INNER JOIN bettype bt with(nolock) ON b.bettype = bt.typeid
	WHERE
		b.matchid = @matchid 
		AND b.bettype = @bettype
		AND b.liveindicator = @liveindicator
--AND b.bettype in (1,2,3,4,5,6,7,8,12,15,20)
--AND b.bettype = @bettype 
--AND b.betteam = @betteam
--select * from bettype (nolock)
-- exec Save_BetList 419522
	ORDER BY b.betteam, b.transid
	GO 
 GRANT EXECUTE ON [dbo].[NAP_SaveBet_GetBets] TO [bodbAdminNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SaveBet_GetBets] TO [vnteam]
GO 
