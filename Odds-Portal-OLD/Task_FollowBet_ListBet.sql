ALTER PROCEDURE [Task_FollowBet_ListBet]
AS
/*
	Revision:
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustSetting, custInfo, Cust_FollowBet by link database)
*/

Declare @start datetime, @df int
Declare @LastTransID bigint, @LastCustUpdate datetime, @maxTransID bigint, @CNT int
Declare @bettype smallint, @sporttype tinyint


SET @start = CURRENT_TIMESTAMP

SELECT @LastTransID = transid, @LastCustUpdate = LastCustUpdate FROM dbo.Task_FollowBet_LastTransID with (nolock)
IF @@ROWCOUNT = 0
BEGIN
	SELECT @LastTransID = max(transid) FROM dbo.bettrans with (nolock)
	SET @LastCustUpdate = CURRENT_TIMESTAMP
	
	INSERT INTO dbo.Task_FollowBet_LastTransID (transid, LastCustUpdate) VALUES ( @LastTransID, @LastCustUpdate )
END

SELECT @maxTransID = max(transid) FROM dbo.bettrans with (nolock)

-- this one to check, in case FollowBet job been disable/stop for long time, just start it as new
IF @LastTransID < (@maxTransID - 20000) SET @LastTransID = @maxTransID - 10


-- re-sync BA custid list
IF @LastCustUpdate < DATEADD(minute, -5, @start) -- data is 5 minutes old
BEGIN
	TRUNCATE TABLE dbo.Task_FollowBet_BA_From_DB054
	
	INSERT INTO dbo.Task_FollowBet_BA_From_DB054
	SELECT custid
	FROM
		DB054.bodb_Licensee.dbo.LicenseeBAHistory with (nolock)
	WHERE
		status = 'Running'
		
	SET @LastCustUpdate = CURRENT_TIMESTAMP


	-- Update List to follow, default new entry is 0.3	
	-- src = 0 : manual add
	-- src = 1 : add by this auto add
	Declare @list TABLE (custid int PRIMARY KEY, rate smallmoney, src tinyint,
		FollowLive tinyint, Follow1 bit, Follow3 bit, Follow7 bit, Follow8 bit, follower int)
	INSERT INTO @list
	SELECT ci.custid, 0.3, 1,
		2, 1,1,1,1,6153451 -- BARM001
	FROM CustDB.dbo.custInfo ci with (nolock)
		INNER JOIN dbo.Task_FollowBet_BA_From_DB054 t with (nolock) ON ci.custid = t.custid
	WHERE
		ci.username LIKE 'ALogUS$%'
	
	UPDATE l
	SET rate = cf.rate,
		FollowLive = cf.FollowLive,
		Follow1 = cf.Follow1,
		Follow3 = cf.Follow3,
		Follow7 = cf.Follow7,
		Follow8 = cf.Follow8
	FROM @list l INNER JOIN CustDB.dbo.Cust_FollowBet cf ON l.custid = cf.custid
	
	DELETE FROM CustDB.dbo.Cust_FollowBet WHERE src = 1
	DELETE FROM CustDB.dbo.Cust_FollowBet WHERE custid IN (SELECT custid FROM @list)
	
	INSERT INTO CustDB.dbo.Cust_FollowBet (custid, rate, src, FollowLive, Follow1, Follow3, Follow7, Follow8, follower)
	SELECT custid, rate, src, FollowLive, Follow1, Follow3, Follow7, Follow8,follower  FROM @list

END


INSERT INTO dbo.Task_FollowBet_Details
	(transid, custid, matchid, leagueid, homeid, oddsid, bettype, betteam,
	liveindicator, odds, sporttype, rate, actualrate, stake, follow_stake)
SELECT
	transid, b.custid, b.matchid, m.leagueid, m.homeid, oddsid, bettype, betteam,
	liveindicator, odds
		/*CASE 
		WHEN odds - 0.05 < -1 THEN odds - 0.05 + 1
		ELSE odds - 0.05 END*/
	, m.sporttype, c.Rate, actualrate, stake, ROUND(c.Rate * actualrate * stake,2) --  -1)
