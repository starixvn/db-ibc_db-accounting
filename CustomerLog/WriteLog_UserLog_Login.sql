set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[WriteLog_UserLog_Login]
 @UserID int,   
 @RoleID tinyint,   
 @SubAccID int,   
 @ServerID int,   
 @LoginIP VARCHAR(20)='', 
 @DomainName NVARCHAR(253) = NULL,
 @ActionID int = 0,  
 @Doing VARCHAR(300),
 @BrowserName NVARCHAR(255) = NULL,
 @Platform NVARCHAR(255) = NULL,
 @CountryCode VARCHAR(64) = NULL,
 @Duration INT = NULL	,
 @NickName VARCHAR(50) = NULL	 
AS  
/*  
Creator: 20081129@QuiNV  
Task: Insert login count statistic  
DB: DBLOG.BODB_CUSTOMERLOG 
Original:   
  
Revisions:  
 - 20100101@Kiwi: Write logs for ActionID and Doing  
 - 20101006@Kaden; Add three parameter (DomainName, BrowserName, Platform) 
 - 20101022@Johnson: Add parameter @Duration
 - 20110608@Sophia: Add parameter @NickName

Param's Explanation:  
• @CustID: main account login.  
• @RoleID: roleID of main account.  
• @SubAccID: subaccount ID(0: main account login, >0: subaccount login, <0: admin login => subaccid stand for admin ID).  
• @ServerID: serverID.  
• @DomainName: Domain user login.  
• @LoginIP: IP user login.  
• @BrowserName: Browser user using.  
• @Platform: Platform user login. 
• @CountryCode: CountryCode user login.  
• @Duration: Time process login
• @Duration: Nickname Login

*/  
  
  
SET NOCOUNT ON  
  
INSERT INTO dbo.UserLog_Login( UserID,   
        RoleID,   
        SubAccID,   
        ServerID,   
        IP, 
		DomainName,  
        LogDate,   
        ActionID,   
        Doing,
		BrowserName,
		Platform,
		CountryCode,
		Duration,
		Username2  
         )   
      VALUES( @UserID,   
        ISNULL(@RoleID,0),   
        isnull(@SubAccID,0), 
        @ServerID,  
		@LoginIP,   
		@DomainName, 
        CURRENT_TIMESTAMP,   
        @ActionID,   
        @Doing,
		@BrowserName,
		@Platform,
		@CountryCode,
		@Duration ,
		@NickName
         )  

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Login] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Login] TO [bodbLicenseeNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Login] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Login] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Login] TO [vnteam]

