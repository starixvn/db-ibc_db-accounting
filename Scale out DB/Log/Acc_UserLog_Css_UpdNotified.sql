 
ALTER PROCEDURE [dbo].[Acc_UserLog_Css_UpdNotified]
(
	@LogID INT
)
AS
/*
	Created: 20120815@Lukas
	Task: mark is notified
	DB: bodb_CútomerLog
	
	Revisions:
	
	Param explanation:
	
*/
BEGIN
	SET NOCOUNT ON 
	
	UPDATE [dbo].[userLog_css] WITH(ROWLOCK,UPDLOCK)
	SET [IsNotified] = 1
	WHERE [LogID] = @LogID
	
END
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_Css_UpdNotified] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_Css_UpdNotified] TO [vnteam] AS [dbo]