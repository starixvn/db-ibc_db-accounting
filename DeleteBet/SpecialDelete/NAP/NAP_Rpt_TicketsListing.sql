ALTER PROCEDURE [dbo].[NAP_Rpt_TicketsListing]
	@MatchId INT,
	@LicenseeId INT,
	@BetTypes VARCHAR(1000) ,
	@BetTypesLive VARCHAR(1000) ,
	@LiveType SMALLINT = 2,
	@LiveHomeScore smallint = NULL,
    @LiveAwayScore smallint = NULL,
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@Type SMALLINT = 0,
    @SecondAcceptFlag tinyint = 0, 		
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
	
/*	Created by: Elodie
	Date: 20130606
	Task: Show Tickets Listing for NAP system
	DB: DBACC/bodb02
	Original: Acc_Rpt_TicketListing
	
	Revisions:	
		- 20130910@Kathy: Rename parameter @SAFilter to @SecondAcceptFlag
		- 20131129@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
	Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		1: Number Game
		2: Virtual sports
		3: Live casino
	- @LicenseeID:
	  + =0: No Site filter
	  + >0: Filter by specific Licensee's ID
	  + -1: Filter by IBC sites (Non-Licensee sites)
	- @BetTypes: String of bettype for Sportsbook, Virtual sports and for Dead Ball - Number game, Live casino
	- @BetTypesLive: String of bettype ONLY for Live - Number game 
	- @LiveType: Combo Type, used only for Sportsbook
		0: Dead ball
		1: Live ball
		2: All	
	- Because the interface is separated with sportbook and number game
		==>	SportsBook: Use @BetTypes and @LiveType to indicate Live ball or Dead ball
			Number game: Use @BetTypes and @BetTypesLive to indicate Live ball or Dead ball
			Virtual sports: Use @BetTypes to indicate Dead ball
    - @SecondAcceptFlag: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only	  
      
    Example:	declare @p12 int
				set @p12=0
				declare @p13 varchar(1000)
				set @p13=''
				exec NAP_Rpt_TicketsListing @MatchId=4626986,@LicenseeID=0,@BetTypes='1101,1102',@BetTypesLive='',@LiveType=2,@LiveHomeScore=default,@LiveAwayScore=default,@FromTransdate=default,@ToTransdate=default,@Type=3,@SecondAcceptFlag=0,@ErrCode=@p12 output,@ErrMsg=@p13 output
				select @p12, @p13		
*/
WITH RECOMPILE
AS

SET NOCOUNT ON
--- Check MatchID
DECLARE @matchcode nvarchar(100), @homeid int, @awayid int, @eventdate datetime, @IsNeutral bit, @sporttype smallint
SET @sporttype = 0

---- If number game or virtual sports, live casino then don't care @livetype , so set @LiveType to zero
IF @Type = 1 or @Type = 2 or @Type = 3
SELECT @LiveType = 0

----Show match description
SELECT	@matchcode = matchcode, @homeid = homeid, @awayid = awayid, @eventdate = eventdate, @IsNeutral = IsNeutral, @sporttype = sporttype
FROM	match  WITH (NOLOCK)
WHERE	matchid = @MatchId
 
IF ISNULL(@sporttype,0) = 0 OR (@sporttype > 99 and @sporttype <> 154 and @sporttype <> 161 and @sporttype <> 162 and @sporttype not between 180 and 186)
BEGIN 
	SET @ErrCode = 1
	SET @ErrMsg ='Invalid MatchID.'   
	RETURN
END
ELSE
IF @sporttype > 99 and @sporttype <> 154 AND @Type = 0  
BEGIN
	SET @ErrCode = 2  
	SET @ErrMsg ='This MatchID is not sportsbook.'  
	RETURN
END
ELSE
IF @sporttype <> 161 AND @Type = 1 
BEGIN 
	SET @ErrCode =  3  
	SET @ErrMsg ='This MatchID is not number game.' 
	RETURN
END 
ELSE
IF @sporttype not between 180 and 186 AND @Type = 2
BEGIN 
	SET @ErrCode =  4
	SET @ErrMsg ='This MatchID is not virtual sports.' 
	RETURN
END 
ELSE
IF @sporttype <> 162 AND @Type = 3
BEGIN 
	SET @ErrCode =  5
	SET @ErrMsg ='This MatchID is not live casino.' 
	RETURN
