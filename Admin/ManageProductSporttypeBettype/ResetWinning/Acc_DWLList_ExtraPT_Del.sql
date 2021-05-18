/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_DWLList_ExtraPT_Del
	@CustID      INT,
	@ErrCode     INT = 0 OUTPUT,
	@ErrMsg      NVARCHAR(MAX) = '' OUTPUT,
	@UserID      INT,
	@LoginIP     VARCHAR(20) = '',
	@IsTest		 BIT
AS

/*
Created: 20200917@Danny
Task :  NAP Manage Reset Winning
DB: DBACC/bodb_ACC -> DBCUST.CustDB
Original:

	Revisions:
		- 20200917@Danny: NAP Manage Reset Winning [Redmine: #131241][Task: #141775]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
	Param's Explanation:
	
		
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE @startRun DATETIME = GETDATE(), @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX)

	BEGIN TRY
		IF @IsTest = 0
		BEGIN
			DELETE m
			FROM dbo.Acc_DWLList_ExtraPT m WITH (ROWLOCK)
			WHERE m.CustID = @CustID
		END
		
		IF @IsTest = 1
		BEGIN
			DELETE m
			FROM dbo.Acc_DWLList_ExtraPT_xtest m WITH (ROWLOCK)
			WHERE m.CustID = @CustID
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

    SELECT @LogSPData = (SELECT @CustID AS '@CustID', @LoginIP AS '@LoginIP', @IsTest AS '@IsTest' FOR XML PATH('R'))

	SET @endRun = GETDATE()
    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@ActionID = 95037,
			@TrackingValue = @LogSPData,
			@duration = @duration
	
END

