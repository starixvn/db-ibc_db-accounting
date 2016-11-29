USE [bodb_CustomerLog]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog_ExternalAPI_Ins]    Script Date: 8/12/2016 2:20:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[WriteLog_UserLog_ExternalAPI_Ins]
	 @SystemID		SMALLINT
	,@ProductID		SMALLINT
	,@UserID		INT
	,@FuncName		VARCHAR(200)
	,@CustID		INT
	,@ActionID		INT
	,@TrackingValue	XML
	,@LogID			BIGINT = 0 OUTPUT -- Note: Not using @LogID VN cannot read 
AS
/*
Creator: 20160809@Jamie 
Task: Insert API calling statistic [RedmineID: #62306]
DB: DBLOG.BODB_CUSTOMERLOG

Revisions:

Param's Explanation:
	@SystemID: Sub-system id: Accounting 3, Agent 2, AgentWap 4, AgentIphone 5
	@UserID: Login user id, 
	@CustID: Customer id, 
	@ActionID: Action id (hashed from @FuncName), 
	@FuncName: Name of API, 
	@TrackingValue: API serialized parameters,
    @ReturnValue: Returned value of API
	@ReturnCode: Returned code of API: 1 failed, 0 succeeded.
*/

BEGIN 
	SET NOCOUNT ON

	INSERT INTO [dbo].[UserLog_ExternalAPI]
			   ([LogDate]
			   ,[SystemID]
			   ,[ProductID]
			   ,[UserID]
			   ,[FuncName]
			   ,[CustID]
			   ,[ActionID]
			   ,[TrackingValue]
			   ,[ModifiedDate]
			   ,[StatusID]
			   ,[isNotified]
			   ,[ReturnCode]
			   ,[ReturnValue])
				VALUES(
				CURRENT_TIMESTAMP
				,@SystemID
				,@ProductID
				,@UserID
				,@FuncName
				,@CustID
				,@ActionID
				,@TrackingValue
				,CURRENT_TIMESTAMP
				,0   --- 0: Waiting ; 1: Completed 
				,0	 --  0: Not notified yet 	
				,NULL
				,NULL
				)
	SELECT @LogID = SCOPE_IDENTITY() 
END 


GO
GRANT EXECUTE ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [bodbExtAccNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [bodbLicenseeNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [Dot_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [Dot_Member] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].WriteLog_UserLog_ExternalAPI_Ins TO [vnteam] AS [dbo]
GO