END 
ELSE
	SELECT @matchcode as matchcode, @homeid as homeid, @awayid as awayid, convert(VARCHAR(12), @eventdate, 107) as eventdate, @MatchId as matchid, @IsNeutral as IsNeutral

---------
DECLARE @TmpTotal TABLE (OrderNo int, TotalTrans bigint, bettype smallint, LiveIndicator bit, LicenseeName VARCHAR(50) )

CREATE TABLE #TmpBettrans (srecommend int ,bettype smallint, liveindicator bit, statusID tinyint, matchid int, cnt int)
INSERT INTO #TmpBettrans
SELECT srecommend, bettype, liveindicator , statusID, matchid, count(transid) as cnt
FROM bettrans WITH (NOLOCK)
WHERE matchid = @MatchId
  AND statusID NOT IN (101,102,121)--('Void', 'Reject', 'Dummy')
  AND
   (   
    (
     bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@BetTypes,','))
     AND CASE WHEN @LiveType <> 2 THEN liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
     AND livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveType = 1 THEN @LiveHomeScore ELSE livehomescore END
	 AND liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveType = 1 THEN @LiveAwayScore ELSE liveawayscore END
	 AND transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE transdate END 
				   AND	   CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE transdate END 
    )
     OR
    (
     bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@BetTypesLive,','))
     AND liveindicator = 1 
     
    )
   )
   AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
GROUP BY srecommend, matchid, bettype, liveindicator, statusid
 
----## Direct Licensee
	IF  @LicenseeID <> 0 AND @LicenseeID <> -1   
	BEGIN
		DECLARE @LicenseeName VARCHAR(100)
		SET @LicenseeName = ''

		SELECT  @LicenseeName = site
		FROM	site WITH(NOLOCK)
		WHERE	isLicensee = 1 AND isActive =1 AND siteID NOT IN (29,35)
				AND siteID = @LicenseeID
  
		IF @BetTypes <> '9' AND @BetTypes <> '29' AND @BetTypes <> '9,29'
			INSERT INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
			SELECT	1 as OrderNo, sum(cnt) as TotalTrans, bettype, 
					CASE WHEN @type = 1 THEN liveindicator ELSE 0 END,  --- because liveindicator only use for indicate live or dead ball of number game. So the sportsbook don't care.
					@LicenseeName as LicenseeName
			FROM	#TmpBettrans WITH (NOLOCK)
			WHERE	srecommend IN ( SELECT custid FROM dbo.f_DepSuper_1 (@LicenseeName))  
 			GROUP BY bettype, LiveIndicator

		---mix parlay
		IF charindex('9', @BetTypes , 1) <> 0 
			INSERT INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
			SELECT	1 as OrderNo, Count(b.transid) as TotalTrans, b.bettype, 0, @LicenseeName as LicenseeName
			FROM	bettransm bm WITH (NOLOCK)
				INNER JOIN Bettrans b WITH (NOLOCK) ON bm.refno= b.refno
				INNER JOIN dbo.strSplit(@BetTypes,',') t ON b.bettype = t.val
			WHERE	b.srecommend IN ( SELECT custid FROM dbo.f_DepSuper_1 (@LicenseeName))  
					AND bm.matchid = @MatchId
					AND b.statusID NOT IN (101,102) --('Void', 'Reject')
					AND b.bettype IN (9,29)  AND b.matchid IN (9,29)
					AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
					AND bm.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveType = 1 THEN @LiveHomeScore ELSE bm.livehomescore END
					AND bm.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveType = 1 THEN @LiveAwayScore ELSE bm.liveawayscore END	 
					AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
									AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
					AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					AND (b.betid = 0 OR b.betid IS NULL)
			GROUP BY  b.bettype, bm.liveIndicator
			HAVING  Count(b.Refno) >0
	END 

