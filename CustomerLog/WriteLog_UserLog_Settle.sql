ALTER PROCEDURE [dbo].[WriteLog_UserLog_Settle]
	@UserID int, 
	@MatchID int, 
	@ActionID int=0, 
	@finalhomescore INT,
    @finalawayscore INT,  
    @hthomescore INT,
    @htawayscore INT,
    @GoalRecord VARCHAR(50),
    @betstatus NVARCHAR(50),
    @Remark VARCHAR(3000) = '',	
	@IP varchar(15)='',
	@LogDate DATETIME = NULL
AS
/*
Creator: Daniel
Date: 2009-12-25
DB: bodb_CustomerLog
Task: Insert LOGS for settlement function

Revision:
	- 20110110@Jamie: Change size of Remark to 500
	- 20160507@Patrick: Add more param @LogDate & change size of Remark to 3000

*/

SET NOCOUNT ON;

INSERT INTO dbo.UserLog_Settle
(	
	UserID,
	LogDate,
	MatchID,
	ActionID,
	[finalhomescore],
	[finalawayscore],  
    [hthomescore],
    [htawayscore],
    [GoalRecord],
    [betstatus],
    [Remark],
	IP
) 
VALUES
(	
	@UserID,
	CASE WHEN @LogDate IS NULL THEN GETDATE() ELSE @LogDate END,
	@MatchID,
	@ActionID,
	@finalhomescore,
    @finalawayscore,  
    @hthomescore,
    @htawayscore,
    @GoalRecord,
    @betstatus,
    @Remark,	
	@IP
)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Settle] TO [bodbAdminNet]
GO
DENY EXECUTE ON [dbo].[WriteLog_UserLog_Settle] TO [bodbDownlineNet]
GO
DENY EXECUTE ON [dbo].[WriteLog_UserLog_Settle] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Settle] TO [vnteam]