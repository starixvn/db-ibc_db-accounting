ALTER PROCEDURE [dbo].[Acc_UserLog_RunSPSelTotalRecords]    
    @CustId INT, 
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT =-1,
    @IsInternal TINYINT,
	@LowerActionId INT = NULL,
	@UpperActionId INT = NULL  
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
	- @IsAdminAccess: Accouting site TRUE, agent = FALSE
	- @IsSubCust: view logaction affect to sub account or not
	
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON ;
 
IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)  
BEGIN
	select @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
	IF (@ActionTypeId > 0)
		SELECT  COUNT(LogID)
		FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
		WHERE   CustID = @CustId
				AND LogDate BETWEEN @FromDate AND @ToDate
				AND ActionTypeID = @ActionTypeId
				AND IsInternal <= @IsInternal
	ELSE
		SELECT  COUNT(LogID)                           
		FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
		WHERE   CustID = @CustId
				AND LogDate BETWEEN @FromDate AND @ToDate								
				AND IsInternal <= @IsInternal
				AND la.ActionID NOT BETWEEN @LowerActionId AND @UpperActionId
END
ELSE
BEGIN
	SELECT  COUNT(LogID)                           
    FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
    WHERE   CustID = @CustId
            AND LogDate BETWEEN @FromDate AND @ToDate
            AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
            AND IsInternal <= @IsInternal
END

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [vnteam]