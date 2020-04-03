/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC Acc_FinancePermissionDel
	 @UserId INT,
	 @GroupId SMALLINT,
	 @Username NVARCHAR(50),
	 @Type SMALLINT = 0
AS
/*
    Created by: 20200325@Malcolm
	Task: Remove Admin / Finance Code from FinancePermission table [Redmine : #128128]
	DB : DBCUST/CustDB

	Revisions:
		- 20200325@Malcolm: Remove Admin / Finance Code from FinancePermission table [Redmine : #128128]
	Param's Explanation:
		- @Type = 0 : Finance code
		        = 1 : Admin
*/
BEGIN
    DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = NULL, @ErrCode INT = 0 , @ErrMsg NVARCHAR(4000) = '',@IsView BIT, @RoleId INT
	SET @startRun = GETDATE();
     
	SELECT @CustId = custid FROM  dbo.Customer WITH(NOLOCK) WHERE username = @Username
	
	SELECT @IsView = IsView, @RoleId = RoleId 
	FROM dbo.Acc_FinancePermission 
	WHERE FinanceCode = @Username AND GroupId = @GroupId

	IF @CustId IS NULL
	BEGIN
	    SELECT @ErrMsg = 'username is uncorrect'
		RETURN
	END 
    BEGIN TRY
		DELETE t
		OUTPUT deleted.IsView
		FROM dbo.Acc_FinancePermission t 
		WHERE t.FinanceCode = @Username AND t.GroupId = @GroupId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE();
		RETURN;
	END CATCH

	

	SELECT @LogSPData = '<R GroupId="'+ COALESCE(CAST(@GroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
	                       'Username="'+ COALESCE(CAST(@Username AS VARCHAR(50)), SPACE(1)) + '" ' +
						   'RoleId="'+ COALESCE(CAST(@RoleId AS VARCHAR(5)), SPACE(1)) + '" ' +
						   'IsView="'+ COALESCE(CAST(@IsView AS VARCHAR(2)), SPACE(1)) + '" ' +
						   'Type="'+ COALESCE(CAST(@Type AS VARCHAR(2)), SPACE(1)) + '" ' +						   
						   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
						   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)
	EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				 @UserID = @UserID, 
				 @CustID = @CustId,
				 @ActionID = 95004,
			     @TrackingValue = @LogSPData,
				 @duration = @duration
END
GO
