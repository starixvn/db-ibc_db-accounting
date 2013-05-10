ALTER PROCEDURE [dbo].[WriteLog_AppLog]
(
	@EventID int, 
	@Priority int, 
	@Severity nvarchar(32), 
	@Title nvarchar(256), 
	@Timestamp datetime,
	@MachineName nvarchar(32), 
	@AppDomainName nvarchar(512),
	@ProcessID nvarchar(256),
	@ProcessName nvarchar(512),
	@ThreadName nvarchar(512),
	@Win32ThreadId nvarchar(128),
	@Message nvarchar(4000),
	@FormattedMessage ntext,
	@LogId int OUTPUT
)
AS 
/*	Created by: Lewin
	Date: 2010-07-08
	Task: Insert categorylog
	DB: LOG.bodb_CustomerLog 
	
	Revisions:
		- 20100806@Jamie:Edit the size of the param @Message 

*/
BEGIN
	SET NOCOUNT ON 
	INSERT INTO [AppLog_Log] (
		EventID,
		Priority,
		Severity,
		Title,
		[Timestamp],
		MachineName,
		AppDomainName,
		ProcessID,
		ProcessName,
		ThreadName,
		Win32ThreadId,
		Message,
		FormattedMessage
	)
	VALUES (
		@EventID, 
		@Priority, 
		@Severity, 
		@Title, 
		@Timestamp,
		@MachineName, 
		@AppDomainName,
		@ProcessID,
		@ProcessName,
		@ThreadName,
		@Win32ThreadId,
		@Message,
		@FormattedMessage)

	SET @LogID = @@IDENTITY
	RETURN @LogID
END 

GO
GRANT EXECUTE ON [dbo].[WriteLog_AppLog] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_AppLog] TO [vnteam]