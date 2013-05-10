ALTER PROCEDURE [dbo].[Acc_UserLog_CreditSel]    
    @CustID INT ,
	@CustName varchar(50) = '',
    @FromDate DATETIME ,
    @ToDate DATETIME ,    
    @IsInternal TINYINT ,
    @PageIndex INT ,
    @PageSize INT
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog
    

	Description:
	- Get paged log credit
	Revisions:
    - 20110623@Sophia: Do not allow to search for Nickname if @IsAdminAccess = 0
		
    Param's Explaination:    
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log
	- @ActionTypeId: action type
	- @IsInternal: Accounting: 1 Agent:0
	- @PageIndex: from 0
	- @PageSize: total record per request
*/

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON ;

SET @PageIndex = ABS(@PageIndex)
SET @PageSize = ABS(@PageSize)  


DECLARE @lbound INT 
DECLARE @ubound INT

SET @lbound = @PageIndex * @PageSize       
	
SET @ubound = @lbound + @PageSize 
IF ( @PageIndex > 0 ) 
    SET @lbound = @lbound + 1

DECLARE @ActionName AS NVARCHAR(256)
		
IF ( @IsInternal = 0 AND NOT EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE username2 = @CustName) ) OR @IsInternal = 1
SELECT	LogID,
        UserID,
		CustID,
		LogDate,
		OldValue,
		NewValue,
		IP,
		Doing,
		ActionID,
		IsInternal,
		ActionTypeID,
        SPName,
		UserName,
		CustName,                                                             
		ActionName
					
FROM    ( SELECT    ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum,
                    LogID,
                    UserID,
					uc.CustID,
					LogDate,
					OldValue,
					NewValue,
					IP,
					Doing,
					la.ActionID,
					IsInternal,
					la.ActionTypeID,
                    la.SPName,
					Username =	CASE 
										when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										ELSE ci.Username
									END,
					@CustName as CustName,                                         
					la.ActionNameEN As ActionName
          FROM      dbo.UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
          WHERE     uc.CustID = @CustID
                    AND LogDate BETWEEN @FromDate AND @ToDate                            
                    AND IsInternal <= @IsInternal
        ) AS MyTable
WHERE   RowNum BETWEEN @lbound AND @ubound



GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CreditSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CreditSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CreditSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_CreditSel] TO [vnteam]