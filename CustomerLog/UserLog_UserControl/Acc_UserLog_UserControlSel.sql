ALTER  PROCEDURE [dbo].[Acc_UserLog_UserControlSel]
	@FromDate DATETIME,
	@ToDate DATETIME,
	@Name nvarchar(50),
	@CustID INT,
	@PageIndex INT = 0,
    @PageSize INT = 5
AS
/*
	Created by: 20120605@Sophia
	Task: View lof of User Control 
	DB: DBLOG.bodb_CustomerLog
 
	Revisions:
	
	Param's Explanation:
	- @TypeID:
			0: used for Group
			1: used for Admin
	- @Name: for Group name and Admin name	
	- @PageIndex: from 0
	- @PageSize: total record per request
				
*/
SET NOCOUNT ON 

SET @PageIndex = ABS(@PageIndex)
SET @PageSize = ABS(@PageSize)  

DECLARE @lbound INT 
DECLARE @ubound INT

SET @lbound = @PageIndex * @PageSize       
	
SET @ubound = @lbound + @PageSize 
IF ( @PageIndex > 0 ) 
    SET @lbound = @lbound + 1

SELECT	LogID, LogDate, TypeID, CustID, CustName,  
		UserID, Username , ActionID, ActionName, Doing 
FROM	(SELECT     ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
					U.LogID, U.LogDate, U.TypeID, U.CustID, @Name as CustName,  
					U.UserID, D.Username as UserName, U.ActionID, A.ActionNameEN as ActionName, U.Doing 
			FROM	UserLog_UserControl U WITH (NOLOCK)
			INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
			LEFT JOIN BODB02.dbo.Custinfo D WITH (NOLOCK) ON U.UserID = D.CustID
			WHERE	U.LogDate BETWEEN @FromDate AND @ToDate
					AND U.ActionID BETWEEN 1700 AND 1799
 					AND U.CustID = @CustID 
		) AS MyTable
WHERE   RowNum BETWEEN @lbound AND @ubound
 


GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_UserControlSel] TO [vnteam]

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_UserControlSel] TO [bodbAdminNet] 