FROM
	dbo.bettrans b with (nolock)
	INNER JOIN dbo.match m with (nolock) ON b.matchid = m.matchid
	INNER JOIN CustDB.dbo.cust_FollowBet c with (nolock) ON b.custid = c.custid
/*
SELECT
	transid, b.custid, b.matchid, m.leagueid, m.homeid, oddsid, bettype, betteam,
	liveindicator, odds
	, m.sporttype, 0.8 Rate, actualrate, stake, ROUND(stake * actualrate * 0.8,2)
FROM
	dbo.bettrans b with (nolock)
	INNER JOIN dbo.match m with (nolock) ON b.matchid = m.matchid
	INNER JOIN dbo.Task_FollowBet_BA_From_DB054 c with (nolock) ON b.custid = c.custid
*/
WHERE
	transid > @LastTransID AND transid <= @maxTransID
	AND sporttype = 1
	AND bettype IN (1,3,7,8)
	AND b.liveindicator = CASE c.FollowLive WHEN 2 THEN B.liveindicator ELSE c.FollowLive END	

SET @CNT = @@ROWCOUNT

UPDATE dbo.Task_FollowBet_LastTransID
SET transid = @maxTransID, LastCustUpdate = @LastCustUpdate

DELETE B
FROM dbo.Task_FollowBet_Details B
WHERE follow_stake < 3


DELETE B
FROM dbo.Task_FollowBet_Details B
INNER JOIN CustDB.dbo.Cust_FollowBet c ON B.custid = c.custid AND (c.FollowBin & POWER(2, B.bettype-1)) = 0

DELETE B
FROM dbo.Task_FollowBet_Details B
INNER JOIN dbo.team t with (nolock) ON B.homeid = t.teamid
INNER JOIN dbo.league l with (nolock) ON B.leagueid = l.leagueid
WHERE
	teamname LIKE '% last %'
	OR teamname LIKE '% 1st %'
	--OR teamname LIKE '%No.of Corners%'
	--OR teamname LIKE '%0:0%'
	--OR leaguename LIKE '%SPECIAL%'


/*
select distinct leaguename from bettrans b (nolock)
inner join Task_FollowBet_BA_From_DB054 c on b.custid = c.custid
inner join match m on b.matchid = m.matchid
inner join league l on m.leagueid = l.leagueid
where m.sporttype = 1 and leaguename like '%special%'
order by 1
*/

UPDATE dbo.Task_FollowBet_Details
SET @bettype = bettype,
	@sporttype = sporttype,
	cssporttype = case
			when @sporttype = 26 then 3		-- Football(3) for Rugby(26) (Vivi)
			when @sporttype = 32 then 2		-- Basketball(2) for Netball(32) (Victor)
			when @sporttype NOT IN (1,2,3,5,8,10,11,151,161) then 99
			else @sporttype end,
	csbettype = case
			when @sporttype in (3,8,26) AND @bettype = 7 then 1	--Get Fulltime Handicap for 1st Handicap
			when @sporttype in (3,8,26) AND @bettype = 8 then 3	--Get Fulltime Over/Under for 1st Over/Under
			when @sporttype = 11 AND @bettype = 3 then 1	--Motorsport (11) don't have OverUnder (3) setting, get from HDP (1)
			else @bettype end

UPDATE D
SET apos = CASE liveindicator WHEN 0 THEN apositiontaking ELSE alivepositiontaking END,
	mpos = CASE liveindicator WHEN 0 THEN mpositiontaking ELSE mlivepositiontaking END,
	spos = CASE liveindicator WHEN 0 THEN spositiontaking ELSE slivepositiontaking END,
	pdis = playerdiscount,
	dis = discount,
	adis = adiscount,
	sdis = sdiscount
FROM dbo.Task_FollowBet_Details D 
	INNER JOIN CustDB.dbo.custsetting cs with (nolock) ON D.custid = cs.custid
	AND D.csbettype = cs.bettype AND D.cssporttype = cs.sporttype
	
SELECT @df = DATEDIFF(millisecond, @start, CURRENT_TIMESTAMP)

PRINT '** from ' + CAST(@lastTransID as varchar(30)) + ' until ' + CAST(@maxTransID as varchar(30)) + ' get ' + CAST(@CNT as varchar(10)) + ' tickets ('
	+ CAST(@df as varchar(10)) + ' ms) **'
