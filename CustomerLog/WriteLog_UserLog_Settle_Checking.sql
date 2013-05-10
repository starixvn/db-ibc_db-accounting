 ALTER PROCEDURE [dbo].[WriteLog_UserLog_Settle_Checking]
	@UserID int, 
	@MatchID int, 
	@KeyID tinyint,
	@ActionID int=0, 	
    @Remark VARCHAR(500) = ''
AS
/*
Creator: Elodie
Date: 20120102
DB: bodb_CustomerLog
Task: Insert LOGS for checking a match which cannot settle due to it is marked as "Being calculated"

Revision:

*/

SET NOCOUNT ON

INSERT INTO dbo.UserLog_Settle_Checking
(	
	UserID,
	MatchID,
	KeyID,
	ActionID,	
	Remark
) 
VALUES
(	
	@UserID,
	@MatchID,
	@KeyID,
	@ActionID,	
    @Remark
)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Settle_Checking] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Settle_Checking] TO [vnteam]