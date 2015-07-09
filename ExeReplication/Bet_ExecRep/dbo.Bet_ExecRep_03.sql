USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Bet_ExecRep_03]    Script Date: 11/26/2012 23:00:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Bet_ExecRep_03]
	@target varchar(10),
	@creator int,
	@matchid varchar(500),
	@btList varchar(200),
	@RejectTime datetime,

	@minTransID bigint OUTPUT,
	@maxTransID bigint OUTPUT,
	@ticketCount int = 0 OUTPUT,

	@RejectedMatch varchar(2000) = '' OUTPUT,
	@minTransIDs varchar(2000) = '' OUTPUT,
	@maxTransIDs varchar(2000) = '' OUTPUT,
	@ticketCounts varchar(2000) = '' OUTPUT,

	@RejectedOdds varchar(2000) = '' OUTPUT,
	@HomeTotals varchar(2000) = '' OUTPUT,
	@AwayTotals varchar(2000) = '' OUTPUT
AS
SET NOCOUNT ON

/*
reject bet using execrep
should call from Dot_Admin_BetTransUpdLiveReject_CP 

	20111019@Joe: reject SecAcceptFlag = 1 (20 seconds auto accept, when admin site click CP will reject Flag is true tickets)
	20120503@Vivi: BalancePendingCredit
*/

Declare @RejectedTicket TABLE (
		custid int, matchid int, transid bigint, oddsid int, 
		betteam varchar(10), stake money, actual_stake money, odds money, 
		tpositiontaking money, virtualrate float)
Declare @Refnos TABLE (refno bigint, custid int)
Declare @pTransID TABLE (transid bigint PRIMARY KEY)

IF (@@SERVERNAME = N'DBTRANS') AND (@target = 'DBTRANS')
BEGIN

	SELECT
		@minTransID = 9223372036854775807, @maxTransID = 0, @ticketCount = 0
		--,@minTransIDm= 2147483647, @maxTransIDm= 0, @ticketCountm= 0


	UPDATE dbo.bettrans with (rowlock, updlock)
	SET status = 'Reject', statusID = 101, checktime=@RejectTime
		,creator = @creator, ruben = 1, winlost = actual_stake --statuswinlost=5,   
		,@minTransID=CASE WHEN [transid]<@minTransID THEN [transid] ELSE @minTransID END
		,@maxTransID=CASE WHEN [transid]>@maxTransID THEN [transid] ELSE @maxTransID END
		,@ticketCount=@ticketCount+1
	OUTPUT
		DELETED.custid, DELETED.matchid, DELETED.transid, DELETED.oddsid,
		DELETED.betteam, DELETED.stake, DELETED.actual_stake, DELETED.odds,
		DELETED.tpositiontaking, DELETED.virtualrate INTO @RejectedTicket
	FROM dbo.bettrans with (index=CIX_matchid_bettype)
	WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
		AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
		AND statusID = 0	-- running
		AND checktime > @RejectTime
		AND SecAcceptFlag = 1
		AND transid > 3200000000
		
	-- BalancePendingCredit
	INSERT INTO dbo.BalancePendingCredit (custid, balance)
	SELECT custid, SUM(actual_stake)
	FROM @RejectedTicket
	GROUP BY custid

	Declare @Sum TABLE (matchid int PRIMARY KEY, minTransID bigint, maxTransID bigint, ticketCount int)
	INSERT INTO @Sum
	SELECT matchid, min(transid), max(transid), COUNT(*)
	FROM @RejectedTicket
	GROUP BY matchid

	SET @RejectedMatch	= (  SELECT CAST(matchid     as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )
	SET @minTransIDs	= (  SELECT CAST(minTransID  as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )
	SET @maxTransIDs	= (  SELECT CAST(maxTransID  as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )
	SET @ticketCounts	= (  SELECT CAST(ticketCount as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )

	SELECT
		@RejectedMatch = SUBSTRING(@RejectedMatch, 1, LEN(@RejectedMatch)-1),
		@minTransIDs   = SUBSTRING(@minTransIDs  , 1, LEN(@minTransIDs)-1),
		@maxTransIDs   = SUBSTRING(@maxTransIDs  , 1, LEN(@maxTransIDs)-1),
		@ticketCounts  = SUBSTRING(@ticketCounts , 1, LEN(@ticketCounts)-1)

	Declare @Total TABLE (oddsid int, homeTotal money, awayTotal money)
	INSERT INTO @Total
	SELECT oddsid,
		SUM(case when betteam='h' then (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * stake * virtualrate * (1-tpositiontaking)) else 0 end),
		SUM(case when betteam='a' then (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * stake * virtualrate * (1-tpositiontaking)) else 0 end)
	FROM @RejectedTicket
	GROUP BY oddsid

	SET @RejectedOdds	= (  SELECT CAST(oddsid     as varchar(20)) + ',' FROM @Total ORDER BY oddsid FOR XML PATH('')  )
	SET @HomeTotals		= (  SELECT CAST(homeTotal  as varchar(20)) + ',' FROM @Total ORDER BY oddsid FOR XML PATH('')  )
	SET @AwayTotals		= (  SELECT CAST(awayTotal  as varchar(20)) + ',' FROM @Total ORDER BY oddsid FOR XML PATH('')  )

	SELECT
		@RejectedOdds = SUBSTRING(@RejectedOdds, 1, LEN(@RejectedOdds)-1),
		@HomeTotals   = SUBSTRING(@HomeTotals  , 1, LEN(@HomeTotals)-1),
		@AwayTotals   = SUBSTRING(@AwayTotals  , 1, LEN(@AwayTotals)-1)

END
ELSE IF (@@SERVERNAME <> N'DBTRANS') AND (@target = '')
BEGIN

	UPDATE dbo.bettrans with (rowlock, updlock)
	SET status = 'Reject', statusID = 101, checktime=@RejectTime
		,creator = @creator, ruben = 1, winlost = actual_stake --statuswinlost=5,   
		,@ticketCount=@ticketCount+1
	FROM dbo.bettrans with (index=CIX_matchid_bettype)
	WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
		AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
		AND statusID = 0	-- running
		AND checktime > @RejectTime
		AND transid BETWEEN @minTransID AND @maxTransID	
		AND SecAcceptFlag = 1
END

