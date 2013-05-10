 ALTER PROCEDURE [dbo].[WriteLog_UserLog_Credit]
	@UserID INT,
	@CustID INT = 0,
	@SPName	VARCHAR(50)=NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER 
	@Doing VARCHAR(1000),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15)='',
	@ActionID int = NULL
AS
/*
Created: 
Task : Write Credit Log .	
DB: DBLOG.bodb_CustomerLog
Original:

Revisions: 
    - 20090903@Simon: Write Credit Log.	
    - 20100102@Kiwi: Add ActionID Log.
*/
SET NOCOUNT ON
INSERT INTO UserLog_Credit (UserID, 
							CustID,
							SPName, 
							Doing, 
							OldValue, 
							NewValue, 
							IP, 
							ActionID) 
					VALUES (@UserID, 
							@CustID,
							@SPName, 
							@Doing, 
							@OldValue, 
							@NewValue, 
							@IP, 
							@ActionID)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Credit] TO [vnteam]