ALTER PROCEDURE [dbo].[LAS_WriteLog_UserLog_RunSP]
	@UserID int, 
	@MatchID int, 
	@ActionID int=0, 	
    @Remark VARCHAR(500) = ''
AS
/*
Creator: Elodie
Date: 20140210
DB: bodb_CustomerLog
Task: Insert LOGS for checking if a LAS's SP is called from main SP

Revision:

*/

SET NOCOUNT ON

INSERT INTO dbo.UserLog_RunSP_LAS
(	
	UserID,
	MatchID,
	ActionID,	
	Remark
) 
VALUES
(	
	@UserID,
	@MatchID,
	@ActionID,	
    @Remark
)


GO
GRANT EXECUTE ON [dbo].[LAS_WriteLog_UserLog_RunSP] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[LAS_WriteLog_UserLog_RunSP] TO [vnteam] AS [dbo]