ALTER PROCEDURE [dbo].[Acc_UserLog_CreditSelTotalRecords]    
    @CustID INT,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @IsInternal TINYINT    
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- count total record with input conditions
	
    Param's Explaination:    
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log	
	- @IsInternal: AccountingSite: 1 Agent:0
	
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT    COUNT(LogID)                           
           FROM     dbo.UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
          WHERE     CustID = @CustID
                    AND LogDate BETWEEN @FromDate AND @ToDate                           
                    AND IsInternal <= @IsInternal


GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CreditSelTotalRecords] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CreditSelTotalRecords] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_CreditSelTotalRecords] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_CreditSelTotalRecords] TO [vnteam]