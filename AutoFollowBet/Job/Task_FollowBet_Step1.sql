/*<info serverAlias="DBTXN-bodb02" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_FollowBet_Step1]
AS

/*
	Created:
	DB: DBTXN-bodb02

	Revision:
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustSetting, custInfo, Cust_FollowBet by link database)
		- 20140227@Kathy: Adjust odds = (follower odds + member odds) in Task_FollowBet_Details table  [Redmine:#12546]
		- 20140807@Logan:   1. Insert live&non-live setting instead of both
		                    2. Allow following all members under an agent
		- 20140831@Lukas: comment code which remove tickets with follow_stake less than 3
		- 20140924@Kathy: comment old code which is not used  [Redmine:#22392]
		- 20150311@Kathy: Support multi-follower on one customer [Redmine:#32146]
		- 20150323@Kathy: Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]  
		- 20150617@Daniel: Separate custDB to new server DBCUST [Redmine:#36216]
		- 20170426@Percy: Support Cash Out - get original stake before cash out [RedmineID: #75021]
		- 20170816@Percy: Change data type of Sporttype [RedmineID: #73545]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @start			DATETIME
		,@df				INT
		,@LastTransID		BIGINT
		,@LastCustUpdate	DATETIME
		,@maxTransID		BIGINT
		,@CNT				INT
		,@bettype			SMALLINT
		,@sporttype			SMALLINT

	SET @start = CURRENT_TIMESTAMP

	SELECT @LastTransID		= transid
		,@LastCustUpdate	= LastCustUpdate
	FROM dbo.Task_FollowBet_LastTransID WITH (NOLOCK)

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @LastTransID = MAX(transid)
		FROM dbo.bettrans WITH(NOLOCK)
		
		SET @LastCustUpdate = CURRENT_TIMESTAMP

		INSERT INTO dbo.Task_FollowBet_LastTransID (transid, LastCustUpdate)
		VALUES (@LastTransID, @LastCustUpdate)
	END

	SELECT @maxTransID = MAX(transid)
	FROM dbo.bettrans WITH(NOLOCK)
	
	-- this one to check, in case FollowBet job been disable/stop for long time, just start it as new
	IF @LastTransID < (@maxTransID - 20000)
	BEGIN
		SET @LastTransID = @maxTransID - 10
	END
	
	-- Generate list of custid
	Declare @ListCust TABLE (CustId		INT
							,Follower	INT
							,FollowLive BIT
							,Odds		SMALLMONEY
							,Rate		SMALLMONEY
							,Odds2		SMALLMONEY
							,Rate2		SMALLMONEY
							,Followbin	INT)
	
	-- member
	SELECT cf.custid
		,cf.Follower
		,cf.FollowLive
		,cf.Odds
		,cf.Rate
		,cf.Odds2
		,cf.Rate2
		,cif.recommend as follower_recommend
		,cf.FollowBin
	INTO #tmp_custid
	FROM DBCUST.custDB.dbo.Cust_FollowBet cf WITH(NOLOCK)
	INNER JOIN CustDB.dbo.custInfo cif WITH(NOLOCK) ON cf.Follower = cif.custid
	WHERE IsAgent = 0
	
	--member belong to agent
	INSERT INTO @ListCust (custid, follower, FollowLive, Odds, Rate, Odds2, Rate2, followbin )
	SELECT custid, follower, followLive, odds, rate, Odds2, Rate2, followbin
	FROM #tmp_custid
	UNION ALL
	SELECT ci.custid, c.Follower, c.FollowLive, c.Odds, c.Rate, c.Odds2, c.Rate2, c.FollowBin -- member belong to agent
	FROM DBCUST.CustDB.dbo.Cust_FollowBet c with (nolock) 
	INNER JOIN CustDB.dbo.custInfo ci with (nolock)	ON c.IsAgent = 1 AND c.custid = ci.recommend AND ci.roleid = 1
	INNER JOIN CustDB.dbo.custInfo cif WITH(NOLOCK) ON c.Follower = cif.custid
	WHERE ci.custid NOT IN (SELECT custid FROM #tmp_custid t WHERE t.follower_recommend = cif.recommend)
		AND NOT EXISTS (SELECT TOP 1 1 FROM DBCUST.CustDB.dbo.TradeCust tc WITH(NOLOCK) WHERE tc.custid = ci.custid AND tc.VendorID = 14)
	
	DROP TABLE #tmp_custid
	
	--get Tickets	
	INSERT INTO dbo.Task_FollowBet_Details (
		transid
		,custid
		,matchid
		,leagueid
		,homeid
		,oddsid
		,bettype
		,betteam
		,liveindicator
		,odds
		,sporttype
		,rate
		,actualrate
		,stake
		,follow_stake
		,follower
		)
	SELECT b.transid
		,c.custid
		,b.matchid
		,m.leagueid
		,m.homeid
		,b.oddsid
		,b.bettype
		,b.betteam
		,b.liveindicator
		,CASE WHEN b.bettype IN (5, 15) THEN c.Odds2 ELSE c.Odds END + b.odds
		,m.sporttype
		,CASE WHEN b.bettype IN (5, 15) THEN c.Rate2 ELSE c.Rate END as Rate
		,b.actualrate
		,CASE
			WHEN (b.betdaqid = 0 AND CAST(b.ExtraInfo AS XML).exist('/p25/@s') = 1) THEN ISNULL(CAST(b.ExtraInfo AS XML).value('data(/p25/@s)[1]','MONEY'), 0)
			ELSE b.stake END AS stake
		,ROUND(
			(CASE WHEN b.bettype IN (5, 15) THEN c.Rate2 ELSE c.Rate END)
			* b.actualrate
			* (CASE
				WHEN (b.betdaqid = 0 AND CAST(b.ExtraInfo AS XML).exist('/p25/@s') = 1) THEN ISNULL(CAST(b.ExtraInfo AS XML).value('data(/p25/@s)[1]','MONEY'), 0)
				ELSE b.stake END)
			, 2)
		,c.follower
	FROM dbo.bettrans b WITH(NOLOCK)
		INNER JOIN dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
		INNER JOIN @ListCust c ON b.custid = c.custid AND b.liveindicator = c.FollowLive 
	WHERE b.transid > @LastTransID 
		AND b.transid <= @maxTransID 
		AND m.sporttype = 1 
		AND b.bettype IN (1, 3, 5, 7, 8, 15)		
	OPTION (MAXDOP 4)
	
	UPDATE dbo.Task_FollowBet_LastTransID
	SET transid = @maxTransID
		,LastCustUpdate = @LastCustUpdate

	
	DELETE B
	FROM dbo.Task_FollowBet_Details B
		INNER JOIN @ListCust c ON B.custid = c.custid AND (c.FollowBin & POWER(2, B.bettype - 1)) = 0
	WHERE c.FollowLive = B.liveindicator
	AND b.Follower = c.Follower

	
	DELETE B
	FROM dbo.Task_FollowBet_Details B
		INNER JOIN dbo.team t WITH (NOLOCK) ON B.homeid = t.teamid
		INNER JOIN dbo.league l WITH (NOLOCK) ON B.leagueid = l.leagueid
	WHERE t.teamname LIKE '% last %' 
		OR t.teamname LIKE '% 1st %'

	SELECT @df = DATEDIFF(MILLISECOND, @start, CURRENT_TIMESTAMP)

	PRINT '** from ' + CAST(@lastTransID AS VARCHAR(30)) + ' until ' + CAST(@maxTransID AS VARCHAR(30)) + ' get ' + CAST(@CNT AS VARCHAR(10)) + ' tickets (' + CAST(@df AS VARCHAR(10)) + ' ms) **'
END
GO