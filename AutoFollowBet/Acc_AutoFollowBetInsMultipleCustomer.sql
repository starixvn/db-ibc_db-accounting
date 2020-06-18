/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetInsMultipleCustomer] 
	@strUsername    VARCHAR(MAX)
    ,@Rate          SMALLMONEY
    ,@Rate2			SMALLMONEY
    ,@LiveOdds      SMALLMONEY
    ,@NonLiveOdds   SMALLMONEY
    ,@LiveOdds2     SMALLMONEY
    ,@NonLiveOdds2  SMALLMONEY
    ,@LiveHDP       BIT
    ,@NonLiveHDP    BIT
    ,@LiveOU        BIT
    ,@NonLiveOU     BIT
    ,@Live1x2       BIT
    ,@NonLive1x2    BIT
    ,@Live1stHDP    BIT
    ,@NonLive1stHDP BIT    
    ,@Live1stOU     BIT
    ,@NonLive1stOU  BIT
    ,@Live1st1x2    BIT
    ,@NonLive1st1x2 BIT
    ,@Follower      VARCHAR(30)
    ,@UserId        INT
    ,@IP            VARCHAR(50)
    ,@ErrCode       VARCHAR(100)	= ''	OUTPUT
    ,@ErrMsg        NVARCHAR(MAX)	= ''	OUTPUT
AS

/*
	Created: 20141230@Kathy
	DB: DBCUST-CustDB
	Task: Insert muliple customer
	
	Revisions:
		- 20150323@Kathy: Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]  
		
	Param's Explanation:
		*@strUsername: list of username	
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @SubErrMsg			VARCHAR(200)
			,@SubErrCode		INT
			,@custFollower		INT
			,@recommendFollower INT
			,@username			NVARCHAR(50)
			,@rowid				INT
	
	DECLARE @tblCust TABLE (rowid int IDENTITY(1,1), username NVARCHAR(50))
	
	SELECT @custFollower		= c.custid
			,@recommendFollower = c.recommend
	FROM custInfo c WITH(NOLOCK)
	WHERE c.username = @Follower
	AND roleid     = 1  
	
	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg	= 'Invalid follower, please try again!'
			 , @ErrCode = 101

		RETURN
	END	
	
	--Not follow any bettype
	IF @LiveHDP	= 0
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
			 , @ErrCode = 102

		RETURN
	END	    
	
	-- Rate must range between 0.01 and 3
	IF @Rate NOT BETWEEN 0.01 AND 3
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for O/U and HDP group! Rate must range between 0.01 and 3'
			 , @ErrCode = 103

		RETURN
	END
	
	IF @Rate2 NOT BETWEEN 0.01 AND 3 
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for 1x2 Group! Rate must range between 0.01 and 3'
			 , @ErrCode = 103

		RETURN
	END
	
	-- Don't allow to save rate with 3 decimal digits
	IF CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 2)) <> CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 1))
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for O/U and HDP group! Don''t enter the number with more than 2 decimal places.'
			 , @ErrCode = 104

		RETURN
	END
	
	IF (CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate2, 2)) <> CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate2, 1)))
	BEGIN
		SELECT @ErrMsg = 'Invalid rate for 1x2 Group! Don''t enter the number with more than 2 decimal places.'
			 , @ErrCode = 104

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
			 , @ErrCode = 105

		RETURN
	END 
	
	INSERT INTO @tblCust(username)
	SELECT s.val
	FROM dbo.strSplit(@strUsername, ',') s
	
	WHILE (1 = 1)
	BEGIN
		SELECT TOP 1 @username = username
					,@rowid = rowid
		FROM @tblCust
		ORDER BY rowid
		
		IF @@rowcount = 0
			BREAK
					
		BEGIN TRY
			SELECT @SubErrCode = 0
				,@SubErrMsg = ''
				
			EXEC dbo.Acc_AutoFollowBetInsCustomer
					@Username    	= @username
					,@Rate       	= @Rate 
					,@Rate2       	= @Rate2 
					,@LiveOdds   	= @LiveOdds  
					,@NonLiveOdds   = @NonLiveOdds 
					,@LiveOdds2   	= @LiveOdds2  
					,@NonLiveOdds2  = @NonLiveOdds2 
					,@LiveHDP		= @LiveHDP      
					,@NonLiveHDP	= @NonLiveHDP   
					,@LiveOU		= @LiveOU       
					,@NonLiveOU		= @NonLiveOU  
					,@Live1x2		= @Live1x2   
					,@NonLive1x2	= @NonLive1x2  
					,@Live1stHDP	= @Live1stHDP   
					,@NonLive1stHDP	= @NonLive1stHDP
					,@Live1stOU		= @Live1stOU    
					,@NonLive1stOU	= @NonLive1stOU 
					,@Live1st1x2	= @Live1st1x2  
					,@NonLive1st1x2	= @NonLive1st1x2
					,@Follower		= @Follower     
					,@UserId		= @UserId       
					,@IP			= @IP           
					,@ErrCode		= @SubErrCode      OUTPUT
					,@ErrMsg		= @SubErrMsg       OUTPUT
					
			SELECT @ErrCode = ISNULL(@ErrCode,'') + CONVERT(VARCHAR(3),ISNULL(@SubErrCode,0)) + ';'
					,@ErrMsg = ISNULL(@ErrMsg,'') + ISNULL(@SubErrMsg,'') + ';'
					
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = ISNULL(@ErrCode,'') + CONVERT(VARCHAR(3),ISNULL(@SubErrCode,0)) + ';'
					,@ErrMsg = ISNULL(@ErrMsg,'') + ISNULL(@SubErrMsg,'') + ';'
		END CATCH
				
		DELETE FROM @tblCust WHERE username = @username AND rowid = @rowid
	END
	
	SELECT @ErrCode = LEFT(@ErrCode,LEN(@ErrCode) - 1)
		,@ErrMsg = LEFT(@ErrMsg, LEN(@ErrMsg) - 1)
END
GO