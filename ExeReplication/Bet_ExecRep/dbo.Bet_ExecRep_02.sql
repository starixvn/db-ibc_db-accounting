USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Bet_ExecRep_02]    Script Date: 11/26/2012 22:59:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Bet_ExecRep_02]
	@target varchar(10),
	@creator int,
	@matchid varchar(500),
	@btList varchar(200),
	@RejectTime datetime,

	@minTransID bigint OUTPUT,
	@maxTransID bigint OUTPUT,
	@ticketCount int = 0 OUTPUT,

	@minTransIDm int OUTPUT,
	@maxTransIDm int OUTPUT,
	@ticketCountm int = 0 OUTPUT,

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
accept bet using execrep
should call from Dot_Admin_BettransUpd_LiveAccept
	20101103@Joe : new option with @target parameter
	20110530@Joe : add AcceptBet log for DB04/042
	20110817@Joe : add multiple reject and include live parlay(update bettransm)
	20111206@Vivi: update bettransm.winlostdate=bettransm.matchdate
	20120503@Joe/Vivi: BalancePendingCredit
*/
	
Declare @RejectedTicket TABLE (
		custid int, matchid int, transid bigint, oddsid int, 
		betteam varchar(10), stake money, actual_stake money, odds money, 
		tpositiontaking money, virtualrate float)
Declare @Refnos TABLE (refno bigint, custid int)
Declare @pTransID TABLE (transid bigint PRIMARY KEY)

Declare @RejectedTicketParlay TABLE (custid int, actual_stake money)

IF (@@SERVERNAME = N'DBTRANS') AND (@target = 'DBTRANS')
BEGIN

	SELECT
		@minTransID = 9223372036854775807, @maxTransID = 0, @ticketCount = 0,
		@minTransIDm= 2147483647, @maxTransIDm= 0, @ticketCountm= 0


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
		AND statusID = 1	-- waiting
		AND transid > 3200000000
		
	-- BalancePendingCredit
	INSERT INTO dbo.BalancePendingCredit (custid, balance)
	SELECT custid, SUM(actual_stake)
	FROM @RejectedTicket
	GROUP BY custid

	UPDATE dbo.bettransm with (rowlock, updlock)
	SET status = 'Reject', statusID = 101, statuswinlost=5, winlostdate = matchdate
		,@minTransIDm = CASE WHEN [transid]<@minTransIDm THEN [transid] ELSE @minTransIDm END
		,@maxTransIDm = CASE WHEN [transid]>@maxTransIDm THEN [transid] ELSE @maxTransIDm END
		,@ticketCountm=@ticketCountm+1
	OUTPUT
		DELETED.refno, DELETED.custid
	INTO @Refnos
	FROM dbo.bettransm with (index=IX_matchid)
	WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
		AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
		AND statusID = 1	-- waiting

	-- reject parlay main tickets.
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO @pTransID
		SELECT DISTINCT transid
		FROM dbo.bettrans B with (nolock, index=CIX_matchid_bettype)
			INNER JOIN @Refnos R ON B.matchid IN (9,29) AND B.custid = R.custid AND B.refno = R.refno
		WHERE
			statusID = 0 --running

		UPDATE B
		SET status = 'Reject', statusID = 101, checktime=@RejectTime
			,creator = @creator, ruben = 1, winlost = actual_stake
		OUTPUT DELETED.custid, DELETED.actual_stake INTO @RejectedTicketParlay
		FROM dbo.bettrans B with (nolock)
			INNER JOIN @pTransID p ON B.transid = p.transid
			
		-- BalancePendingCredit
		INSERT INTO dbo.BalancePendingCredit (custid, balance)
		SELECT custid, SUM(actual_stake)
		FROM @RejectedTicketParlay
		GROUP BY custid
			
	END		

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

	Declare @matchs TABLE (matchid int primary key)
	INSERT INTO @matchs
	SELECT val FROM dbo.strSplit(@matchid, ',')

	UPDATE dbo.bettrans with (rowlock, updlock)
	SET status = 'Reject', statusID = 101, checktime=@RejectTime
		,creator = @creator, ruben = 1, winlost = actual_stake --statuswinlost=5,   
		,@ticketCount=@ticketCount+1
	FROM dbo.bettrans with (index=PK_bettrans) --CIX_matchid_bettype)
		INNER JOIN @matchs m ON dbo.bettrans.matchid = m.matchid
	WHERE --matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
		--AND 
		bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
		AND statusID = 1	-- waiting
		AND transid BETWEEN @minTransID AND @maxTransID	

	IF @maxTransIDm > 0
	BEGIN
		UPDATE dbo.bettransm with (rowlock, updlock)
		SET status = 'Reject', statusID = 101, statuswinlost=5, winlostdate = matchdate
			,@ticketCountm=@ticketCountm+1
		OUTPUT
			DELETED.refno, DELETED.custid
		INTO @Refnos
		FROM dbo.bettransm with (index=IX_matchid)
		WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
			AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
			AND statusID = 1	-- waiting
			AND transid BETWEEN @minTransIDm AND @maxTransIDm	

		-- reject parlay main tickets.
		INSERT INTO @pTransID
		SELECT DISTINCT transid
		FROM dbo.bettrans B with (nolock, index=CIX_matchid_bettype)
			INNER JOIN @Refnos R ON B.matchid IN (9,29) AND B.refno = R.refno
		WHERE
			statusID = 0 --running

		UPDATE B
		SET status = 'Reject', statusID = 101, checktime=@RejectTime
			,creator = @creator, ruben = 1, winlost = actual_stake
		FROM dbo.bettrans B with (nolock)
			INNER JOIN @pTransID p ON B.transid = p.transid
	END

END

