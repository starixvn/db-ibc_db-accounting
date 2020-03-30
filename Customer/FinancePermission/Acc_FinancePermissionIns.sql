/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.Acc_FinancePermissionIns
	 @UserId INT,
	 @GroupId SMALLINT,
	 @Username NVARCHAR(50),
	 @RoleId INT,
	 @IsView BIT = 0,
	 @Type SMALLINT = 0
	 	
AS
/*
    Created by: 20200325@Malcolm
	Task: Insert Finance User/ Finance Code into FinancePermission table [Redmine : #128128]
	DB : DBCUST/CustDB

	Revisions:
		- 20200325@Malcolm: Insert Finance User/ Finance Code into FinancePermission table [Redmine : #128128]
	Param's Explanation:
		- @Type   = 0 : Finance code
		          = 1 : Finance User	
	    - @IsView = 0 for Finance User
*/
BEGIN
    DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = 0, @ErrCode INT = 0, @ErrMsg NVARCHAR(4000) = '' 
	SET @startRun = GETDATE();

    BEGIN TRY
		INSERT INTO dbo.Acc_FinancePermission(GroupId, FinanceCode, RoleId, IsView)
	    VALUES (@GroupId, @Username, @RoleId, @IsView)
	END TRY
	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE();
	END CATCH
	
	SELECT @CustId = custid
	FROM  dbo.Customer WITH(NOLOCK)
	WHERE username = @Username

	SELECT @LogSPData = '<R GroupId="'+ COALESCE(CAST(@GroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
	                       'Username="'+ COALESCE(CAST(@Username AS VARCHAR(50)), SPACE(1)) + '" ' +
						   'Type="'+ COALESCE(CAST(@Type AS VARCHAR(2)), SPACE(1)) + '" ' +
						   'RoleId="'+ COALESCE(CAST(@RoleId AS VARCHAR(4)), SPACE(1)) + '" ' +
						   'IsView="'+ COALESCE(CAST(@IsView AS VARCHAR(2)), SPACE(1)) + '" ' +
						   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
						   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)
	EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper 
				 @UserID = @UserID, 
				 @CustID = @CustId,
				 @ActionID = 95003,
			     @TrackingValue = @LogSPData,
				 @duration = @duration
END
