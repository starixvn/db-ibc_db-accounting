USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AutoFollowBetDelCustomer]    Script Date: 04/14/2015 09:58:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_AutoFollowBetDelCustomer    Script Date: 08/04/2015 9:36:37 AM ******/
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetDelCustomer]	
	@Username   VARCHAR(30),
	@Follower	VARCHAR(30),
	
	@UserId		INT,
	@IP			VARCHAR(50),
	@ErrCode    INT				= 0 OUTPUT,
	@ErrMsg     NVARCHAR(200)	= '' OUTPUT
AS
/*
	Created: Viet @ 4-Jul-2012
	DB: DBTXN.custDB

	Revision:
		- 20131212@Kathy: - Remove @status, add new @param
						  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144] 
						  - Write log
        - 20140805@Logan:   1. User can be agent (only member before) [Redmine: #19650]
                            2. Get log for live & non-live settings [Redmine: #16578]
                            2. Code aligning
		- 20141230@Kathy: Update the accounts dangerous setting change to "2" for Original & Non Live [Redmine:#25770]
		- 20150120@Kathy: Update Original and Nonlive danger level of BA member to 100 and 0 respectively [Redmine:#29459]
		- 20150311@Kathy: Support multi-follower on one customer [Redmine:#32146]
		- 20150323@Kathy: - Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]  
						  - Update danger, danger2 for downlines
		- 20170621@Harper: Apply change request to rules of Bet Follow [Redmine: #78586]
		
	Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun           DATETIME
	      , @endRun             DATETIME
	      , @duration           INT
	      
	      , @oldRate            SMALLMONEY
	      , @oldRate2           SMALLMONEY
	      , @oldLiveOdds        SMALLMONEY
	      , @oldNonLiveOdds     SMALLMONEY
	      , @oldLiveOdds2       SMALLMONEY
	      , @oldNonLiveOdds2    SMALLMONEY
	      , @oldLiveHDP         BIT
	      , @oldLiveOU          BIT
	      , @oldLive1x2         BIT
	      , @oldLive1stOU       BIT
	      , @oldLive1stHDP      BIT
	      , @oldLive1st1x2      BIT
	      , @oldNonLiveHDP      BIT
	      , @oldNonLiveOU       BIT
	      , @oldNonLive1x2      BIT
	      , @oldNonLive1stHDP   BIT	      
	      , @oldNonLive1stOU    BIT
	      , @oldNonLive1st1x2   BIT
	      , @oldFollower        VARCHAR(30)
	      ,	@oldDanger			INT
		  ,	@oldDanger2			INT
		  , @custid             INT
		  , @custFollower		INT
		  ,	@isBA				BIT
		  , @isAgent			BIT
		  , @recommend			INT

	SELECT @startRun = GETDATE()
	     , @duration = 0
	     , @isBA = 0

	SELECT @custFollower = custid
	FROM custinfo with(NOLOCK)
	WHERE username = @Follower
	
	SELECT @custid = custid
		, @isAgent = CASE WHEN roleid = 1 THEN 0 ELSE 1 END
		, @recommend = recommend
	  FROM Custinfo WITH(nolock)
	 WHERE username = @username
	   and roleid IN (1, 2)

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username ''' + @Username + ',' + @Follower + ''', please try again!'
		     , @ErrCode = 101

		RETURN
	END

	IF NOT EXISTS (SELECT TOP 1 1
					FROM Cust_followBet WITH(NOLOCK)
					WHERE custid = @custid
					AND follower = @custFollower
			  )
	BEGIN
		SELECT @ErrMsg = 'Username ''' + @Username + ',' + @Follower + ''' does not exist, please try again!'
			 , @ErrCode = 102

		RETURN
	END
	
	--IF EXISTS(SELECT TOP 1 1 FROM DBLIC.bodb_licensee.dbo.LicenseeBAHistory l WITH(NOLOCK)
	--			WHERE l.status = 'running'
	--			AND custid = @custid)
	--	SET @isBA = 1
	IF EXISTS(SELECT TOP 1 1 FROM Dep_CustBAActive WITH(NOLOCK)
				WHERE custid = @custid)
		SET @isBA = 1
	
	-- Get old Live value
	SELECT @oldRate = f.Rate
		 , @oldRate2 = f.Rate2
	     , @oldLiveHDP = f.Follow1
	     , @oldLiveOU = f.Follow3
	     , @oldLive1x2 = f.Follow5
	     , @oldLive1stHDP = f.Follow7	     
	     , @oldLive1stOU = f.Follow8
	     , @oldLive1st1x2 = f.Follow15
	     , @oldLiveOdds = f.Odds
	     , @oldLiveOdds2 = f.Odds2
	     , @oldFollower = (SELECT c.username
	                         FROM custInfo c WITH(NOLOCK)
	                        WHERE c.custid = f.Follower
	                          AND c.roleid = 1
	                      )
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
		AND f.follower = @custFollower
		AND f.FollowLive = 1
	
	-- Get old NonLive value
	SELECT @oldNonLiveHDP = f.Follow1
	     , @oldNonLiveOU = f.Follow3
	     , @oldNonLive1x2 = f.Follow5
	     , @oldNonLive1stHDP = f.Follow7	     
	     , @oldNonLive1stOU = f.Follow8
	     , @oldNonLive1st1x2 = f.Follow15
	     , @oldNonLiveOdds = f.Odds
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
		AND f.follower = @custFollower
		AND f.FollowLive = 0
	 
	SELECT @oldDanger		= danger
			,@oldDanger2	= danger2
	FROM dbo.custInfo WITH(NOLOCK)
	WHERE custid = @custid

	DELETE Cust_followBet WITH(ROWLOCK, UPDLOCK)
	WHERE custid = @custid
	AND follower = @custFollower
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Cust_FollowBet WITH(NOLOCK) WHERE custid = @CustId)
	BEGIN
		--  If remove a member, but his upline is being followed -> danger still stay at level 2
		UPDATE dbo.custInfo WITH(ROWLOCK, UPDLOCK)
		SET danger = CASE WHEN @isBA = 1 THEN 100 ELSE 0 END			
		WHERE custid = @custid
		AND (
				(@isAgent = 1) 
				OR (recommend NOT IN (SELECT cf.custid FROM dbo.Cust_FollowBet cf WITH(NOLOCK) WHERE cf.IsAgent = 1))
			)
		
		-- update downlines
		IF @isAgent = 1
		BEGIN
			SELECT ci.custid
				,(SELECT ci.custid FROM dbo.Dep_CustBAActive d WITH(NOLOCK) WHERE ci.custid = d.CustId) BACust
			INTO #Downlines
			FROM dbo.custInfo ci WITH(NOLOCK)
			WHERE ci.recommend = @custid AND ci.roleid = 1
			AND ci.custid NOT IN (SELECT cf.custid FROM dbo.Cust_FollowBet cf WITH(NOLOCK) WHERE IsAgent = 0)
			
			UPDATE ci 
			SET danger = CASE WHEN d.BACust IS NOT NULL THEN 100 ELSE 0 END				
			FROM dbo.custInfo ci WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #Downlines d ON ci.custid = d.custid
			
			DROP TABLE #Downlines
		END

	END

	-- write log
	Declare @LogSPData VARCHAR(MAX),@TrackingValueDB VARCHAR(max)

	SELECT	@LogSPData = '<Acc_AutoFollowBetDelCustomer Username="'+ COALESCE(@Username, SPACE(1)) + '" '
					   + 'follower="' + COALESCE(@follower, SPACE(1)) + '" '
	                   + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                   + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                   + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                   + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

	SELECT	@TrackingValueDB = '<Acc_AutoFollowBetDelCustomer Username="'+ COALESCE(@Username, SPACE(1)) + '" '
	                         + 'Rate="' + COALESCE(CAST(@oldRate AS VARCHAR(10)), SPACE(1)) + '" '
	                         + 'Rate2="' + COALESCE(CAST(@oldRate2 AS VARCHAR(10)), SPACE(1)) + '" '
	                         + 'oldLiveOdds="' + COALESCE(CAST(@oldLiveOdds AS VARCHAR(30)), SPACE(1))+'" '
	                         + 'oldLiveOdds2="' + COALESCE(CAST(@oldLiveOdds2 AS VARCHAR(30)), SPACE(1))+'" '
	                         + 'oldLiveHDP="' + COALESCE(CAST(@oldLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                         + 'oldLiveOU="' + COALESCE(CAST(@oldLiveOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldLive1x2="' + COALESCE(CAST(@oldLive1x2 AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldLive1stHDP="' + COALESCE(CAST(@oldLive1stHDP AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldLive1stOU="' + COALESCE(CAST(@oldLive1stOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldLive1st1x2="' + COALESCE(CAST(@oldLive1st1x2 AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLiveOdds="' + COALESCE(CAST(@oldNonLiveOdds AS VARCHAR(30)), SPACE(1))+'" '
	                         + 'oldNonLiveOdds2="' + COALESCE(CAST(@oldNonLiveOdds2 AS VARCHAR(30)), SPACE(1))+'" '
	                         + 'oldNonLiveHDP="' + COALESCE(CAST(@oldNonLiveHDP AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLiveOU="' + COALESCE(CAST(@oldNonLiveOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLive1x2="' + COALESCE(CAST(@oldNonLive1x2 AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLive1stHDP="' + COALESCE(CAST(@oldNonLive1stHDP AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLive1stOU="' + COALESCE(CAST(@oldNonLive1stOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLive1st1x2="' + COALESCE(CAST(@oldNonLive1st1x2 AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldDanger="' + COALESCE(CAST(@oldDanger AS VARCHAR(10)), SPACE(1))+'" '
	                         + 'oldDanger2="' + COALESCE(CAST(@oldDanger2 AS VARCHAR(10)), SPACE(1))+'" '
	                         + 'Follower="' + COALESCE(@follower, SPACE(1)) + '" '
	                         + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                         + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                         + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                         + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1))+'" />'
	
	SET @endRun = getdate()
	SET @duration = datediff(millisecond, @startRun, @endRun)
	
	BEGIN TRY											  						  	 
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 641,
			@TrackingValue = @LogSPData	,
			@TrackingValue2 = @TrackingValueDB,
			@duration = @duration 
	END TRY
	BEGIN CATCH
		SELECT	@LogSPData = '<Acc_AutoFollowBetDelCustomer Username="'+ COALESCE(@Username, SPACE(1)) + '" '
						   + 'follower="' + COALESCE(@follower, SPACE(1)) + '" '
	                       + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                       + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                       + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                       + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 641,
			@TrackingValue = @LogSPData	,
			@TrackingValue2 = @TrackingValueDB,
			@duration = @duration 
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetDelCustomer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetDelCustomer] TO [vnteam] AS [dbo]