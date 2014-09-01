
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_AutoFollowBetDelCustomer    Script Date: 8/29/2014 9:35:01 AM ******/
CREATE PROCEDURE [Acc_AutoFollowBetDelCustomer]	
	@Username   varchar(30),

	@UserId		INT,
	@IP			VARCHAR(50),
	@ErrCode    int = 0 Output,
	@ErrMsg     nvarchar(200) = '' Output
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

	Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @custid             int
	      , @startRun           Datetime
	      , @endRun             datetime
	      , @duration           int
	      , @oldRate            smallmoney
	      , @oldLiveOdds        smallmoney
	      , @oldNonLiveOdds     smallmoney
	      , @oldLiveHDP         bit
	      , @oldLive1stHDP      bit
	      , @oldLiveOU          bit
	      , @oldLive1stOU       bit
	      , @oldNonLiveHDP      bit
	      , @oldNonLive1stHDP   bit
	      , @oldNonLiveOU       bit
	      , @oldNonLive1stOU    bit
	      , @oldFollower        varchar(30)

	SELECT @startRun = getdate()
	     , @duration = 0

	SELECT @custid = custid
	  FROM Custinfo with(nolock)
	 WHERE username = @username
	   and roleid IN (1, 2)

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username'
		     , @ErrCode = 101

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

	DELETE Cust_followBet
	 WHERE custid = @custid

	-- write log
	Declare @LogSPData varchar(MAX),@TrackingValueDB varchar(max)

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
	
	set @endRun = getdate()
	set @duration = datediff(millisecond, @startRun, @endRun)
	
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

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetDelCustomer] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetDelCustomer] TO [bodbAdminNet]
GO 
