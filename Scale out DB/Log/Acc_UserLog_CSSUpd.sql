 

ALTER procedure [dbo].[Acc_UserLog_CSSUpd]
(
	@userID int  
   ,@matchid int
   ,@dbServer varchar(50)
   ,@actiontype varchar(100)   
   ,@status varchar(20)
   ,@errorMessage varchar(500)
   ,@TrackingValue varchar(1000)
   ,@IP varchar(20)
   ,@ProcessName varchar(50)
)
AS
/*
	Created: 20120814@Lukas
	Task: 
	DB: DB052.bodb_CustomerLog
	
	Revisions:
	
	Param explanation
*/
BEGIN

	SET NOCOUNT ON 
	
	IF EXISTS (SELECT 1 FROM userLog_CSS WITH(NOLOCK) WHERE matchid = @matchid AND dbServer = @dbServer 
															AND actiontype = @actionType AND userID = @userID
															AND ProcessName = @ProcessName)
	BEGIN
		UPDATE [dbo].[userLog_css] WITH(ROWLOCK,UPDLOCK)
		SET [status]		= @status,
			errorMessage	= @errorMessage,
			TrackingValue	= @TrackingValue,
			IsNotified		= 0,
			logdate			= GETDATE()
		WHERE 
			matchid			= @matchid 
			AND dbServer	= @dbServer 
			AND actiontype	= @actionType 
			AND userID		= @userID
			AND ProcessName = @ProcessName
	END
	ELSE
	BEGIN
		INSERT INTO userLog_css(userID, matchid, dbServer, actiontype, [status], errorMessage, TrackingValue, IP, ProcessName)
						VALUES(@userID,@matchid,@dbServer,@actiontype,@status,@errorMessage,@TrackingValue,@IP, @ProcessName)
	END
END



GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CSSUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_CSSUpd] TO [vnteam] AS [dbo]