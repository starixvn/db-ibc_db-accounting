USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AutoFollowBetInsBACustomer]    Script Date: 03/25/2015 09:33:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetInsBACustomer]
    @strCustID  VARCHAR(MAX)
	,@UserID    INT				= 0
	,@IP        NVARCHAR(50)	= ''
	,@rate      SMALLMONEY
	,@Follower  VARCHAR(30)
	,@totalRows INT				= 0 OUTPUT
	,@ErrCode   INT				= 0 OUTPUT
	,@ErrMsg    VARCHAR(1000)	= '' OUTPUT
AS
/*  Created: Henry  
	Date: 2012-07-06
    Task : Insert BA Customers to Cust_FollowBet
    DB: DBTXN/bodb02  
   
    Revisions:  
        - 20130201@Daniel: Change link server alias & failover writelog to DBTXN  
		- 20140106@Kathy: Add new param: @Follower [Redmine:#9144]
		- 20140428@Kathy: Down minimum rate from 0.3 to 0.01 [Redmine:#15495]
		- 20140805@Logan:   1. Separate live and non-live setting [Redmine: #16578]
		                    2. Do not allow user to follow himself
		- 20150120@Kathy: Update Original and Nonlive danger level of BA member to 2 [Redmine:#29459]
		- 20150324@Kathy: Support 2 more bettype 1x2 & 1st 1x2 [Redmine:#30394]  
		
	Param's Explanation:  
	 
	  
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @startRun			DATETIME
			,@endRun			DATETIME
			,@duration			INT
			,@oldDanger			VARCHAR(100)
			,@oldDanger2		VARCHAR(100)
			,@LogSPData			VARCHAR(5000)
			,@TrackingValueDB	VARCHAR(max)
			,@custFollower		INT

	SET @startRun = GETDATE()

	CREATE TABLE #TempCustID(CustID INT)

	--INSERT INTO #TempCustID(CustID)
	--SELECT c.CustID
	--FROM dbo.custInfo c WITH(NOLOCK)
	--INNER JOIN DBLIC.bodb_licensee.dbo.LicenseeBAHistory lba WITH(NOLOCK) ON c.custid = lba.custid
	--WHERE c.CustID IN (SELECT RTRIM(LTRIM(VAL))
	--		              FROM strSplit(@strCustID, ',')
	--		           )
	--AND lba.status = 'running'

	INSERT INTO #TempCustID(CustID)
	SELECT c.custid
	FROM dbo.custInfo c WITH(NOLOCK)
	INNER JOIN dbo.Dep_CustBAActive d WITH(NOLOCK) ON d.CustId = c.custid
	WHERE c.custid IN (SELECT RTRIM(LTRIM(val)) FROM dbo.strSplit(@strCustId,','))	
	
	SELECT @custFollower = c.custid
	  FROM custInfo c WITH(NOLOCK)
	 WHERE c.username = @Follower
	   AND c.roleid = 1

	IF @@Rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid follower, please try again!'
			 , @ErrCode = 101

		RETURN
	END
	
	--Do not allow member to follow himself
	SELECT 1
	  FROM #TempCustID
	 WHERE CustID = @custFollower

    IF @@Rowcount <> 0
	BEGIN
		SELECT @ErrMsg = 'User and follower are identical, please try again!'
			 , @ErrCode = 106

		RETURN
	END

	-- Rate must range between 0.01 and 3, 2 decimal digits
	IF @Rate NOT BETWEEN 0.01 AND 3 
	   OR (CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 2)) <> CONVERT(FLOAT, CONVERT(NVARCHAR, @Rate, 1)))
	BEGIN
		SELECT @ErrMsg = 'Invalid rate! Rate must range between 0.01 and 3'
			 , @ErrCode = 103

		RETURN
	END

    --Live setting
	INSERT INTO Cust_FollowBet
	(
	    custid
	  , rate
	  , Rate2
	  , FollowLive
	  , Follower
	)
	SELECT c.CustID
		 , @rate
		 , @rate
		 , 1
		 , @custFollower
	  FROM #TempCustID c
     WHERE NOT EXISTS (SELECT 1
                         FROM Cust_FollowBet WITH(NOLOCK)
                        WHERE custid = c.CustID
                      )

    SELECT @totalRows = @@ROWCOUNT

	IF @totalRows = 0
	BEGIN
		SELECT @ErrCode = 100
			 , @ErrMsg = 'Nothing was inserted, please check again!'
	END
	 
	--Non-Live setting
	INSERT INTO Cust_FollowBet
	(
	    custid
	  , rate
	  , Rate2
	  , FollowLive
	  , Follower
	)
	SELECT c.CustID
		 , @rate
		 , @rate
		 , 0
		 , @custFollower
	  FROM #TempCustID c
	LEFT JOIN Cust_FollowBet cf WITH(NOLOCK) ON c.custid = cf.custid
     WHERE NOT EXISTS (SELECT 1
                         FROM Cust_FollowBet WITH(NOLOCK)
                        WHERE custid = c.CustID
                          AND FollowLive = 0
                      )
	
	SELECT @totalRows = @@ROWCOUNT

	IF @totalRows = 0
	BEGIN
		SELECT @ErrCode = 100
			 , @ErrMsg = 'Nothing was inserted, please check again!'
	END
	
	SELECT @oldDanger = COALESCE(@oldDanger, '') + CAST(ci.danger AS VARCHAR(10)) + ','
			,@oldDanger2 = COALESCE(@oldDanger2, '') + CAST(ci.danger2 AS VARCHAR(10)) + ','
	FROM dbo.custInfo ci WITH(NOLOCK)
	INNER JOIN #TempCustID t ON t.CustID = ci.custid
	WHERE t.CustID IN (SELECT custid FROM dbo.Cust_FollowBet WITH(NOLOCK))
	
	UPDATE ci WITH(ROWLOCK, UPDLOCK)
	SET danger = 2
		,danger2 = 2
	FROM dbo.custInfo ci	
	INNER JOIN #TempCustID t ON t.CustID = ci.custid
	WHERE ci.custid IN (SELECT custid FROM dbo.Cust_FollowBet WITH(NOLOCK))
	
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	SELECT @LogSPData = '<Acc_AutoFollowBetInsBACustomer CustID="' + COALESCE(CAST(@strCustID AS VARCHAR(MAX)), SPACE(1)) + '" '
	                  + 'rate="' + COALESCE(CAST(@rate AS VARCHAR(40)), SPACE(1)) + '" '
	                  + 'Follower="' + COALESCE(CAST(@Follower AS VARCHAR(30)), SPACE(1)) + '" '
	                  + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(40)), SPACE(1)) + '" '
	                  + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" '
	                  + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(5000)), SPACE(1)) + '" />'
	
	SELECT @TrackingValueDB = '<Acc_AutoFollowBetInsBACustomer Danger="' + COALESCE(CAST(@oldDanger AS VARCHAR(100)), SPACE(1)) + '" '	          
	                        + 'Danger2="' + COALESCE(CAST(@oldDanger2 AS VARCHAR(100)), SPACE(1)) + '" />'
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
		    ,@CustID = 0
			,@ActionID = 635
			,@TrackingValue = @LogSPData
			,@TrackingValue2 = @TrackingValueDB
			,@duration = @duration
	END TRY

	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
			,@CustID = 0
			,@ActionID = 635
			,@TrackingValue = @LogSPData
			,@TrackingValue2 = @TrackingValueDB
			,@duration = @duration
	END CATCH
END



GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetInsBACustomer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetInsBACustomer] TO [vnteam] AS [dbo]