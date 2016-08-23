USE [bodb_CustomerLog]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse]    Script Date: 8/12/2016 2:21:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse]
	 @LogID			BIGINT  
    ,@ReturnValue	VARCHAR(MAX)= ''
	,@ReturnCode	INT = 0 
AS
/*
Creator: 20160809@Jamie 
Task: Insert API calling statistic
DB: DBLOG.BODB_CUSTOMERLOG

Revisions:

Param's Explanation:
    @ReturnValue: Returned value of API
	@ReturnCode: Returned code of API: <>0 failed, 0 succeeded.
*/

BEGIN 
	SET NOCOUNT ON

	UPDATE [UserLog_ExternalAPI] WITH (UPDLOCK,ROWLOCK)
	SET	StatusID		= 1		-- Repond 
		,ModifiedDate	= CURRENT_TIMESTAMP
		,ReturnCode		= @ReturnCode
		,ReturnValue	= @ReturnValue
	WHERE	LogID = @LogID 

END 
