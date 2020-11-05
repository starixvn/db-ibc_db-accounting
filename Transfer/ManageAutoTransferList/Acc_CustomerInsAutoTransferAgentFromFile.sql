/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [Acc_CustomerInsAutoTransferAgentFromFile]	
	@username		VARCHAR(MAX),
	@TransferType	TINYINT = 1,
	@UserID			INT,
	@IP				VARCHAR(50) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(4000)= 0 OUTPUT
AS

/*
	Created: Johnson
	Date: 2014-09-23
	Task: Manage auto transfer list agents adding from file
	DB: DBCUST/CustDB
		
	Revisions:
		- 20141023@Johnson: Set default transfer to 'Transfer all downlines' from upload file
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
	
	SELECT	@startRun = GETDATE()
	
	-- Check permission
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission
		@custid		= @userid
		,@funcname	= '[OtherTrans]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN
	-- End Check permission
	
	DECLARE @tmpUser TABLE (custid INT, username VARCHAR(50))
	DECLARE @tmpCust TABLE (custid INT, islog BIT)
	DECLARE @tmpResult TABLE (username VARCHAR(50), remark VARCHAR(100), isSuccess BIT)
	
	INSERT INTO @tmpUser(username)
	SELECT val
	FROM strSplit (@username, ',')
	
	-- Hardcode transfer type from file is 'Transfer all downlines'
	SET @TransferType = 2
	
	UPDATE t
	SET t.custid = c.custid
	FROM @tmpUser t
		LEFT JOIN customer c WITH(NOLOCK) ON t.username = c.username AND roleid > 1
	
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
		SELECT @ErrMsg = 'Add agent unsuccessfully', @ErrCode = 100
		RETURN
	END	
		 
	INSERT INTO @tmpResult(username,remark,isSuccess)
	SELECT username, 'Added successfully.',1
	FROM @tmpUser
	WHERE custid IN (SELECT custid FROM @tmpCust)

	-- if @username includes super and @transfertype is transfer all downline --> Update transfer option daily for supers and all downlines (except members)
	DECLARE @SuperIdXML XML, @SuperIdList VARCHAR(MAX)
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
		
		SELECT @LogData = '<Acc_CustomerInsAutoTransferAgentFromFile username="' + COALESCE(@log_username,SPACE(1)) + '" '
								+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																
		
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId			= @UserId
			,@CustId		= @CustId
			,@ActionID		= 652
			,@TrackingValue = @LogData		
			,@Duration		= @Duration
	END	
	
	SELECT * FROM @tmpResult
END
GO