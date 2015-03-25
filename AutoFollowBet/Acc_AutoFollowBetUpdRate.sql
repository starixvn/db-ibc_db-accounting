USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AutoFollowBetUpdRate]    Script Date: 03/25/2015 09:34:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_AutoFollowBetUpdRate    Script Date: 24/03/2015 3:16:15 PM ******/
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetUpdRate]
    @Username      		VARCHAR(30)
    
  , @Rate          		SMALLMONEY
  , @Rate2				SMALLMONEY
  
  , @LiveOdds2			SMALLMONEY
  , @NonLiveOdds2		SMALLMONEY	
  , @LiveOdds      		SMALLMONEY
  , @NonLiveOdds   		SMALLMONEY
  
  , @LiveHDP       		TINYINT	-- 1
  , @NonLiveHDP    		TINYINT  
  , @LiveOU        		TINYINT -- 3
  , @NonLiveOU     		TINYINT 
  , @Live1x2			TINYINT	-- 5
  , @NonLive1x2			TINYINT	
  , @Live1stHDP    		TINYINT -- 7
  , @NonLive1stHDP 		TINYINT
  , @Live1stOU     		TINYINT -- 8
  , @NonLive1stOU  		TINYINT  
  , @Live1st1x2			TINYINT -- 15
  , @NonLive1st1x2		TINYINT	
  
  , @Follower      		VARCHAR(30) 	-- Follower after changed
  , @OriginalFollower	VARCHAR(30) 	-- Follower before changed
  
  , @UserId        		INT
  , @IP            		VARCHAR(50) = ''
  , @ErrCode       		INT = 0				OUTPUT
  , @ErrMsg        		NVARCHAR(200) = ''	OUTPUT
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
		- 20150323@Kathy: Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]             

	Param's Explanation:
	    
		- For params with values = 2: those will not be updated.
		* @Rate, @LiveOdds, @NonLiveOdds: for bettypes 1, 3, 7, 8 
		* @Rate2, @LiveOdds2, @NonLiveOdds2: for bettypes 5, 15
	    

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun         				DATETIME
		  , @endRun           				DATETIME
		  , @duration         				INT
		            	  
		  , @oldRate          				SMALLMONEY
		  , @oldRate2						SMALLMONEY
		  
		  , @oldFollower      				VARCHAR(30)
		  
		  , @OldLiveOdds      				SMALLMONEY
          , @OldNonLiveOdds   				SMALLMONEY
          , @OldLiveOdds2     				SMALLMONEY
          , @OldNonLiveOdds2  				SMALLMONEY

          , @OldLiveHDP       				BIT -- 1
          , @OldNonLiveHDP    				BIT
          , @OldLiveOU        				BIT -- 3
          , @OldNonLiveOU     				BIT
          , @OldLive1x2     				BIT -- 5
          , @OldNonLive1x2					BIT
          , @OldLive1stHDP    				BIT -- 7
          , @OldNonLive1stHDP 				BIT
          , @OldLive1stOU     				BIT -- 8
          , @OldNonLive1stOU				BIT          
          , @OldLive1st1x2     				BIT -- 15
          , @OldNonLive1st1x2				BIT
          
          , @custid           				INT
		  , @custFollower     				INT
		  , @custOriginalFollower     		INT
		  , @recommendFollower				INT
          , @recommendOriginalFollower		INT
          , @isAgent						BIT 


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

	SELECT @oldRate			= ISNULL(f.Rate, 0)
		 , @oldRate2		= ISNULL(f.Rate2, 0)		 
	     , @OldLiveOdds		= ISNULL(f.Odds, 0)
	     , @OldLiveOdds2	= ISNULL(f.Odds2, 0)	     
         , @OldLiveHDP		= ISNULL(f.Follow1, 0)
         , @OldLiveOU		= ISNULL(f.Follow3, 0)
         , @OldLive1x2		= ISNULL(f.Follow5, 0)
         , @OldLive1stHDP	= ISNULL(f.Follow7, 0)
         , @OldLive1stOU	= ISNULL(f.Follow8, 0)
         , @OldLive1st1x2	= ISNULL(f.Follow15, 0)
		 , @oldFollower		= (SELECT ISNULL(c.username, '')
								FROM custInfo c WITH(NOLOCK)
								WHERE c.custid = f.Follower
								AND c.roleid = 1
			              )
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
		AND f.Follower = @custoriginalFollower
		AND f.FollowLive = 1

    SELECT @OldNonLiveOdds		= ISNULL(f.Odds, 0)
		 , @OldNonLiveOdds2		= ISNULL(f.Odds2, 0)
         , @OldNonLiveHDP		= ISNULL(f.Follow1, 0)
         , @OldNonLiveOU		= ISNULL(f.Follow3, 0)
         , @OldNonLive1x2		= ISNULL(f.Follow5, 0)
         , @OldNonLive1stHDP	= ISNULL(f.Follow7, 0)
         , @OldNonLive1stOU		= ISNULL(f.Follow8, 0)
         , @OldNonLive1st1x2	= ISNULL(f.Follow15, 0)
	  FROM Cust_FollowBet f WITH(NOLOCK)
	 WHERE f.custid = @custid
		AND f.Follower = @custoriginalFollower
		AND f.FollowLive = 0

    IF @oldRate = @Rate
	   AND @oldRate2 = @Rate2
       AND @OldLiveOdds = @LiveOdds
       AND @OldLiveOdds2 = @LiveOdds2
       AND @OldLiveHDP = @LiveHDP
       AND @OldLiveOU = @LiveOU
       AND @OldLive1x2 = @Live1x2
       AND @OldLive1stHDP = @Live1stHDP
       AND @OldLive1stOU = @Live1stOU
       AND @OldLive1st1x2 = @Live1st1x2
       AND @oldFollower = @Follower
       AND @OldNonLiveOdds = @NonLiveOdds
       AND @OldNonLiveOdds2 = @NonLiveOdds2
       AND @OldNonLiveHDP = @NonLiveHDP
       AND @OldNonLiveOU = @NonLiveOU
       AND @OldNonLive1x2 = @NonLive1x2
       AND @OldNonLive1stHDP = @NonLive1stHDP
       AND @OldNonLive1stOU = @NonLive1stOU
       AND @OldNonLive1st1x2 = @NonLive1st1x2
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
         , @LiveOdds2 = CASE
                         WHEN @LiveOdds2 = 2 THEN @OldLiveOdds2
                         ELSE @LiveOdds2
                       END
         , @LiveHDP = CASE
                        WHEN @LiveHDP = 2 THEN @OldLiveHDP
                        ELSE @LiveHDP
                      END
         , @LiveOU = CASE
                       WHEN @LiveOU = 2 THEN @OldLiveOU
                       ELSE @LiveOU
                     END
         , @Live1x2 = CASE
                       WHEN @Live1x2 = 2 THEN @OldLive1x2
                       ELSE @Live1x2
                     END
         , @Live1stHDP = CASE
                           WHEN @Live1stHDP = 2 THEN @OldLive1stHDP
                           ELSE @Live1stHDP
                         END
         , @Live1stOU = CASE
                          WHEN @Live1stOU = 2 THEN @OldLive1stOU
                          ELSE @Live1stOU
                        END
          , @Live1st1x2 = CASE
                       WHEN @Live1st1x2 = 2 THEN @OldLive1st1x2
                       ELSE @Live1st1x2
                     END
         , @NonLiveOdds = CASE
                            WHEN @NonLiveOdds = 2 THEN @OldNonLiveOdds
                            ELSE @NonLiveOdds
                          END
          , @NonLiveOdds2 = CASE
                            WHEN @NonLiveOdds2 = 2 THEN @OldNonLiveOdds2
                            ELSE @NonLiveOdds2
                          END
         , @NonLiveHDP = CASE
                           WHEN @NonLiveHDP = 2 THEN @OldNonLiveHDP
                           ELSE @NonLiveHDP
                         END
         , @NonLiveOU = CASE
                          WHEN @NonLiveOU = 2 THEN @OldNonLiveOU
                          ELSE @NonLiveOU
                        END
          , @NonLive1x2 = CASE
                          WHEN @NonLive1x2 = 2 THEN @OldNonLive1x2
                          ELSE @NonLive1x2
                        END              
         , @NonLive1stHDP = CASE
                              WHEN @NonLive1stHDP = 2 THEN @OldNonLive1stHDP
                              ELSE @NonLive1stHDP
                            END
         , @NonLive1stOU = CASE
                             WHEN @NonLive1stOU = 2 THEN @OldNonLive1stOU
                             ELSE @NonLive1stOU
                           END
		 , @NonLive1st1x2 = CASE
                          WHEN @NonLive1st1x2 = 2 THEN @OldNonLive1st1x2
                          ELSE @NonLive1st1x2
                        END  

    --Update Live
	UPDATE Cust_FollowBet WITH(UPDLOCK, ROWLOCK)
	   SET rate = @Rate
		 , Rate2 = @Rate2
		 , Follow1 = @LiveHDP
		 , Follow3 = @LiveOU
		 , Follow5 = @Live1x2
		 , Follow7 = @Live1stHDP		 
		 , Follow8 = @Live1stOU
		 , Follow15 = @Live1st1x2
		 , Follower = @custFollower
		 , Odds = @LiveOdds
		 , Odds2 = @LiveOdds2
	 WHERE custid = @custid
	   AND FollowLive = 1
	   AND Follower = @custoriginalFollower

    --Update Non-Live
    UPDATE Cust_FollowBet WITH(UPDLOCK, ROWLOCK)
	   SET rate = @Rate
		 , Rate2 = @Rate2
		 , Follow1 = @NonLiveHDP		 
		 , Follow3 = @NonLiveOU
		 , Follow5 = @NonLive1x2
		 , Follow7 = @NonLive1stHDP
		 , Follow8 = @NonLive1stOU
		 , Follow15 = @NonLive1st1x2
		 , Follower = @custFollower
		 , Odds = @NonLiveOdds
		 , Odds2 = @NonLiveOdds2
	 WHERE custid = @custid
	   AND FollowLive = 0
	   AND Follower = @custoriginalFollower

	-- write log
	DECLARE @LogSPData VARCHAR(MAX)
		  , @TrackingValueDB VARCHAR(max)

	SELECT @LogSPData = '<Acc_AutoFollowBetUpdRate Username="' + COALESCE(@Username, SPACE(1)) + '" '
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
	                  + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'LiveOdds2="' + COALESCE(CAST(@LiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'NonLiveOdds2="' + COALESCE(CAST(@NonLiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'UserId="' + COALESCE(CAST(@UserId AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '
	                  + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

	SELECT @TrackingValueDB = '<Acc_AutoFollowBetUpdRate Username="' + COALESCE(@Username, SPACE(1)) + '" '
	                        + 'Rate="' + coalesce(cast(@oldRate AS VARCHAR(10)), space(1)) + '" '
	                        + 'Rate2="' + COALESCE(CAST(@oldRate2 AS VARCHAR(10)), SPACE(1)) + '" '
	                        + 'LiveHDP="' + COALESCE(CAST(@OldLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'Live1x2="' + COALESCE(CAST(@oldLive1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'LiveOU="' + COALESCE(CAST(@OldLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'Live1stHDP="' + COALESCE(CAST(@OldLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'Live1stOU="' + COALESCE(CAST(@OldLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'Live1st1x2="' + COALESCE(CAST(@oldLive1st1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLiveHDP="' + COALESCE(CAST(@OldNonLiveHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLiveOU="' + COALESCE(CAST(@OldNonLiveOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLive1x2="' + COALESCE(CAST(@oldNonLive1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLive1stHDP="' + COALESCE(CAST(@OldNonLive1stHDP AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLive1stOU="' + COALESCE(CAST(@OldNonLive1stOU AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'NonLive1st1x2="' + COALESCE(CAST(@NonLive1st1x2 AS VARCHAR(1)), SPACE(1)) + '" '
	                        + 'LiveOdds="' + COALESCE(CAST(@OldLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                        + 'NonLiveOdds="' + COALESCE(CAST(@OldNonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                        + 'NonLiveOdds2="' + COALESCE(CAST(@oldNonLiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
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
	                      + 'LiveOdds="' + COALESCE(CAST(@LiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'NonLiveOdds="' + COALESCE(CAST(@NonLiveOdds AS VARCHAR(30)), SPACE(1)) + '" '
	                      + 'LiveOdds2="' + COALESCE(CAST(@LiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
						  + 'NonLiveOdds2="' + COALESCE(CAST(@NonLiveOdds2 AS VARCHAR(30)), SPACE(1)) + '" '
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