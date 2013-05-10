USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog]    Script Date: 07/27/2010 13:13:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[WriteLog_UserLog]
@UserID int,
@Doing nvarchar(300)
AS
/*
	Task: Write Log on UserLog
	DB: DB02.BODB02
	
	Revisions:
		- 20100727@Jamie: Grant permission for Acc extension 
		- 20100729@Henry: Grant permission for bodbAdminNet
*/
SET NOCOUNT ON
insert into dbo.UserLog (UserID, Doing) values (@UserID, @Doing)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog] TO [vnteam]
GO
 
 