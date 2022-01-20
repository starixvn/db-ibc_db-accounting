/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceGroupsConfig_FinanceGroup_GroupUpd]
	@NewGroupId		SMALLINT
	,@OldGroupId	SMALLINT
	,@UserID		INT
	,@IP			VARCHAR(50) = ''
	,@UserName      VARCHAR(50)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]
		
	Param's Explanation:
       
*/

BEGIN
	SET NOCOUNT ON

	IF @NewGroupId = @OldGroupId
		RETURN

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = NULL, @LogSPData2 NVARCHAR(MAX), @RoleId INT
	SET @startRun = GETDATE();
	
	SELECT @CustId = custid, @RoleId = roleid FROM dbo.Customer c WITH(NOLOCK) WHERE username = @UserName

	BEGIN TRY 
		IF @OldGroupId = -1
		BEGIN
			INSERT INTO dbo.Acc_FinancePermission (GroupId, FinanceCode, RoleId, IsView)
			VALUES (@NewGroupId, @UserName, @RoleId, 0)
		END
		ELSE IF @NewGroupId = -1
		BEGIN
			DELETE f WITH(ROWLOCK, UPDLOCK)
			FROM dbo.Acc_FinancePermission f 
			WHERE f.FinanceCode = @UserName AND f.RoleId >= 5
		END
		ELSE 
		BEGIN
			UPDATE f WITH(ROWLOCK)
				SET f.GroupId = @NewGroupId
			FROM dbo.Acc_FinancePermission f
			WHERE f.FinanceCode = @UserName AND f.RoleId >= 5
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = '' 
		RETURN
	END CATCH

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	SELECT @LogSPData = '<Acc_FinanceGroupsConfig_FinanceGroup_GroupUpd GroupId="'+ COALESCE(CAST(@NewGroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'CustId="'+ COALESCE(CAST(@CustId AS VARCHAR(20)), SPACE(1)) + '" ' +
							   'Username="'+ COALESCE(CAST(@Username AS VARCHAR(50)), SPACE(1)) + '" ' +		   
							   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'

	SELECT @LogSPData2 = '<Acc_FinanceGroupsConfig_FinanceGroup_GroupUpd GroupId="'+ COALESCE(CAST(@OldGroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'CustId="'+ COALESCE(CAST(@CustId AS VARCHAR(20)), SPACE(1)) + '" ' +
							   'Username="'+ COALESCE(CAST(@Username AS VARCHAR(50)), SPACE(1)) + '" ' +		   
							   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'
		
	EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				 @UserID = @UserID, 
				 @CustID = @CustId,
				 @ActionID = 95004,
				 @TrackingValue = @LogSPData,
				 @TrackingValue2 = @LogSPData2,
				 @duration = @duration
END
GO
