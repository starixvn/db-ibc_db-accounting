 ALTER PROCEDURE [dbo].[Acc_UserLog_UserControlSelTotalRecords]    
	@FromDate DATETIME,
	@ToDate DATETIME,
	@CustID INT
AS 

/*	Created:20120606@Sophia
    Task: Calculate total records for view log user control
	DB: DBLOG.bodb_CustomerLog
 
	Revisions:
		
    Param's Explaination:    
		- @TypeID:
				0: used for Group
				1: used for Admin
		- @Name: for Group name and Admin name	
		- @PageIndex: from 0
		- @PageSize: total record per request
	
*/
SET NOCOUNT ON

SELECT	COUNT(U.LogID)      
FROM	UserLog_UserControl U WITH (NOLOCK)
INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
WHERE	U.LogDate BETWEEN @FromDate AND @ToDate
		AND U.ActionID BETWEEN 1700 AND 1799
 		AND U.CustID = @CustID  

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_UserControlSelTotalRecords] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_UserControlSelTotalRecords] TO [vnteam]

 