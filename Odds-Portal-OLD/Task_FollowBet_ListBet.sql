USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_FollowBet_ListBet]
AS
/*
	Create:  
	Task:  
	DB: DBTRANS.BODB02

	Revision:
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustSetting, custInfo, Cust_FollowBet by link database)
		- 20140227@Kathy: Adjust odds = (follower odds + member odds) in Task_FollowBet_Details table  [Redmine:#12546]
		- 20140807@Logan:   1. Insert live&non-live setting instead of both
		                    2. Allow following all members under an agent
		- 20140831@Lukas: comment code which remove tickets with follow_stake less than 3
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @start          DATETIME
	      , @df             INT
          , @LastTransID    BIGINT
	      , @LastCustUpdate DATETIME
	      , @maxTransID     BIGINT
	      , @CNT            INT
          , @bettype        SMALLINT
	      , @sporttype      TINYINT

    SET @start = CURRENT_TIMESTAMP

    SELECT @LastTransID = transid        
	     , @LastCustUpdate = LastCustUpdate 
      FROM dbo.Task_FollowBet_LastTransID WITH(NOLOCK)

    IF @@ROWCOUNT = 0
    BEGIN
	    SELECT @LastTransID = MAX(transid)
	      FROM dbo.bettrans WITH(NOLOCK)

	    SET @LastCustUpdate = CURRENT_TIMESTAMP

	    INSERT INTO dbo.Task_FollowBet_LastTransID
	    (
	        transid
	      , LastCustUpdate
	    )
	    VALUES
	    (
	        @LastTransID
	      , @LastCustUpdate
        )
    END

    SELECT @maxTransID = MAX(transid)
      FROM dbo.bettrans WITH(NOLOCK)
      
    -- this one to check, in case FollowBet job been disable/stop for long time, just start it as new

    IF @LastTransID < (@maxTransID - 20000)
    BEGIN
	    SET @LastTransID = @maxTransID - 10
	END

    -- re-sync BA custid list
    IF @LastCustUpdate < DATEADD(MINUTE, - 5, @start) -- data is 5 minutes old
    BEGIN
	    TRUNCATE TABLE dbo.Task_FollowBet_BA_From_DB054

	    INSERT INTO dbo.Task_FollowBet_BA_From_DB054
	    SELECT custid
	      FROM DB054.bodb_Licensee.dbo.LicenseeBAHistory WITH(NOLOCK)
	     WHERE status = 'Running'

	    SET @LastCustUpdate = CURRENT_TIMESTAMP

	    -- Update List to follow, default new entry is 0.3	
	    -- src = 0 : manual add
	    -- src = 1 : add by this auto add
	    DECLARE @list TABLE
	    (
	        custid        INT
	      , rate          SMALLMONEY
	      , src           TINYINT
	      , FollowLive    TINYINT
	      , Follow1       BIT
	      , Follow3       BIT
	      , Follow7       BIT
	      , Follow8       BIT
	      , Follower      INT
	      , Odds_Follower SMALLMONEY
	      , PRIMARY KEY (custid, FollowLive)
	    )

        --Non-live
	    INSERT INTO @list
	    SELECT ci.custid
		     , 0.3
		     , 1
		     , 0
		     , 1
		     , 1
		     , 1
		     , 1
		     , 6153451 -- BARM001
		     , 0 -- default Odds 
	      FROM CustDB.dbo.custInfo ci WITH(NOLOCK)
    INNER JOIN dbo.Task_FollowBet_BA_From_DB054 t WITH(NOLOCK) ON ci.custid = t.custid
	     WHERE ci.username LIKE 'ALogUS$%'

	    --Live
	    INSERT INTO @list
	    SELECT ci.custid
		     , 0.3
		     , 1
		     , 1
		     , 1
		     , 1
		     , 1
		     , 1
		     , 6153451 -- BARM001
		     , 0 -- default Odds 
	      FROM CustDB.dbo.custInfo ci WITH(NOLOCK)
    INNER JOIN dbo.Task_FollowBet_BA_From_DB054 t WITH(NOLOCK) ON ci.custid = t.custid
	     WHERE ci.username LIKE 'ALogUS$%'

	    UPDATE l
	       SET rate = cf.rate
	 	     , FollowLive = cf.FollowLive
		     , Follow1 = cf.Follow1
		     , Follow3 = cf.Follow3
		     , Follow7 = cf.Follow7
		     , Follow8 = cf.Follow8
		     , Odds_Follower = cf.Odds
	      FROM @list l
    INNER JOIN CustDB.dbo.Cust_FollowBet cf WITH(NOLOCK) ON l.custid = cf.custid

	    DELETE
	      FROM CustDB.dbo.Cust_FollowBet
	     WHERE src = 1

	    DELETE
	      FROM CustDB.dbo.Cust_FollowBet
	     WHERE custid IN (SELECT custid
			                FROM @list
			             )

        --BEGIN: 20140504@Viet: disable BARM001 (auto follow bet), requested by Byron)
	    DELETE @list WHERE follower = 6153451
	    --END: 20140504@Viet: disable BARM001 (auto follow bet), requested by Byron)

	    INSERT INTO CustDB.dbo.Cust_FollowBet
	    (
	        custid
	      , rate
   	      , src
	      , FollowLive
	      , Follow1
	      , Follow3
	      , Follow7
	      , Follow8
	      , Follower
	      , Odds
	    )
	    SELECT custid
		     , rate
		     , src
		     , FollowLive
		     , Follow1
		     , Follow3
		     , Follow7
		     , Follow8
		     , follower
		     , Odds_Follower
	      FROM @list
    END

    --Member
    INSERT INTO dbo.Task_FollowBet_Details
    (
        transid
      , custid
      , matchid
      , leagueid
      , homeid
      , oddsid
      , bettype
      , betteam
      , liveindicator
      , odds
      , sporttype
      , rate
      , actualrate
      , stake
      , follow_stake
    )
    SELECT b.transid
	     , c.custid
	     , b.matchid
	     , m.leagueid
	     , m.homeid
	     , b.oddsid
	     , b.bettype
	     , b.betteam
	     , b.liveindicator
	     , c.odds + b.odds
	     , m.sporttype
	     , c.Rate
	     , b.actualrate
	     , b.stake
	     , ROUND(c.Rate * b.actualrate * b.stake, 2)
      FROM dbo.bettrans b WITH(NOLOCK)
INNER JOIN dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
INNER JOIN CustDB.dbo.Cust_FollowBet c WITH(NOLOCK) ON b.custid = c.custid
                                                   AND b.liveindicator = c.FollowLive
                                                   AND c.IsAgent = 0
     WHERE b.transid > @LastTransID 
       AND b.transid <= @maxTransID
       AND m.sporttype = 1
       AND b.bettype IN (1, 3, 7, 8)

    
    --Agent
    INSERT INTO dbo.Task_FollowBet_Details
    (
        transid
      , custid
      , matchid
      , leagueid
      , homeid
      , oddsid
      , bettype
      , betteam
      , liveindicator
      , odds
      , sporttype
      , rate
      , actualrate
      , stake
      , follow_stake
    )
    SELECT b.transid
	     , c.custid
	     , b.matchid
	     , m.leagueid
	     , m.homeid
	     , b.oddsid
	     , b.bettype
	     , b.betteam
	     , b.liveindicator
	     , c.odds + b.odds
	     , m.sporttype
	     , c.Rate
	     , b.actualrate
	     , b.stake
	     , ROUND(c.Rate * b.actualrate * b.stake, 2)
      FROM dbo.bettrans b WITH(NOLOCK)
INNER JOIN dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
INNER JOIN CustDB.dbo.custInfo ci WITH(NOLOCK) ON b.custid = ci.custid
INNER JOIN CustDB.dbo.Cust_FollowBet c WITH(NOLOCK) ON ci.recommend = c.custid
                                                   AND b.liveindicator = c.FollowLive
                                                   AND c.IsAgent = 1
     WHERE b.transid > @LastTransID 
       AND b.transid <= @maxTransID
       AND m.sporttype = 1
       AND b.bettype IN (1, 3, 7, 8)
       AND NOT EXISTS (SELECT 1
                         FROM CustDB.dbo.Cust_FollowBet cf
                        WHERE ci.custid = cf.custid
                      )

    UPDATE dbo.Task_FollowBet_LastTransID
       SET transid = @maxTransID
	     , LastCustUpdate = @LastCustUpdate

    --DELETE B
    --  FROM dbo.Task_FollowBet_Details B
    -- WHERE follow_stake < 3

    DELETE B
      FROM dbo.Task_FollowBet_Details B
INNER JOIN CustDB.dbo.Cust_FollowBet c ON B.custid = c.custid
                                      AND (c.FollowBin & POWER(2, B.bettype - 1)) = 0
     WHERE c.FollowLive = B.liveindicator

    DELETE B
      FROM dbo.Task_FollowBet_Details B
INNER JOIN dbo.team t WITH(NOLOCK) ON B.homeid = t.teamid
INNER JOIN dbo.league l WITH(NOLOCK) ON B.leagueid = l.leagueid
     WHERE t.teamname LIKE '% last %' 
        OR t.teamname LIKE '% 1st %'
        
    

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
       SET @bettype = bettype
	     , @sporttype = sporttype
	     , cssporttype = CASE
		                   WHEN @sporttype = 26 THEN 3 -- Football(3) for Rugby(26) (Vivi)
		                   WHEN @sporttype = 32 THEN 2 -- Basketball(2) for Netball(32) (Victor)
		                   WHEN @sporttype NOT IN (1, 2, 3, 5, 8, 10, 11, 151, 161) THEN 99
		                   ELSE @sporttype
		                 END
	     , csbettype = CASE 
		                 WHEN @sporttype IN (3, 8, 26) AND @bettype = 7 THEN 1 --Get Fulltime Handicap for 1st Handicap
		                 WHEN @sporttype IN (3, 8, 26) AND @bettype = 8 THEN 3 --Get Fulltime Over/Under for 1st Over/Under
		                 WHEN @sporttype = 11 AND @bettype = 3 THEN 1 --Motorsport (11) don't have OverUnder (3) setting, get from HDP (1)
		                 ELSE @bettype
		               END

    UPDATE D
       SET apos = CASE liveindicator
		            WHEN 0 THEN apositiontaking
		            ELSE alivepositiontaking
		          END
	     , mpos = CASE liveindicator
		            WHEN 0 THEN mpositiontaking
		            ELSE mlivepositiontaking
		          END
	     , spos = CASE liveindicator
		            WHEN 0 THEN spositiontaking
		            ELSE slivepositiontaking
		          END
	     , pdis = playerdiscount
	     , dis = discount
	     , adis = adiscount
	     , sdis = sdiscount
      FROM dbo.Task_FollowBet_Details D
INNER JOIN CustDB.dbo.custSetting cs WITH(NOLOCK) ON D.custid = cs.custid
                                                 AND D.csbettype = cs.bettype
                                                 AND D.cssporttype = cs.sporttype

    SELECT @df = DATEDIFF(MILLISECOND, @start, CURRENT_TIMESTAMP)

    PRINT '** from ' + CAST(@lastTransID AS VARCHAR(30))
         + ' until ' + CAST(@maxTransID AS VARCHAR(30))
         + ' get ' + CAST(@CNT AS VARCHAR(10))
         + ' tickets (' + CAST(@df AS VARCHAR(10)) + ' ms) **'
END
GO


