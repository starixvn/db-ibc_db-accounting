

ALTER PROCEDURE [dbo].[Acc_UserLog_CSSCheckFail] 
(
	@delay INT = 300
)
AS
/*
	Created: 20120815@Lukas
	Task: Get failed actions and notify	
	DB:
	
	Revisions:
	
	Param explanation:
		@delay: delay time before send notification (in second)
*/
BEGIN
	SELECT	LogID, userID, matchid, dbServer, actiontype, logdate, status, errorMessage,
			TrackingValue, IP, ProcessName
	FROM [userLog_css] WITH(NOLOCK)
	WHERE [status] IN ('Fail','Exception') AND IsNotified = 0
		AND logdate <= DATEADD(ss,-@delay,GETDATE())
END

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CSSCheckFail] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_CSSCheckFail] TO [vnteam] AS [dbo]