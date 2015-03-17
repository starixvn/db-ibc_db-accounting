USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AutoFollowBetUpdRate]    Script Date: 03/16/2015 12:34:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetUpdRate]
    @Username      		VARCHAR(30)
  , @Rate          		SMALLMONEY
  , @LiveOdds      		SMALLMONEY
  , @NonLiveOdds   		SMALLMONEY
  , @LiveHDP       		TINYINT
  , @NonLiveHDP    		TINYINT
  , @Live1stHDP    		TINYINT
  , @NonLive1stHDP 		TINYINT
  , @LiveOU        		TINYINT
  , @NonLiveOU     		TINYINT
  , @Live1stOU     		TINYINT
  , @NonLive1stOU  		TINYINT
  , @Follower      		VARCHAR(30) 	-- Follower after changed
  , @OriginalFollower	VARCHAR(30) 	-- Follower before changed
  , @UserId        		INT
  , @IP            		VARCHAR(50) = ''
  , @ErrCode       		INT = 0 OUTPUT
  , @ErrMsg        		NVARCHAR(200) = '' OUTPUT
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTXN.CustDB
Revison:
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144] 
					  - Write log
	- 20140106@Kathy: Add param: @Follower [Redmine:#10329]
	- 20140227@Kathy: Add more param: @Odds [Redmine:#12546]
	- 20140331@Kathy: Rename xml attributes (names must not begin with a digit)
	- 20140428@Kathy: Down minimum rate from 0.3 to 0.01 [Redmine:#15495]
	- 20140805@Logan:   1. Separate live and nonlive setting [Redmine: #16578]
	                    2. Allow following an agent (all members under) [Redmine: #19650]
                        3. Do not allow member to follow himself or his agent
	- 20150311@Kathy: Support multi-follower on one customer [Redmine:#32146]                        

Param's Explanation:
    
    - For params with values = 2: those will not be updated.
    

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @custid           				INT
		  , @custFollower     				INT
		  , @custOriginalFollower     		INT
		  , @startRun         				DATETIME
		  , @endRun           				DATETIME
		  , @duration         				INT
		  , @oldRate          				SMALLMONEY
		  , @oldFollower      				VARCHAR(30)
		  , @OldLiveOdds      				SMALLMONEY
          , @OldNonLiveOdds   				SMALLMONEY
          , @OldLiveHDP       				BIT
          , @OldNonLiveHDP    				BIT
          , @OldLive1stHDP    				BIT
          , @OldNonLive1stHDP 				BIT
          , @OldLiveOU        				BIT
          , @OldNonLiveOU     				BIT
          , @OldLive1stOU     				BIT
          , @OldNonLive1stOU				BIT
          , @recommendFollower				INT
          , @recommendOriginalFollower		INT
          , @isAgent		  BIT 


	SELECT @startRun = getdate()
		 , @duration = 0

	SELECT @custid = custid
		 , @isAgent = CASE
	                   WHEN roleid = 1 THEN 0
	                   ELSE 1
	                 END
 	 FROM Custinfo WITH(NOLOCK)
	 WHERE username = @Username
	   AND roleid IN (1, 2)

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username, please try again!'
			 , @ErrCode = 101

		RETURN
	END

	SELECT @custFollower = custid
         , @recommendFollower = recommend
	  FROM Custinfo WITH(NOLOCK)
	 WHERE username = @Follower
	   AND roleid = 1

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid follower, please try again!'
			 , @ErrCode = 102

		RETURN
	END
	
	SELECT @custOriginalFollower = custid
		,@recommendOriginalFollower = recommend
	  FROM Custinfo WITH(NOLOCK)
	 WHERE username = @originalFollower
	   AND roleid = 1
	
	
	--Do not allow member to follow himself
	IF @custFollower = @custid
	BEGIN
	    SELECT @ErrMsg = 'User and follower are identical, please try again!'
			 , @ErrCode = 103

		RETURN
	END

    --Do not allow member to follow his agent
	IF @recommendFollower = @custid
	BEGIN
	    SELECT @ErrMsg = 'Can not follow direct upline, please try again!'
			 , @ErrCode = 104

		RETURN
	END

    --Do not allow loop-following
    SELECT 1
      FROM Cust_followBet WITH(NOLOCK)
     WHERE custid = @custFollower
       AND Follower = @custid

    IF @@rowcount <> 0
	BEGIN
		SELECT @ErrMsg = 'Do not allow loop following, please try again!'
			 , @ErrCode = 105

		RETURN
	END
	
	
	IF @Follower <> @originalFollower AND @recommendFollower <> @recommendOriginalFollower
	BEGIN
		IF EXISTS( SELECT TOP 1 1
				FROM dbo.Cust_FollowBet cf WITH(NOLOCK)
				INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON cf.Follower = ci.custid
				WHERE cf.custid = @custid
				AND ci.recommend = @recommendFollower
				AND @isAgent = 0
			) 
			BEGIN
				SELECT @ErrMsg = 'The account is already followed by this group'
					 , @ErrCode = 106
				RETURN 
			END	
		
	END
	
	-- Rate must range between 0.01 and 3, 2 decimal digits
	IF @Rate NOT BETWEEN 0.01 AND 3 
	   OR (CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 2)) <> CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 1)))
	BEGIN
		SELECT @ErrMsg = 'Invalid rate! Rate must range between 0.01 and 3'
			 , @ErrCode = 107

		RETURN
	END

	-- Validate Odds
	IF (@LiveOdds <> 2
	    AND (@LiveOdds NOT BETWEEN -0.1 AND 0.1
	         OR ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @LiveOdds, 2))) - ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @LiveOdds, 1))) <> 0
	         OR ABS(@LiveOdds) * 100 < 1 AND @LiveOdds <> 0
	        )
	   )
	   OR (@NonLiveOdds <> 2
	       AND (@NonLiveOdds NOT BETWEEN -0.1 AND 0.1
	            OR ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @NonLiveOdds, 2))) - ABS(CONVERT(FLOAT, CONVERT(NVARCHAR, @NonLiveOdds, 1))) <> 0
	            OR ABS(@NonLiveOdds) * 100 < 1 AND @NonLiveOdds <> 0
	           )
	      )
	BEGIN
		SELECT @ErrMsg = 'Invalid odds! Odds must range between -0.1 and 0.1'
			 , @ErrCode = 108

		RETURN
	END

	SELECT @oldRate = ISNULL(f.Rate, 0)
	     , @OldLiveOdds = ISNULL(f.Odds, 0)
         , @OldLiveHDP = ISNULL(f.Follow1, 0)
         , @OldLiveOU = ISNULL(f.Follow3, 0)
         , @OldLive1stHDP = ISNULL(f.Follow7, 0)
         , @OldLive1stOU = ISNULL(f.Follow8, 0)
		 , @oldFollower = (SELECT ISNULL(c.username, '')
			                 FROM custInfo c WITH(NOLOCK)
			                WHERE c.custid = f.Follower
			                  AND c.roleid = 1
			              )
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
		AND f.Follower = @custoriginalFollower
		AND f.FollowLive = 1

    SELECT @OldNonLiveOdds = ISNULL(f.Odds, 0)
         , @OldNonLiveHDP = ISNULL(f.Follow1, 0)
         , @OldNonLiveOU = ISNULL(f.Follow3, 0)
         , @OldNonLive1stHDP = ISNULL(f.Follow7, 0)
         , @OldNonLive1stOU = ISNULL(f.Follow8, 0)
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
		AND f.Follower = @custoriginalFollower
		AND f.FollowLive = 0

    IF @oldRate = @Rate
       AND @OldLiveOdds = @LiveOdds
       AND @OldLiveHDP = @LiveHDP
       AND @OldLiveOU = @LiveOU
       AND @OldLive1stHDP = @Live1stHDP
       AND @OldLive1stOU = @Live1stOU
       AND @oldFollower = @Follower
       AND @OldNonLiveOdds = @NonLiveOdds
       AND @OldNonLiveHDP = @NonLiveHDP
       AND @OldNonLiveOU = @NonLiveOU
       AND @OldNonLive1stHDP = @NonLive1stHDP
       AND @OldNonLive1stOU = @NonLive1stOU
       AND @Follower = @originalFollower
    BEGIN
        SELECT @ErrMsg = 'There is no new data for updating, please try again!'
			 , @ErrCode = 19

		RETURN
    END
    
    --Any @=2 means no update
    SELECT @LiveOdds = CASE
                         WHEN @LiveOdds = 2 THEN @OldLiveOdds
                         ELSE @LiveOdds
                       END
         , @LiveHDP = CASE
                        WHEN @LiveHDP = 2 THEN @OldLiveHDP
                        ELSE @LiveHDP
                      END
         , @LiveOU = CASE
                       WHEN @LiveOU = 2 THEN @OldLiveOU
                       ELSE @LiveOU
                     END
         , @Live1stHDP = CASE
                           WHEN @Live1stHDP = 2 THEN @OldLive1stHDP
                           ELSE @Live1stHDP
                         END
         , @Live1stOU = CASE
                          WHEN @Live1stOU = 2 THEN @OldLive1stOU
                          ELSE @Live1stOU
                        END
         , @NonLiveOdds = CASE
                            WHEN @NonLiveOdds = 2 THEN @OldNonLiveOdds
                            ELSE @NonLiveOdds
                          END
         , @NonLiveHDP = CASE
                           WHEN @NonLiveHDP = 2 THEN @OldNonLiveHDP
                           ELSE @NonLiveHDP
                         END
         , @NonLiveOU = CASE
                          WHEN @NonLiveOU = 2 THEN @OldNonLiveOU
                          ELSE @NonLiveOU
                        END
         , @NonLive1stHDP = CASE
                              WHEN @NonLive1stHDP = 2 THEN @OldNonLive1stHDP
                              ELSE @NonLive1stHDP
                            END
         , @NonLive1stOU = CASE
                             WHEN @NonLive1stOU = 2 THEN @OldNonLive1stOU
                             ELSE @NonLive1stOU
                           END


    --Update Live
	UPDATE Cust_FollowBet WITH(UPDLOCK, ROWLOCK)
	   SET rate = @Rate
		 , Follow1 = @LiveHDP
		 , Follow7 = @Live1stHDP
		 , Follow3 = @LiveOU
		 , Follow8 = @Live1stOU
		 , Follower = @custFollower
		 , Odds = @LiveOdds
	 WHERE custid = @custid
	   AND FollowLive = 1
	   AND Follower = @custoriginalFollower

    --Update Non-Live
    UPDATE Cust_FollowBet WITH(UPDLOCK, ROWLOCK)
	   SET rate = @Rate
		 , Follow1 = @NonLiveHDP
		 , Follow7 = @NonLive1stHDP
		 , Follow3 = @NonLiveOU
		 , Follow8 = @NonLive1stOU
		 , Follower = @custFollower
		 , Odds = @NonLiveOdds
	 WHERE custid = @custid
	   AND FollowLive = 0
	   AND Follower = @custoriginalFollower

	-- write log
	DECLARE @LogSPData VARCHAR(MAX)
		  , @TrackingValueDB VARCHAR(max)

	SELECT @LogSPData = '<Acc_AutoFollowBetUpdRate Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                  + 'Rate="' + COALESCE(CAST(@Rate AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'LiveHDP="' + COALESCE(CAST(@LiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1stHDP="' + COALESCE(CAST(@Live1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'LiveOU="' + COALESCE(CAST(@LiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'Live1stOU="' + COALESCE(CAST(@Live1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLiveHDP="' + COALESCE(CAST(@NonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1stHDP="' + COALESCE(CAST(@NonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLiveOU="' + COALESCE(CAST(@NonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'NonLive1stOU="' + COALESCE(CAST(@NonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                  + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

	SELECT @TrackingValueDB = '<Acc_AutoFollowBetUpdRate Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                        + 'Rate="' + coalesce(cast(@oldRate AS VARCHAR(10)), space(1)) + '" '
	                        + 'LiveHDP="' + COALESCE(CAST(@OldLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'Live1stHDP="' + COALESCE(CAST(@OldLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'LiveOU="' + COALESCE(CAST(@OldLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'Live1stOU="' + COALESCE(CAST(@OldLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLiveHDP="' + COALESCE(CAST(@OldNonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLive1stHDP="' + COALESCE(CAST(@OldNonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLiveOU="' + COALESCE(CAST(@OldNonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLive1stOU="' + COALESCE(CAST(@OldNonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'LiveOdds="' + COALESCE(CAST(@OldLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                        + 'NonLiveOdds="' + COALESCE(CAST(@OldNonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                        + 'Follower="' + COALESCE(CAST(@oldFollower AS VARCHAR(30)), SPACE(1)) + '" '
	                        + 'UserId="' + coalesce(cast(@UserId AS VARCHAR(50)), space(1)) + '" '
	                        + 'IP="' + coalesce(cast(@IP AS VARCHAR(50)), space(1)) + '" '
	                        + 'ErrCode="' + coalesce(cast(@ErrCode AS VARCHAR(10)), space(1)) + '" '
	                        + 'ErrMsg="' + coalesce(cast(@ErrMsg AS VARCHAR(400)), space(1)) + '" />'

	SET @endRun = getdate()
	SET @duration = datediff(millisecond, @startRun, @endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
		  , @CustID = @CustID
		  , @ActionID = 640
		  , @TrackingValue = @LogSPData
		  , @TrackingValue2 = @TrackingValueDB
		  , @duration = @duration
	END TRY

	BEGIN CATCH
		SELECT @LogSPData = '<Acc_AutoFollowBetUpdRate Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                      + 'Rate="' + COALESCE(CAST(@Rate AS VARCHAR(10)), SPACE(1)) + '" '
	                      + 'LiveHDP="' + COALESCE(CAST(@LiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1stHDP="' + COALESCE(CAST(@Live1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'LiveOU="' + COALESCE(CAST(@LiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'Live1stOU="' + COALESCE(CAST(@Live1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLiveHDP="' + COALESCE(CAST(@NonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1stHDP="' + COALESCE(CAST(@NonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLiveOU="' + COALESCE(CAST(@NonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'NonLive1stOU="' + COALESCE(CAST(@NonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                      + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                      + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                      + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                      + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
		  , @CustID = @CustID
		  , @ActionID = 640
		  , @TrackingValue = @LogSPData
		  , @TrackingValue2 = @TrackingValueDB
		  , @duration = @duration

	END CATCH
END






GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetUpdRate] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetUpdRate] TO [vnteam] AS [dbo]