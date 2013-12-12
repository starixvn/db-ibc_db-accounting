ALTER PROCEDURE [dbo].[Task_FollowBet_ListBet]

AS
/*
	Revision:
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustSetting by link database)
*/
Declare @start datetime, @df int
Declare @LastTransID bigint, @maxTransID bigint, @CNT int
Declare @bettype smallint, @sporttype tinyint



SET @start = CURRENT_TIMESTAMP

SELECT @LastTransID = transid FROM dbo.Task_FollowBet_LastTransID with (nolock)
IF @@ROWCOUNT = 0
BEGIN
	SELECT @LastTransID = max(transid) FROM dbo.bettrans with (nolock)
	
	INSERT INTO dbo.Task_FollowBet_LastTransID (transid) VALUES ( @LastTransID )
END

SELECT @maxTransID = max(transid) FROM dbo.bettrans with (nolock)

INSERT INTO dbo.Task_FollowBet_Details
	(transid, custid, matchid, homeid, oddsid, bettype, betteam,
	liveindicator, odds, sporttype, rate, actualrate, stake, follow_stake)
SELECT
	transid, b.custid, b.matchid, m.homeid, oddsid, bettype, betteam,
	liveindicator, odds, m.sporttype, c.Rate, actualrate, stake, ROUND(c.Rate * actualrate * stake,-1)
FROM
	dbo.bettrans b with (nolock)
	INNER JOIN dbo.match m with (nolock) ON b.matchid = m.matchid
	INNER JOIN CustDB.dbo.cust_FollowBet c with (nolock) ON b.custid = c.custid
WHERE
	transid > @LastTransID AND transid <= @maxTransID
	AND sporttype = 1
	AND bettype IN (1,3,7,8)
	
SET @CNT = @@ROWCOUNT

UPDATE dbo.Task_FollowBet_LastTransID
SET transid = @maxTransID

DELETE B
FROM dbo.Task_FollowBet_Details B
INNER JOIN dbo.team t with (nolock) ON B.homeid = t.teamid
WHERE
	teamname LIKE '%No.of Corners%'
	OR teamname LIKE '%0:0%'
	OR teamname LIKE '% last %'
	OR teamname LIKE '% 1st %'
	
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



GO
GRANT VIEW DEFINITION ON [dbo].[Task_FollowBet_ListBet] TO [vnteam] AS [dbo]