ALTER PROCEDURE [dbo].[WriteLog_UserLog_SettleOutright]
	@UserID int, 
	@MatchID int, 
	@ActionID int=0, 
	@LeagueID int,
	@EventDate datetime,
    @Remark VARCHAR(500) = ''
AS
/*
Creator: Elodie
Date: 2013-05-06
DB: DBLOG.bodb_CustomerLog
Task: Insert LOGS for settlement outright function 

Revision:

*/

SET NOCOUNT ON

INSERT INTO dbo.UserLog_SettleOutright
(	
	UserID,
	MatchID,
	ActionID,
	LeagueID,
	EventDate,
    Remark
) 
VALUES
(	
	@UserID,
	@MatchID,
	@ActionID,
	@LeagueID,
	@EventDate,
    @Remark
)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_SettleOutright] TO [bodbAdminNet]
GO
DENY EXECUTE ON [dbo].[WriteLog_UserLog_SettleOutright] TO [bodbDownlineNet]
GO
DENY EXECUTE ON [dbo].[WriteLog_UserLog_SettleOutright] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_SettleOutright] TO [vnteam]