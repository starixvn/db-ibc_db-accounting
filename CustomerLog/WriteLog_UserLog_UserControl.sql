ALTER PROCEDURE [dbo].[WriteLog_UserLog_UserControl]
	@CustID INT,
	@Doing NVARCHAR(MAX),
	@UserID int = NULL,
	@TypeID tinyint=0,
	@ActionID int=NULL,
	@Duration int = NULL
AS
/*
	Created: 20110526:TOM
	Task : Write Credit Log on User Control/ACCOUNTING.	
	DB: DBLog.bodb_CustomerLog

	Revisions :
		- 20120606@Sophia: Change datatype of @Doing to NVARCHAR(MAX)
	
*/

SET NOCOUNT ON

INSERT INTO  dbo.UserLog_UserControl
           ([CustID]
           ,[LogDate]
           ,[UserID]
           ,[TypeID]
		   ,[ActionID]
           ,[Duration]
           ,[Doing])
     VALUES
			(@CustID
			,GETDATE()
			,@UserID
			,@TypeID
			,@ActionID
			,@Duration
			,@Doing
			)
GO

GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_UserControl] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_UserControl] TO [bodbAdminNet]
