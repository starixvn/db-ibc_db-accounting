/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Acc_CustomerUpdAutoTransferAgent]
	@custid			INT,
	@TransferType	TINYINT = 1,
	@userID			INT,
	@IP				VARCHAR(30) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(500) = '' OUTPUT
AS
/*
	Created: Johnson
	Date: 2014-09-25
	Task: Update transfer type for agent
	DB: DBCUST/CustDB
	
	Revisions:
		- 20170703@Percy: Add space bar into log content [RedmineID: #79293]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20190409@Percy: Check super is in automate transfer list [RedmineID: #111365]
	
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
	
	IF NOT EXISTS(SELECT 1 FROM Acc_ClearBalanceList WITH(NOLOCK) WHERE custid = @custid)
	BEGIN
		SELECT @ErrMsg = 'This agent doesn''t exist in the automate transfer list.', @ErrCode = 100
		RETURN
	END
	
	-- Check data change
	DECLARE @Old_transferType TINYINT
	SELECT  @Old_transferType = TransferType FROM Acc_ClearBalanceList WITH(NOLOCK) WHERE custid = @custid
	
	IF @Old_TransferType = @TransferType
		RETURN
	-- End Check data change
	
	UPDATE Acc_ClearBalanceList WITH(UPDLOCK,ROWLOCK)
	SET TransferType = @TransferType
	WHERE custid = @custid
	
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = 'Update agent unsuccessfully.', @ErrCode = 101
		RETURN
	END

	-- if @custid is super and @transfertype is transfer all downline --> Update transfer option daily for this super and all downlines (except members)
	DECLARE @roleid TINYINT
	SELECT  @roleid = roleid FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @custid

	DECLARE @SuperIdXML XML, @SuperIdList VARCHAR(MAX)

	IF @roleid = 4 AND @TransferType = 2
	BEGIN
		SELECT @SuperIdXML = (SELECT @custid AS '@c' FOR XML PATH('r'), TYPE)
		
		SELECT @SuperIdList = CAST(@SuperIdXML AS VARCHAR(MAX))
		
		IF ISNULL(@SuperIdList, '') <> ''
		BEGIN
			EXEC dbo.Acc_CustomerInfo_Execrep_08
				@SuperIdList		= @SuperIdList
				,@TransferOption	= 0 -- Daily
		END
	END
	-- End update transfer option
	
	-- Write log
	DECLARE @LogData		VARCHAR(4000),
			@LogData_Old	VARCHAR(4000)
			
	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)
		
	SELECT @LogData = '<Acc_CustomerUpdAutoTransferAgent CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
	
	SELECT @LogData_Old = '<Acc_CustomerUpdAutoTransferAgent CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'TransferType="' + COALESCE(CAST(@Old_TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
		
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId			= @UserId,
		@CustId			= @CustId,
		@ActionId		= 654,
		@TrackingValue	= @LogData,
		@TrackingValue2 = @LogData_Old,
		@Duration		= @Duration
END
GO