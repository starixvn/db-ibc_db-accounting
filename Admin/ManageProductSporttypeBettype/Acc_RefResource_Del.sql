/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_RefResource_Del
	@RefId          VARCHAR(20),
	@ResourceId     VARCHAR(20),	
	@ErrCode     INT = 0 OUTPUT,
	@ErrMsg      NVARCHAR(MAX) = '' OUTPUT,
	@UserID      INT,
	@LoginIP     VARCHAR(20) = ''
AS

/*
Created: 20200703@Malcolm
Task :  NAP-Manage RefResource
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200703@Malcolm: NAP-Manage RefResource [Redmine: #131241]
		
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE @startRun DATETIME = GETDATE(), @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX)

	BEGIN TRY
		DELETE m
		FROM dbo.RefResource m
		WHERE m.RefId = @RefId AND m.ResourceId =  @ResourceId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

    SELECT @LogSPData = (SELECT @RefId AS '@RefId', @ResourceId AS '@ResourceId', @LoginIP AS '@LoginIP' FOR XML PATH('R'))

	SET @endRun = GETDATE()
    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@ActionID = 95030,
			@TrackingValue = @LogSPData,
			@duration = @duration
	
END

