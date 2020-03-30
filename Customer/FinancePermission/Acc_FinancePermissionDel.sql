/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC Acc_FinancePermissionDel
	 @UserId INT,
	 @GroupId SMALLINT,
	 @Username NVARCHAR(50),
	 @Type SMALLINT = 0
AS
/*
    Created by: 20200325@Malcolm
	Task: Remove Finance User/ Finance Code from FinancePermission table [Redmine : #128128]
	DB : DBCUST/CustDB

	Revisions:
		- 20200325@Malcolm: Remove Finance User/ Finance Code from FinancePermission table [Redmine : #128128]
	Param's Explanation:
		- @Type = 0 : Finance code
		        = 1 : Finance User	
*/
BEGIN
    DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = 0, @ErrCode INT = 0 , @ErrMsg NVARCHAR(4000) = '' 
	SET @startRun = GETDATE();

    BEGIN TRY
		DELETE t
		FROM dbo.Acc_FinancePermission t 
		WHERE t.FinanceCode = @Username AND t.GroupId = @GroupId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE();
		RETURN;
	END CATCH

	SELECT @CustId = custid
	FROM  dbo.Customer WITH(NOLOCK)
	WHERE username = @Username

	SELECT @LogSPData = '<R GroupId="'+ COALESCE(CAST(@GroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
	                       'Username="'+ COALESCE(CAST(@Username AS VARCHAR(50)), SPACE(1)) + '" ' +
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
