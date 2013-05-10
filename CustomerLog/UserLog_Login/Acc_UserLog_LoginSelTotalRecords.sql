ALTER PROCEDURE [dbo].[Acc_UserLog_LoginSelTotalRecords]    
    @UserId INT,	
    @FromDate DATETIME,
    @ToDate DATETIME,    
    @IsAdminAccess BIT = 0
	   
AS
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- count total record with input conditions
	Revisions:
	- 20100710@Kiwi: put in a check to return retrieving data if roleid = 1
	- 20100711@Thien: add index hint
	- 20101214@Thien: comment out "OR (SubAccID = @UserId)" for performance improvement
	- 20110526@Jamie: Allow agency/admin view sub-account log
	
    Param's Explaination:    
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log	
	- @IsAdminAccess: Accouting site TRUE, agent = FALSE
	
	
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON ;
--RETURN TO RETRIEVE DATA IF ROLEID = 1 
DECLARE @RoleID tinyint
SELECT @RoleID = roleid from bodb02.dbo.custinfo(nolock) where custid = @UserId
IF (@RoleID = 1)
	RETURN

IF (@IsAdminAccess = 0)
BEGIN
	SELECT  COUNT(LogID)                           
	FROM    dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
			INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
	WHERE    LogDate BETWEEN @FromDate AND @ToDate			
			AND IsInternal <= @IsAdminAccess
			AND ((	UserID = @UserId AND SubAccID >= 0)
					--or (SubAccID = @UserId)
					)
END
ELSE
BEGIN
	SELECT  COUNT(LogID)                           
	FROM    dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
			INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
	WHERE     LogDate BETWEEN @FromDate AND @ToDate			
			AND IsInternal <= @IsAdminAccess
			AND UserID = @UserId 
					-- AND SubAccID <= 0)
					--OR (SubAccID = @UserId)
				
END
   

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LoginSelTotalRecords] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LoginSelTotalRecords] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LoginSelTotalRecords] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_LoginSelTotalRecords] TO [vnteam]