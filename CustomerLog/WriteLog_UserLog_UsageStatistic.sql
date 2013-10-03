ALTER PROCEDURE [dbo].[WriteLog_UserLog_UsageStatistic]
	@CustID INT,
	@RoleID TINYINT,
	@ActionID INT,
	@ServerID TINYINT,
	@Device NVARCHAR(100)=''
AS
/*
	Created: 20131002@Elodie
	Task : Write log to record usage statistic for the update functions
	DB: DBLOG/bodb_CustomerLog
	Original:
	
	Revisions :
	
*/
BEGIN
	SET NOCOUNT ON
	INSERT INTO  dbo.UserLog_UsageStatistic (CustID, RoleID, ActionID, LogDate, ServerID, Device)			
	VALUES (@CustID, @RoleID, @ActionID, getdate(), @ServerID, @Device)
			
END

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_UsageStatistic] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_UsageStatistic] TO [vnteam] AS [dbo] 