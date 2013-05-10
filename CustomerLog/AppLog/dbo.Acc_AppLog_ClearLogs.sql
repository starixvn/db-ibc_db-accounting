ALTER PROCEDURE [dbo].[Acc_AppLog_ClearLogs]
AS
/*	Created by: Lewin
	Date: 2010-07-08
	Task: Insert categorylog
	DB: LOG.bodb_CustomerLog 

*/
BEGIN
	SET NOCOUNT ON;

	DELETE FROM AppLog_CategoryLog WITH (UPDLOCK,ROWLOCK)
	DELETE FROM AppLog_Log WITH (UPDLOCK,ROWLOCK)
    DELETE FROM AppLog_Category WITH (UPDLOCK,ROWLOCK)
END

GO
GRANT EXECUTE ON [dbo].[Acc_AppLog_ClearLogs] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AppLog_ClearLogs] TO [vnteam]