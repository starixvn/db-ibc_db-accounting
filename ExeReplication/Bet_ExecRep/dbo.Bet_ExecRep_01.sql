USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Bet_ExecRep_01]    Script Date: 11/26/2012 22:48:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Bet_ExecRep_01]
	@target varchar(10),
	@matchid varchar(500),
	@btList varchar(200),
	@AcceptTime datetime,
	
	@minTransID bigint OUTPUT,
	@maxTransID bigint OUTPUT,
	@ticketCount int = 0 OUTPUT,
	
	@minTransIDm int OUTPUT,
	@maxTransIDm int OUTPUT,
	@ticketCountm int = 0 OUTPUT,

	@AcceptedMatch varchar(2000) = '' OUTPUT,
	@minTransIDs varchar(2000) = '' OUTPUT,
	@maxTransIDs varchar(2000) = '' OUTPUT,
	@ticketCounts varchar(2000) = '' OUTPUT
AS
SET NOCOUNT ON

/*
accept bet using execrep
should call from Dot_Admin_BettransUpd_LiveAccept
	20101103@Joe : new option with @target parameter
	20110530@Joe : add AcceptBet log for DB04/042
	20110817@Joe : 
		1.remove add AcceptBet log for DB04/042
		2.add multiple accept and include live parlay  
*/

IF (@@SERVERNAME = N'DBTRANS') AND (@target = 'DBTRANS')
BEGIN
	Declare @AcceptedTicket TABLE (matchid int, transid bigint)

	SELECT
		@minTransID = 9223372036854775807, @maxTransID = 0, @ticketCount = 0,
		@minTransIDm= 2147483647, @maxTransIDm= 0, @ticketCountm= 0

	UPDATE dbo.bettrans with (rowlock, updlock)
	SET status=N'running', statusID=0, checktime=@AcceptTime
		,@minTransID=CASE WHEN [transid]<@minTransID THEN [transid] ELSE @minTransID END
		,@maxTransID=CASE WHEN [transid]>@maxTransID THEN [transid] ELSE @maxTransID END
		,@ticketCount=@ticketCount+1
	OUTPUT INSERTED.matchid, INSERTED.transid INTO @AcceptedTicket
	FROM dbo.bettrans with (index=CIX_matchid_bettype)
	WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
		AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
		AND statusID = 1	-- waiting
		AND transid > 3200000000

	UPDATE dbo.bettransm with (rowlock, updlock)
	SET status=N'running', statusID=0
		,@minTransIDm = CASE WHEN [transid]<@minTransIDm THEN [transid] ELSE @minTransIDm END
		,@maxTransIDm = CASE WHEN [transid]>@maxTransIDm THEN [transid] ELSE @maxTransIDm END
		,@ticketCountm = @ticketCountm+1
	FROM dbo.bettransm with (index=IX_matchid)
	WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
		AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
		AND statusID = 1	-- waiting

	Declare @Sum TABLE (matchid int PRIMARY KEY, minTransID bigint, maxTransID bigint, ticketCount int)
	INSERT INTO @Sum
	SELECT matchid, min(transid), max(transid), COUNT(*)
	FROM @AcceptedTicket
	GROUP BY matchid

	SET @AcceptedMatch	= (  SELECT CAST(matchid     as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )
	SET @minTransIDs	= (  SELECT CAST(minTransID  as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )
	SET @maxTransIDs	= (  SELECT CAST(maxTransID  as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )
	SET @ticketCounts	= (  SELECT CAST(ticketCount as varchar(20)) + ',' FROM @Sum ORDER BY matchid FOR XML PATH('')  )

	SELECT
		@AcceptedMatch = SUBSTRING(@AcceptedMatch, 1, LEN(@AcceptedMatch)-1),
		@minTransIDs = SUBSTRING(@minTransIDs, 1, LEN(@minTransIDs)-1),
		@maxTransIDs = SUBSTRING(@maxTransIDs, 1, LEN(@maxTransIDs)-1),
		@ticketCounts = SUBSTRING(@ticketCounts, 1, LEN(@ticketCounts)-1)

END
ELSE IF (@@SERVERNAME <> N'DBTRANS') AND (@target = '')
BEGIN

	UPDATE dbo.bettrans with (rowlock, updlock)
	SET status=N'running', statusID=0, checktime=@AcceptTime
		,@ticketCount=@ticketCount+1
	FROM dbo.bettrans with (index=CIX_matchid_bettype)
	WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
		AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
		AND statusID = 1	-- waiting
		AND transid BETWEEN @minTransID AND @maxTransID	


	IF @maxTransIDm > 0
		UPDATE dbo.bettransm with (rowlock, updlock)
		SET status=N'running', statusID=0
			,@ticketCountm = @ticketCountm+1
		FROM dbo.bettransm with (index=IX_matchid)
		WHERE matchid   IN ( SELECT val FROM dbo.strSplit(@matchid, ',') )
			AND bettype IN ( SELECT val FROM dbo.strSplit(@btList,  ',') )
			AND statusID = 1	-- waiting
			AND transid BETWEEN @minTransIDm AND @maxTransIDm	

	-- perform extra log
	/*
	IF @@SERVERNAME IN (N'DB04', N'DB042')
	BEGIN
		Declare @transdate datetime
		SELECT @transdate = transdate FROM dbo.bettrans with (nolock) WHERE transid = @maxTransID

		INSERT INTO dbo.UserLog_AcceptBet (MatchID, minTransID, maxTransID, maxTransDate, btList)
		VALUES ( @matchid, @minTransID, @maxTransID, @transdate, @btList )
	END
	*/
END

