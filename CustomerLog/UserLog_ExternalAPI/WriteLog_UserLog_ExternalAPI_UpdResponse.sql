USE [bodb_CustomerLog]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse]    Script Date: 8/12/2016 2:21:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse]
	 @LogID			BIGINT  
    ,@ReturnValue	NVARCHAR(MAX)= ''
	,@ReturnCode	INT = 0 
AS
/*
Creator: 20160809@Jamie 
Task: Insert API calling statistic [RedmineID:#62306]
DB: DBLOG.BODB_CUSTOMERLOG

Revisions:

Param's Explanation:
    @ReturnValue: Returned value of API
	@ReturnCode: Returned code of API: <>0 failed, 0 succeeded.
*/

BEGIN 
	SET NOCOUNT ON
	SET ANSI_NULLS ON

	UPDATE [UserLog_ExternalAPI] WITH (UPDLOCK,ROWLOCK)
	SET	StatusID		= 1		-- Repond 
		,ModifiedDate	= CURRENT_TIMESTAMP
		,ReturnCode		= @ReturnCode
		,ReturnValue	= @ReturnValue
	WHERE	LogID = @LogID 

END 
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [bodbExtAccNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [Dot_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [Dot_Member] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse] TO [vnteam] AS [dbo]
GO