----## IBC Group
	IF  @LicenseeID = -1 	 
	BEGIN 
		IF @BetTypes <> '9' AND @BetTypes <> '29' AND @BetTypes <> '9,29'
			INSERT	INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
			SELECT	0 as OrderNo, sum(cnt) as TotalTrans, bettype, CASE WHEN @type = 1 THEN b.liveindicator ELSE 0 END, 'IBC' as LicenseeName
			FROM	#TmpBettrans b WITH (NOLOCK)
			WHERE	b.srecommend NOT IN ( SELECT custid FROM dbo.f_DepSuper_1 ('all'))  
			GROUP BY b.bettype, b.liveindicator

		---mix parlay
		IF charindex('9', @BetTypes , 1) <> 0
			INSERT INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
			SELECT	0 as OrderNo, Count(DISTINCT b.transid) as TotalTrans, b.bettype, 0, 'IBC' as LicenseeName
			FROM	bettransm bm WITH (NOLOCK)
				INNER JOIN Bettrans b WITH (NOLOCK) ON bm.refno= b.refno
				INNER JOIN dbo.strSplit(@BetTypes,',') t ON b.bettype = t.val
			WHERE	b.srecommend NOT IN ( SELECT custid FROM dbo.f_DepSuper_1 ('all'))  
					AND bm.matchid = @MatchId 
					AND b.statusID NOT IN (101,102) ---('Void', 'Reject')
					AND b.bettype IN (9,29) AND b.matchid IN (9,29)
					AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
					AND bm.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveType = 1 THEN @LiveHomeScore ELSE bm.livehomescore END
					AND bm.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveType = 1 THEN @LiveAwayScore ELSE bm.liveawayscore END
					AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
									 AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
					AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					AND (b.betid = 0 OR b.betid IS NULL)
			GROUP BY  b.bettype, bm.liveIndicator
			HAVING  Count(B.Refno) >0
	END 	
	 
-----## All 
	IF @LicenseeID = 0 
	BEGIN
		IF @BetTypes <> '9' AND @BetTypes <> '29' AND @BetTypes <> '9,29'
			INSERT INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
			SELECT	CASE WHEN s.site IS NULL THEN 0 ELSE 1 END OrderNo,
					sum(cnt) as TotalTrans, bettype, CASE WHEN @type = 1 THEN b.liveindicator ELSE 0 END, 
					CASE WHEN s.site IS NULL THEN 'IBC' ELSE s.site END  as LicenseeName
			FROM	#TmpBettrans b WITH (NOLOCK)
			LEFT JOIN Customer c  WITH (NOLOCK) ON b.srecommend = c.custid
			LEFT JOIN site s WITH (NOLOCK) ON s.site = c.Site AND s.isLicensee = 1 AND s.isActive =1 AND s.siteID NOT IN (29,35)
			WHERE	matchid = @MatchId
			GROUP BY b.bettype, b.liveindicator, s.site

		---mix parlay
		IF charindex('9', @BetTypes , 1) <> 0
			INSERT INTO @TmpTotal (OrderNo, TotalTrans, bettype, LiveIndicator, LicenseeName)
			SELECT	CASE WHEN s.site IS NULL THEN 0 ELSE 1 END OrderNo,
					Count(DISTINCT b.transid) as TotalTrans, b.bettype, 0, 
					CASE WHEN s.site IS NULL THEN 'IBC' ELSE s.site END  as LicenseeName
			FROM	bettransm bm WITH (NOLOCK)
				INNER JOIN Bettrans b WITH (NOLOCK) ON bm.refno = b.refno 
				INNER JOIN dbo.strSplit(@BetTypes,',') t ON b.bettype = t.val
				LEFT JOIN Customer c WITH (NOLOCK) ON b.srecommend = c.custid 
				LEFT JOIN site s WITH (NOLOCK) ON s.site = c.Site AND s.isLicensee = 1 AND s.isActive =1 AND s.siteID NOT IN (29,35)
			WHERE	bm.matchid = @MatchId	
					AND b.bettype IN (9,29) AND b.matchid IN (9,29)
					AND b.statusID NOT IN (101,102)-- ('Void', 'Reject')
					AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
					AND bm.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveType = 1 THEN @LiveHomeScore ELSE bm.livehomescore END
					AND bm.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveType = 1 THEN @LiveAwayScore ELSE bm.liveawayscore END
					AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
									AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
					AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					AND (b.betid = 0 OR b.betid IS NULL)
			GROUP BY s.site, bm.liveindicator, b.bettype
	END 
	 
SELECT SUM (TotalTrans) TotalTrans, OrderNo, bettype as 'bettypeId', LiveIndicator,  LicenseeName 
FROM @TmpTotal
GROUP BY OrderNo, LicenseeName, bettype, LiveIndicator
ORDER BY OrderNo, LicenseeName, bettype, LiveIndicator

DROP TABLE #TmpBettrans




GO
GRANT EXECUTE ON [dbo].[NAP_Rpt_TicketsListing] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Rpt_TicketsListing] TO [vnteam]

 