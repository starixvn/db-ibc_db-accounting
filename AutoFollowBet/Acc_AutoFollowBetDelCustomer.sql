USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AutoFollowBetDelCustomer]    Script Date: 01/07/2015 15:16:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetDelCustomer]	
	@Username   VARCHAR(30),

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
		
	Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @custid             INT
	      , @startRun           DATETIME
	      , @endRun             DATETIME
	      , @duration           INT
	      , @oldRate            SMALLMONEY
	      , @oldLiveOdds        SMALLMONEY
	      , @oldNonLiveOdds     SMALLMONEY
	      , @oldLiveHDP         BIT
	      , @oldLive1stHDP      BIT
	      , @oldLiveOU          BIT
	      , @oldLive1stOU       BIT
	      , @oldNonLiveHDP      BIT
	      , @oldNonLive1stHDP   BIT
	      , @oldNonLiveOU       BIT
	      , @oldNonLive1stOU    BIT
	      , @oldFollower        VARCHAR(30)

	SELECT @startRun = GETDATE()
	     , @duration = 0

	SELECT @custid = custid
	  FROM Custinfo WITH(nolock)
	 WHERE username = @username
	   and roleid IN (1, 2)

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username ''' + @Username + ''', please try again!'
		     , @ErrCode = 101

		RETURN
	END

	IF NOT EXISTS (SELECT TOP 1 1
			     FROM Cust_followBet WITH(NOLOCK)
			    WHERE custid = @custid
			  )
	BEGIN
		SELECT @ErrMsg = 'Username ''' + @Username + ''' does not exist, please try again!'
			 , @ErrCode = 102

		RETURN
	END
	
	-- Get old Live value
	SELECT @oldRate = f.Rate
	     , @oldLiveHDP = f.Follow1
	     , @oldLive1stHDP = f.Follow7
	     , @oldLiveOU = f.Follow3
	     , @oldLive1stOU = f.Follow8
	     , @oldLiveOdds = f.Odds
	     , @oldFollower = (SELECT c.username
	                         FROM custInfo c WITH(NOLOCK)
	                        WHERE c.custid = f.Follower
	                          AND c.roleid = 1
	                      )
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
	   AND f.FollowLive = 1
	
	-- Get old NonLive value
	SELECT @oldNonLiveHDP = f.Follow1
	     , @oldNonLive1stHDP = f.Follow7
	     , @oldNonLiveOU = f.Follow3
	     , @oldNonLive1stOU = f.Follow8
	     , @oldNonLiveOdds = f.Odds
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
	   AND f.FollowLive = 0

	DELETE Cust_followBet WITH(ROWLOCK, UPDLOCK)
	 WHERE custid = @custid
	
	UPDATE dbo.custInfo WITH(ROWLOCK, UPDLOCK)
	SET danger = 0
		,danger2 = 0
	WHERE custid = @custid
	AND danger <> 100 -- danger = 100: BA customer

	-- write log
	Declare @LogSPData VARCHAR(MAX),@TrackingValueDB VARCHAR(max)

	SELECT	@LogSPData = '<Acc_AutoFollowBetDelCustomer Username="'+ COALESCE(@Username, SPACE(1)) + '" '
	                   + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                   + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                   + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                   + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

	SELECT	@TrackingValueDB = '<Acc_AutoFollowBetDelCustomer Username="'+ COALESCE(@Username, SPACE(1)) + '" '
	                         + 'Rate="' + COALESCE(CAST(@oldRate AS VARCHAR(10)), SPACE(1)) + '" '
	                         + 'oldLiveOdds="' + COALESCE(CAST(@oldLiveOdds AS VARCHAR(30)), SPACE(1))+'" '
	                         + 'oldLiveHDP="' + COALESCE(CAST(@oldLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                         + 'oldLive1stHDP="' + COALESCE(CAST(@oldLive1stHDP AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldLiveOU="' + COALESCE(CAST(@oldLiveOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldLive1stOU="' + COALESCE(CAST(@oldLive1stOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLiveOdds="' + COALESCE(CAST(@oldNonLiveOdds AS VARCHAR(30)), SPACE(1))+'" '
	                         + 'oldNonLiveHDP="' + COALESCE(CAST(@oldNonLiveHDP AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLive1stHDP="' + COALESCE(CAST(@oldNonLive1stHDP AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLiveOU="' + COALESCE(CAST(@oldNonLiveOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'oldNonLive1stOU="' + COALESCE(CAST(@oldNonLive1stOU AS VARCHAR(1)), SPACE(1))+'" '
	                         + 'Follower="' + COALESCE(CAST(@oldFollower AS VARCHAR(30)), SPACE(1))+'" '
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