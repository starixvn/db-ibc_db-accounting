USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AutoFollowBetInsCustomer]    Script Date: 04/14/2015 09:59:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_AutoFollowBetInsCustomer    Script Date: 08/04/2015 9:36:37 AM ******/
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetInsCustomer]
    @Username       VARCHAR(30)
    ,@Rate          SMALLMONEY
    ,@Rate2         SMALLMONEY
    ,@LiveOdds      SMALLMONEY
    ,@NonLiveOdds   SMALLMONEY
    ,@LiveOdds2     SMALLMONEY
    ,@NonLiveOdds2  SMALLMONEY
    ,@LiveHDP       BIT -- 1
    ,@NonLiveHDP    BIT
    ,@LiveOU        BIT -- 3
    ,@NonLiveOU     BIT
    ,@Live1x2       BIT -- 5
    ,@NonLive1x2    BIT
    ,@Live1stHDP    BIT -- 7
    ,@NonLive1stHDP BIT
    ,@Live1stOU     BIT -- 8
    ,@NonLive1stOU  BIT
    ,@Live1st1x2    BIT -- 15
    ,@NonLive1st1x2 BIT
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
		- 20141230@Kathy: Update the accounts dangerous setting change to "2" for Original & Non Live [Redmine:#25770]
		- 20150120@Kathy: Update Original and Nonlive danger level of BA member to 2 [Redmine:#29459]
		- 20150311@Kathy: Support multi-follower on one customer [Redmine:#32146]
		- 20150323@Kathy: - Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]   
						  - Update danger, danger2 for downlines	
		
	Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME
		  , @endRun		DATETIME
		  , @duration	INT
		  , @oldDanger	INT
		  ,	@oldDanger2	INT

	SELECT @startRun = getdate()
		 , @duration = 0

	DECLARE @custid				INT
		  , @custFollower		INT
		  , @isAgent			BIT --@roleid     BIT
		  , @recommendFollower  INT

	SELECT @custid = custid
	     , @isAgent = CASE
	                   WHEN roleid = 1 THEN 0
	                   ELSE 1
	                 END
	  FROM Custinfo WITH(NOLOCK)
	 WHERE username = @Username
	   AND roleid IN (1, 2) --member or agent

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username '''+ @Username +''', please try again!'
			 , @ErrCode = 101

		RETURN
	END

	--IF EXISTS (SELECT TOP 1 1
	--		     FROM Cust_followBet WITH(NOLOCK)
	--		    WHERE custid = @custid
	--		  )
	--BEGIN
	--	SELECT @ErrMsg = 'Username ''' + @Username +''' existed, please try again!'
	--		 , @ErrCode = 102

	--	RETURN
	--END
	
	SELECT @custFollower = c.custid
         , @recommendFollower = recommend
	  FROM custInfo c WITH(NOLOCK)
	 WHERE c.username = @Follower
	   AND roleid     = 1  

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid follower, please try again!'
			 , @ErrCode = 102

		RETURN
	END
	
	--Do not allow member to follow himself
	IF @custFollower = @custid
	BEGIN
	    SELECT @ErrMsg = 'User '''+ @Username +''' and follower are identical, please try again!'
			 , @ErrCode = 103

		RETURN
	END

    --Do not allow member to follow his agent
	IF @recommendFollower = @custid
	BEGIN
	    SELECT @ErrMsg = 'Can not follow direct upline ''' + @Username + ''', please try again!'
			 , @ErrCode = 104

		RETURN
	END

    --Do not allow loop-following
    IF EXISTS (SELECT TOP 1 1 FROM Cust_FollowBet WITH(NOLOCK) WHERE custid = @custFollower AND Follower = @custid)
	BEGIN
		SELECT @ErrMsg ='Do not allow loop following: ''' + @Username + ''' , please try again!'
			 , @ErrCode = 105

		RETURN
	END


	-- (custid, follower) is existed
	IF EXISTS (SELECT TOP 1 1 FROM dbo.Cust_FollowBet WITH(NOLOCK) WHERE custid = @custid AND Follower = @custFollower)
	BEGIN
		SELECT @ErrMsg = 'The member ''' + @Username + ''' is followed by this follower already! Please try again'
			 , @ErrCode = 106
			 
		RETURN 
	END
	ELSE
	BEGIN
		-- Not allow to follow 1 member by different follower has the same group
		-- Not allow to follow 1 agent by different follower has the same group
		
		IF EXISTS( SELECT TOP 1 1
			FROM dbo.Cust_FollowBet cf WITH(NOLOCK)
			INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON cf.Follower = ci.custid
			WHERE cf.custid = @custid
			AND ci.recommend = @recommendFollower
			
		)
		BEGIN
			SELECT @ErrMsg = 'The account '''+ @username + ''' is already followed by this group'
				 , @ErrCode = 107
			RETURN 
		END	
	END
	
	--Not follow any bettype
	IF @LiveHDP = 0
	    AND @LiveOU = 0
	    AND @Live1x2 = 0
	    AND @Live1stHDP = 0
	    AND @Live1stOU = 0
	    AND @Live1st1x2 = 0
	    AND @NonLiveHDP = 0
	    AND @NonLiveOU = 0
	    AND @NonLive1x2 = 0
	    AND @NonLive1stHDP = 0
	    AND @NonLive1stOU = 0
	    AND @NonLive1st1x2 = 0
    BEGIN
		SELECT @ErrMsg = 'Must follow at least 1 bettype, please try again!'
			 , @ErrCode = 108

		RETURN
	END	    
	    
	-- Rate must range between 0.01 and 3
	IF @Rate NOT BETWEEN 0.01 AND 3
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for O/U and HDP group! Rate must range between 0.01 and 3'
			 , @ErrCode = 109

		RETURN
	END
	
	IF @Rate2 NOT BETWEEN 0.01 AND 3 
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for 1x2 Group! Rate must range between 0.01 and 3'
			 , @ErrCode = 109

		RETURN
	END
	
	-- Don't allow to save rate with 3 decimal digits
	IF CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 2)) <> CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 1))
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for O/U and HDP group! Don''t enter the number with more than 2 decimal places.'
			 , @ErrCode = 110

		RETURN
	END
	
	IF (CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate2, 2)) <> CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate2, 1)))
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for 1x2 Group! Don''t enter the number with more than 2 decimal places.'
			 , @ErrCode = 110

		RETURN
	END

	
	-- Validate Odds: Odds must range between -0.1 and 0.1, 2 decimal digits		
	IF (@LiveOdds NOT BETWEEN -0.1 AND 0.1)
	   OR (@NonLiveOdds NOT BETWEEN -0.1 AND 0.1)
	   OR (CONVERT(SMALLMONEY, RTRIM(CONVERT(CHAR(10),@LiveOdds * 100))) %1 <> 0)
	   OR (CONVERT(SMALLMONEY, RTRIM(CONVERT(CHAR(10),@NonLiveOdds * 100))) %1 <> 0)
	   OR (@LiveOdds2 NOT BETWEEN -0.1 AND 0.1)
	   OR (@NonLiveOdds2 NOT BETWEEN -0.1 AND 0.1)
	   OR (CONVERT(SMALLMONEY, RTRIM(CONVERT(CHAR(10),@LiveOdds2 * 100))) %1 <> 0)
	   OR (CONVERT(SMALLMONEY, RTRIM(CONVERT(CHAR(10),@NonLiveOdds2 * 100))) %1 <> 0)
	BEGIN
		SELECT @ErrMsg = 'Invalid odds! Odds must range between -0.1 and 0.1'
			 , @ErrCode = 111

		RETURN
	END 


    --Live
	INSERT INTO Cust_FollowBet
	(
	    custid
	   	,Rate
	   	,Rate2
		,src
		,FollowLive
		,Follow1
		,Follow3
		,Follow5
		,Follow7
		,Follow8
		,Follow15
		,Follower
		,Odds
		,Odds2
		,IsAgent
    )
    VALUES
	(
	    @custid
		,@Rate
		,@Rate2
		,0
		,1
		,@LiveHDP
		,@LiveOU
		,@Live1x2
		,@Live1stHDP
		,@Live1stOU
		,@Live1st1x2
		,@custFollower
		,@LiveOdds
		,@LiveOdds2
		,@isAgent
    )

    --NonLive
	INSERT INTO Cust_FollowBet
	(
	    custid
	   	,Rate
	   	,Rate2
		,src
		,FollowLive
		,Follow1
		,Follow3
		,Follow5
		,Follow7
		,Follow8
		,Follow15
		,Follower
		,Odds
		,Odds2
		,IsAgent
	    )
	    VALUES
	    (
	        @custid
		    ,@Rate
		    ,@Rate2
		    ,0
		    ,0
		    ,@NonLiveHDP
		    ,@NonLiveOU
		    ,@NonLive1x2
		    ,@NonLive1stHDP
		    ,@NonLive1stOU
		    ,@NonLive1st1x2
		    ,@custFollower
		    ,@NonLiveOdds
		    ,@NonLiveOdds2		    
		    ,@isAgent
        )
    /*END*/
    
    -- Update the accounts dangerous setting change to "2" for Live & Non Live
    UPDATE dbo.custInfo WITH(UPDLOCK, ROWLOCK)
    SET danger = 2
		,danger2 = 2
	WHERE custid = @custid
	
	-- update downlines
	IF @isAgent = 1
	BEGIN
		UPDATE dbo.custInfo WITH(UPDLOCK, ROWLOCK)
		SET danger = 2
			,danger2 = 2
		WHERE recommend = @custid AND roleid = 1
	END	    

	-- write log
	DECLARE @LogSPData			VARCHAR(MAX)
			,@TrackingValueDB	VARCHAR(max)
	
	SELECT @oldDanger		= danger
			,@oldDanger2	= danger2
	FROM dbo.custInfo WITH(NOLOCK)
	WHERE custid = @custid

	SELECT @LogSPData = '<Acc_AutoFollowBetInsCustomer Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                  + 'Rate="' + COALESCE(CAST(@Rate AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'Rate2="' + COALESCE(CAST(@Rate2 AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'LiveHDP="' + COALESCE(CAST(@LiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'LiveOU="' + COALESCE(CAST(@LiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1x2="' + COALESCE(CAST(@Live1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1stHDP="' + COALESCE(CAST(@Live1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1stOU="' + COALESCE(CAST(@Live1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1st1x2="' + COALESCE(CAST(@Live1st1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLiveHDP="' + COALESCE(CAST(@NonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '	                  
	                  + 'NonLiveOU="' + COALESCE(CAST(@NonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1x2="' + COALESCE(CAST(@NonLive1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1stHDP="' + COALESCE(CAST(@NonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1stOU="' + COALESCE(CAST(@NonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1st1x2="' + COALESCE(CAST(@NonLive1st1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'LiveOdds2="' + COALESCE(CAST(@LiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'NonLiveOdds2="' + COALESCE(CAST(@NonLiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'
	
	SELECT @TrackingValueDB = '<Acc_AutoFollowBetInsCustomer Danger="' + COALESCE(CAST(@oldDanger AS VARCHAR(10)), SPACE(1)) + '" '	          
	                        + 'Danger2="' + COALESCE(CAST(@oldDanger2 AS VARCHAR(10)), SPACE(1)) + '" />'
	                        
	SET @endRun = getdate()
	SET @duration = datediff(millisecond, @startRun, @endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
			,@CustID = @CustID
			,@ActionID = 639
			,@TrackingValue = @LogSPData
			,@TrackingValue2 = @TrackingValueDB
			,@duration = @duration
	END TRY

	BEGIN CATCH
		SELECT @LogSPData = '<Acc_AutoFollowBetInsCustomer Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                      + 'Rate="' + COALESCE(CAST(@Rate AS VARCHAR(10)), SPACE(1)) + '" '
	                      + 'Rate2="' + COALESCE(CAST(@Rate2 AS VARCHAR(10)), SPACE(1)) + '" '
	                      + 'LiveHDP="' + COALESCE(CAST(@LiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'LiveOU="' + COALESCE(CAST(@LiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1x2="' + COALESCE(CAST(@Live1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1stHDP="' + COALESCE(CAST(@Live1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1stOU="' + COALESCE(CAST(@Live1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1st1x2="' + COALESCE(CAST(@Live1st1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLiveHDP="' + COALESCE(CAST(@NonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLiveOU="' + COALESCE(CAST(@NonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1x2="' + COALESCE(CAST(@NonLive1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1stHDP="' + COALESCE(CAST(@NonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1stOU="' + COALESCE(CAST(@NonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1st1x2="' + COALESCE(CAST(@NonLive1st1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'LiveOdds2="' + COALESCE(CAST(@LiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '	                      
	                      + 'NonLiveOdds2="' + COALESCE(CAST(@NonLiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                      + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                      + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                      + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
			,@CustID = @CustID
			,@ActionID = 639
			,@TrackingValue = @LogSPData
			,@TrackingValue2 = @TrackingValueDB
			,@duration = @duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [vnteam] AS [dbo]