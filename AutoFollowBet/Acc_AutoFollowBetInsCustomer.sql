
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_AutoFollowBetInsCustomer    Script Date: 8/29/2014 9:35:01 AM ******/
CREATE PROCEDURE [dbo].[Acc_AutoFollowBetInsCustomer]
    @Username       VARCHAR(30)
    ,@Rate          SMALLMONEY
    ,@LiveOdds      SMALLMONEY
    ,@NonLiveOdds   SMALLMONEY
    ,@LiveHDP       BIT
    ,@NonLiveHDP    BIT
    ,@Live1stHDP    BIT
    ,@NonLive1stHDP BIT
    ,@LiveOU        BIT
    ,@NonLiveOU     BIT
    ,@Live1stOU     BIT
    ,@NonLive1stOU  BIT
    ,@Follower      VARCHAR(30)
    ,@UserId        INT
    ,@IP            VARCHAR(50)
    ,@ErrCode       INT = 0 OUTPUT
    ,@ErrMsg        NVARCHAR(200) = '' OUTPUT
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTXN.CustDB

Revision:
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144]
					  - Write log
	- 20140106@Kathy: Add param: @Follower [Redmine:#10329]
	- 20140227@Kathy: Add param: @Odds [Redmine:#12546]
	- 20140331@Kathy: Rename xml attributes (names must not begin with a digit)
	- 20140428@Kathy: Down minimum rate from 0.3 to 0.01 [Redmine:#15495]
	- 20140804@Logan:   1. Separate live and nonlive setting [Redmine: #16578]
	                    2. Allow following an agent (all members under) [Redmine: #19650]
	                    3. Do not allow member to follow himself or his agent
	                    4. Do not allow loop following

Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		  , @endRun DATETIME
		  , @duration INT

	SELECT @startRun = getdate()
		 , @duration = 0

	DECLARE @custid     INT
		  , @custFollow INT
		  , @roleid     BIT
		  , @recommend  INT

	SELECT @custid = custid
	     , @roleid = CASE
	                   WHEN roleid = 1 THEN 0
	                   ELSE 1
	                 END
	  FROM Custinfo WITH(NOLOCK)
	 WHERE username = @Username
	   AND roleid IN (1, 2) --member or agent

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username, please try again!'
			 , @ErrCode = 101

		RETURN
	END

	IF EXISTS (SELECT TOP 1 1
			     FROM Cust_followBet WITH(NOLOCK)
			    WHERE custid = @custid
			  )
	BEGIN
		SELECT @ErrMsg = 'Username existed, please try again!'
			 , @ErrCode = 102

		RETURN
	END

	SELECT @custFollow = c.custid
         , @recommend = recommend
	  FROM custInfo c WITH(NOLOCK)
	 WHERE c.username = @Follower
	   AND roleid     = 1  

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid follower, please try again!'
			 , @ErrCode = 103

		RETURN
	END
	
	--Do not allow member to follow himself
	IF @custFollow = @custid
	BEGIN
	    SELECT @ErrMsg = 'User and follower are identical, please try again!'
			 , @ErrCode = 106

		RETURN
	END

    --Do not allow member to follow his agent
	IF @recommend = @custid
	BEGIN
	    SELECT @ErrMsg = 'Can not follow direct upline, please try again!'
			 , @ErrCode = 107

		RETURN
	END

    --Do not allow loop-following
    SELECT 1
      FROM Cust_FollowBet WITH(NOLOCK)
     WHERE custid = @custFollow
       AND Follower = @custid

    IF @@rowcount <> 0
	BEGIN
		SELECT @ErrMsg = 'Do not allow loop following, please try again!'
			 , @ErrCode = 109

		RETURN
	END

	--Not follow any bettype
	IF @LiveHDP = 0
	    AND @LiveOU = 0
	    AND @Live1stHDP = 0
	    AND @Live1stOU = 0
	    AND @NonLiveHDP = 0
	    AND @NonLive1stHDP = 0
	    AND @NonLiveOU = 0
	    AND @NonLive1stOU = 0
    BEGIN
		SELECT @ErrMsg = 'Must follow at least 1 bettype, please try again!'
			 , @ErrCode = 108

		RETURN
	END	    
	    
	-- Rate must range between 0.01 and 3, 2 decimal digits
	IF @Rate NOT BETWEEN 0.01 AND 3 
	   OR (CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 2)) <> CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 1)))
	BEGIN
		SELECT @ErrMsg = 'Invalid rate! Rate must range between 0.01 and 3'
			 , @ErrCode = 104

		RETURN
	END

	-- Validate Odds
	IF (@LiveOdds NOT BETWEEN -0.1 AND 0.1)
	   OR (@NonLiveOdds NOT BETWEEN -0.1 AND 0.1)
	   OR (ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @LiveOdds, 2))) - ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @LiveOdds, 1))) <> 0 )
	   OR (ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @NonLiveOdds, 2))) - ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @NonLiveOdds, 1))) <> 0 )
	   OR (ABS(@LiveOdds) * 100 < 1 and @LiveOdds <> 0)
	   OR (ABS(@NonLiveOdds) * 100 < 1 and @NonLiveOdds <> 0)

	BEGIN
		SELECT @ErrMsg = 'Invalid odds! Odds must range between -0.1 and 0.1'
			 , @ErrCode = 105

		RETURN
	END 


    --Live
	INSERT INTO Cust_FollowBet
	(
	    custid
	   	,Rate
		,src
		,FollowLive
		,Follow1
		,Follow3
		,Follow7
		,Follow8
		,Follower
		,Odds
		,IsAgent
    )
    VALUES
	(
	    @custid
		,@Rate
		,0
		,1
		,@LiveHDP
		,@LiveOU
		,@Live1stHDP
		,@Live1stOU
		,@custFollow
		,@LiveOdds
		,@roleid
    )

    --NonLive
	INSERT INTO Cust_FollowBet
	(
	    custid
	   	,Rate
		,src
		,FollowLive
		,Follow1
		,Follow3
		,Follow7
		,Follow8
		,Follower
		,Odds
		    ,IsAgent
	    )
	    VALUES
	    (
	        @custid
		    ,@Rate
		    ,0
		    ,0
		    ,@NonLiveHDP
		    ,@NonLiveOU
		    ,@NonLive1stHDP
		    ,@NonLive1stOU
		    ,@custFollow
		    ,@NonLiveOdds
		    ,@roleid
        )
    /*END*/

	-- write log
	DECLARE @LogSPData VARCHAR(MAX)

	SELECT @LogSPData = '<Acc_AutoFollowBetInsCustomer Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                  + 'Rate="' + COALESCE(CAST(@Rate AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'LiveHDP="' + COALESCE(CAST(@LiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'LiveOU="' + COALESCE(CAST(@LiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1stHDP="' + COALESCE(CAST(@Live1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1stOU="' + COALESCE(CAST(@Live1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLiveHDP="' + COALESCE(CAST(@NonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLiveOU="' + COALESCE(CAST(@NonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1stHDP="' + COALESCE(CAST(@NonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1stOU="' + COALESCE(CAST(@NonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

	SET @endRun = getdate()
	SET @duration = datediff(millisecond, @startRun, @endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
			,@CustID = @CustID
			,@ActionID = 639
			,@TrackingValue = @LogSPData
			,@duration = @duration
	END TRY

	BEGIN CATCH
		SELECT @LogSPData = '<Acc_AutoFollowBetInsCustomer Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                      + 'Rate="' + COALESCE(CAST(@Rate AS VARCHAR(10)), SPACE(1)) + '" '
	                      + 'LiveHDP="' + COALESCE(CAST(@LiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'LiveOU="' + COALESCE(CAST(@LiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1stHDP="' + COALESCE(CAST(@Live1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1stOU="' + COALESCE(CAST(@Live1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLiveHDP="' + COALESCE(CAST(@NonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLiveOU="' + COALESCE(CAST(@NonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1stHDP="' + COALESCE(CAST(@NonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1stOU="' + COALESCE(CAST(@NonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                      + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                      + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                      + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
			,@CustID = @CustID
			,@ActionID = 639
			,@TrackingValue = @LogSPData
			,@duration = @duration
	END CATCH
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [bodbAdminNet]
GO 
