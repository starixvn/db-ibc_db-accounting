/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerInsAutoTransferAgent]
	@username		VARCHAR(MAX),
	@TransferType	TINYINT = 1,
	@UserID			INT,
	@IP				VARCHAR(50) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(4000)= 0 OUTPUT
AS

/*
	Created: Johnson
	Date: 2014-09-30
	Task: Add manually agents into automate	transfer list
	DB: DBCUST/CustDB
	
	Revisions:
		- 20150406@Johnson: fix log format [Redmine: #25321]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20190409@Percy: Set transfer option to daily if super is in automate transfer list [RedmineID: #111365]

	Parameter's Explanation:
		- @TransferType = 1: Transfer all members
						= 2: Transfer all downlines
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	
	SELECT  @startRun = GETDATE()
	
	-- Check permission
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission
		@custid		= @userid
		,@funcname	= '[OtherTrans]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN
	-- End Check permission
	
	DECLARE @tmpUser TABLE (custid INT, username VARCHAR(50), roleid TINYINT, srecommend INT)
	DECLARE @tmpCust TABLE (custid INT, islog BIT)
	DECLARE @ErrType VARCHAR(4000)
	
	INSERT INTO @tmpUser(username)
	SELECT DISTINCT val
	FROM strSplit (@username, ',')
	
	UPDATE t
	SET t.custid = c.custid, t.roleid = c.roleid, t.srecommend = c.srecommend
	FROM @tmpUser t
		LEFT JOIN dbo.Customer c WITH(NOLOCK) ON t.username = c.username AND c.roleid > 1
	
	IF EXISTS (SELECT 1 FROM @tmpUser WHERE custid IS NULL)
	BEGIN		
		SELECT @ErrType = NULL
		SELECT @ErrType = COALESCE(@ErrType + ',', '') + username
		FROM @tmpUser
		WHERE custid IS NULL
		
		SELECT @ErrMsg = 'Invalid Username: ' + @ErrType, @ErrCode = 100
		RETURN
	END
	
	IF EXISTS (
		SELECT 1
		FROM @tmpUser t
			INNER JOIN [dbo].[Acc_ClearBalanceList] ac WITH(NOLOCK) ON t.custid = ac.custid
	)
	BEGIN
		SELECT @ErrType = NULL
		SELECT @ErrType = COALESCE(@ErrType + ',', '') + t.username
		FROM @tmpUser t
			INNER JOIN [dbo].[Acc_ClearBalanceList] ac WITH(NOLOCK) ON t.custid = ac.custid
				
		SELECT @ErrMsg = 'Existing Username: ' + @ErrType, @ErrCode = 101
		RETURN
	END

	IF EXISTS (
		SELECT 1
		FROM @tmpUser t
			INNER JOIN [dbo].[Acc_ClearBalanceList] ac WITH(NOLOCK) ON t.srecommend = ac.custid
		WHERE t.roleid IN (2, 3)
	)
	BEGIN
		SELECT @ErrMsg = 'Super already exists on Automate Transfer list, you cannot add donwlines to this list.', @ErrCode = 102
		RETURN
	END

	IF EXISTS (
		SELECT 1
		FROM @tmpUser t
			INNER JOIN [dbo].[Customer] c WITH (NOLOCK) ON t.custid = c.srecommend AND t.roleid = 4 AND c.roleid IN (2,3)
			INNER JOIN [dbo].[Acc_ClearBalanceList] ac WITH(NOLOCK) ON c.custid = ac.custid
	)
	BEGIN
		SELECT @ErrType = NULL
		SELECT @ErrType = COALESCE(@ErrType + ',', '') + c.username
		FROM @tmpUser t
			INNER JOIN [dbo].[Customer] c WITH (NOLOCK) ON t.custid = c.srecommend AND t.roleid = 4 AND c.roleid IN (2,3)
			INNER JOIN [dbo].[Acc_ClearBalanceList] ac WITH(NOLOCK) ON c.custid = ac.custid

		SELECT @ErrMsg = 'Please remove all donwlines: ' + @ErrType + ' before you add this Super to Automate Transfer list.', @ErrCode = 103
		RETURN
	END
	
	INSERT INTO [dbo].[Acc_ClearBalanceList]
           ([custid] 
           ,[status]
           ,[LastTransfer]           
           ,[transferType])
    OUTPUT INSERTED.custid, 0 INTO @tmpCust    
	SELECT t.custid,'', GETDATE()-1, @TransferType
	FROM @tmpUser t
		LEFT JOIN Acc_ClearBalanceList ac WITH(NOLOCK) ON t.custid = ac.custid
	WHERE t.custid IS NOT NULL
		AND ac.custid IS NULL
	
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = 'Add agent unsuccessfully', @ErrCode = 110
		RETURN
	END

	-- if @username includes super and @transfertype is transfer all downline --> Update transfer option daily for supers and all downlines (except members)
	DECLARE @SuperIdXML XML, @SuperIdList VARCHAR(MAX)
	
	IF @TransferType = 2
	BEGIN
		SELECT  @SuperIdXML =
							(SELECT tc.custid AS '@c'
							FROM @tmpCust tc
								INNER JOIN dbo.Customer c WITH (NOLOCK) ON tc.custid = c.custid
							WHERE c.roleid = 4
							FOR XML PATH('r'), TYPE)

		SELECT  @SuperIdList = CAST(@SuperIdXML AS VARCHAR(MAX))
	
		IF ISNULL(@SuperIdList, '') <> ''
		BEGIN
			EXEC dbo.Acc_CustomerInfo_Execrep_08
				@SuperIdList		= @SuperIdList
				,@TransferOption	= 0 -- Daily
		END
	END
	
	--write log
	DECLARE @LogData VARCHAR(4000),	
			@custid INT,			
			@log_username varchar(50)
			
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)	
	
	WHILE (1=1)
	BEGIN
		UPDATE TOP (1) t
		SET @log_username = username,
			@custid = t.custid,
			islog = 1
		FROM @tmpCust t
			INNER JOIN @tmpUser u ON t.custid = u.custid
		WHERE islog = 0
		
		IF @@ROWCOUNT = 0 BREAK;

		SELECT @LogData = '<Acc_CustomerInsAutoTransferAgent username="' + COALESCE(@log_username,SPACE(1)) + '" ' 
								+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@Userid			= @userid
			,@Custid		= @CustID
			,@ActionID		= 653
			,@TrackingValue	= @LogData
			,@Duration		= @duration
	END	
END
GO