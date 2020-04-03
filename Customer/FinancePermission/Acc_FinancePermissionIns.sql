/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.Acc_FinancePermissionIns
	 @UserId INT,
	 @GroupId SMALLINT,
	 @Username VARCHAR(30),
	 @IsView BIT = 0,
	 @Type SMALLINT = 0
	 	
AS
/*
    Created by: 20200325@Malcolm
	Task: Insert Admin/ Finance Code into FinancePermission table [Redmine : #128128]
	DB : DBCUST/CustDB

	Revisions:
		- 20200325@Malcolm: Insert Admin/ Finance Code into FinancePermission table [Redmine : #128128]
	Param's Explanation:
		- @Type   = 0 : Finance code
		          = 1 : Admin
	    - @IsView = 0 for Admine
*/
BEGIN
    DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = NULL, @ErrCode INT = 0, @ErrMsg NVARCHAR(4000) = '', @RoleId INT
	SET @startRun = GETDATE();

	SELECT @RoleId = roleid, @CustId = custid FROM Customer WITH(NOLOCK) WHERE username = @Username


    BEGIN TRY
		INSERT INTO dbo.Acc_FinancePermission(GroupId, FinanceCode, RoleId, IsView)
	    VALUES (@GroupId, @Username, @RoleId, @IsView)
	END TRY
	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE();
	END CATCH
	

	SELECT @LogSPData = '<R GroupId="'+ COALESCE(CAST(@GroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
	                       'Username="'+ COALESCE(CAST(@Username AS VARCHAR(30)), SPACE(1)) + '" ' +
						   'Type="'+ COALESCE(CAST(@Type AS VARCHAR(2)), SPACE(1)) + '" ' +
						   'RoleId="'+ COALESCE(CAST(@RoleId AS VARCHAR(4)), SPACE(1)) + '" ' +
						   'IsView="'+ COALESCE(CAST(@IsView AS VARCHAR(2)), SPACE(1)) + '" ' +
						   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
						   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)
	EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			        @UserID = @UserID,
				    @CustID = @CustId,
					@ActionID = 95003,
					@TrackingValue = @LogSPData,
					@duration = @duration
				
END
GO
