ALTER PROCEDURE [dbo].[Acc_IOM_Rpt_TicketsListing]
	@matchID INT,
	@LicenseeID INT, --unused
	@bettypes VARCHAR(1000) ,
	@bettypesLive VARCHAR(1000) ,
	@LiveType SMALLINT = 2,
	@livehomescore smallint = NULL,
    @liveawayscore smallint = NULL,
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@Type SMALLINT = 0,
    @SAFilter tinyint = 0, 		
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT

/*	Created by: @Elodie
	Date: 20120702
	Task: Show Tickets Listing
	DB: DB06.bodb02
	Origional: Acc_Rpt_TicketsListing

	Revisions:	
	
	Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		1: Number Game
	- @bettypes: String of bettype for Sportsbook and for Dead Ball - Number game
	- @bettypesLive: String of bettype ONLY for Live - Number game 
	- @LiveType: Combo Type, used only for Sportsbook
		0: Dead ball
		1: Live ball
		2: All	
	- Because the interface is separated with sportbook and number game
		==>	SportsBook: Use @bettypes and @LiveType to indicate Live ball or Dead ball
			Number game: Use @bettypes and @bettypesLive to indicate Live ball or Dead ball
    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only  		
*/
WITH RECOMPILE
AS
Begin
	SET NOCOUNT ON
	--- Check MatchID
	DECLARE @matchcode nvarchar(100), @homeid int, @awayid int, @eventdate datetime, @IsNeutral bit, @sporttype smallint
	SET @sporttype = 0

	---- If number game then don't care @livetype , so set @LiveType to zero
	IF @Type = 1
	SELECT @LiveType = 0

	----Show match description
	SELECT	@matchcode = matchcode, @homeid = homeid, @awayid = awayid, @eventdate = eventdate, @IsNeutral = IsNeutral, @sporttype = sporttype
	FROM	match  WITH (NOLOCK)
	WHERE	matchid = @MatchID
	 
	IF ISNULL(@sporttype,0) = 0 OR (@sporttype <> 161 AND @sporttype > 99)
	BEGIN 
		SET @ErrCode = 1
		SET @ErrMsg ='Invalid MatchID.'   
		RETURN
	END
	ELSE
		IF @sporttype = 161 AND @Type = 0  
		BEGIN
			SET @ErrCode = 2  
			SET @ErrMsg ='This MatchID is not sportsbook.'  
			RETURN
		END
		ELSE
			IF @sporttype <=99 AND @Type = 1 
			BEGIN 
				SET @ErrCode =  3  
				SET @ErrMsg ='This MatchID is not number game.' 
				RETURN
			END 
			ELSE
				SELECT @matchcode as matchcode, @homeid as homeid, @awayid as awayid, @eventdate as eventdate, @matchid as matchid, @IsNeutral as IsNeutral

------------------------------------------------------------------
	DECLARE @TmpTotal TABLE (OrderNo int, TotalTrans bigint, bettype smallint, LiveIndicator bit, LicenseeName VARCHAR(50))

	CREATE TABLE #TmpBettrans (srecommend int ,bettype smallint, liveindicator bit,  statusID tinyint, matchid int, cnt int)
	INSERT INTO #TmpBettrans
	SELECT srecommend, bettype, liveindicator , statusID, matchid, count(transid) as cnt
	FROM bettrans WITH (NOLOCK)
	WHERE matchid = @matchid
		AND statusID NOT IN (101,102,121)---('Void', 'Reject', 'Dummy')
		AND
		(   
			(
			 bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,','))
			 AND CASE WHEN @LiveType <> 2 THEN liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
			 AND livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE livehomescore END
			 AND liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE liveawayscore END
			 AND transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE transdate END 
						   AND	   CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE transdate END 
			)
			 OR
			(
			 bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypesLive,','))
			 AND liveindicator = 1      
			)
	   )
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
	GROUP BY srecommend, matchid, bettype, liveindicator, statusid

	IF @bettypes <> '9' AND @bettypes <> '29' AND @bettypes <> '9,29'
		INSERT INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
		SELECT	1 as OrderNo, sum(b.cnt) as TotalTrans, b.bettype, 
				CASE WHEN @type = 1 THEN b.liveindicator ELSE 0 END,  --- because liveindicator only use for indicate live or dead ball of number game. So the sportsbook don't care.
				s.site as LicenseeName
		FROM	#TmpBettrans b WITH (NOLOCK)
				LEFT JOIN Customer c WITH (NOLOCK) ON b.srecommend = c.custid 
				LEFT JOIN site s WITH (NOLOCK) ON s.site = c.Site AND s.isLicensee = 1 AND s.isActive =1			
		GROUP BY bettype, LiveIndicator, s.site

	---mix parlay
	IF charindex('9', @bettypes , 1) <> 0 
		INSERT INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
		SELECT	1 as OrderNo, Count(b.transid) as TotalTrans, b.bettype, 0, s.site as LicenseeName
		FROM	bettransm bm WITH (NOLOCK)
			INNER JOIN Bettrans b WITH (NOLOCK) ON bm.refno= b.refno
			INNER JOIN dbo.strSplit(@bettypes,',') t ON b.bettype = t.val
			LEFT JOIN Customer c WITH (NOLOCK) ON b.srecommend = c.custid 
			LEFT JOIN site s WITH (NOLOCK) ON s.site = c.Site AND s.isLicensee = 1 AND s.isActive =1			 			
		WHERE	bm.matchid = @matchid
				AND b.statusID NOT IN (101,102) --('Void', 'Reject')
				AND b.bettype IN (9,29)  AND b.matchid IN (9,29)
				AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
				AND bm.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE bm.livehomescore END
				AND bm.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE bm.liveawayscore END	 
				AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
				AND CASE when @SAFilter = 2 then 0 else 1 END = 1
				AND (b.betid = 0 OR b.betid IS NULL)
		GROUP BY  b.bettype, bm.liveIndicator, s.site
		HAVING  Count(b.Refno) >0

	SELECT SUM (TotalTrans) TotalTrans, OrderNo, bettype, LiveIndicator, LicenseeName
	FROM @TmpTotal
	GROUP BY OrderNo, LicenseeName, bettype, LiveIndicator
	ORDER BY OrderNo, LicenseeName, bettype, LiveIndicator

	DROP TABLE #TmpBettrans
End

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_Rpt_TicketsListing] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_Rpt_TicketsListing] TO [vnteam]

 