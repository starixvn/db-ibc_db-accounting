ALTER PROCEDURE [dbo].[Acc_AutoFollowBetInsBACustomer]	
	@strCustID VARCHAR(MAX),
	@UserID int=0,
	@IP nvarchar(50) = '',
	@rate smallmoney,
	@totalRows INT = 0 OUTPUT,
	@ErrCode int = 0 Output,
	@ErrMsg VARCHAR(1000) = '' Output
AS
/*  Created: Henry  
	Date: 2012-07-06
    Task : Insert BA Customers to Cust_FollowBet
    DB: DBTXN/bodb02  
   
    Revisions:  
        20130201@Daniel: Change link server alias & failover writelog to DBTXN  
		
	Param's Explanation:  
	 
	  
*/  
DECLARE @startRun DATETIME
DECLARE @endRun DATETIME
DECLARE @duration INT
SET @startRun = GETDATE()
DECLARE @LogSPData VARCHAR(5000)

DECLARE @TempCustID  AS TABLE (CustID INT)
INSERT INTO @TempCustID (CustID)
SELECT c.CustID 
FROM Custinfo c WITH (NOLOCK) 
	INNER JOIN DBLIC.bodb_licensee.dbo.LicenseeBAHistory lba WITH(NOLOCK) ON c.custid = lba.custid
WHERE 
	c.CustID IN (SELECT RTRIM(LTRIM(VAL)) FROM strSplit(@strCustID,','))
	AND status = 'running'
	

INSERT INTO Cust_followBet(custid, rate)
SELECT c.CustID, @rate 
FROM @TempCustID c
	LEFT JOIN Cust_followBet cf WITH (NOLOCK) ON c.custid = cf.custid
WHERE isnull(cf.custid,0) = 0

SELECT @totalRows = @@ROWCOUNT

IF @totalRows=0
BEGIN
	SELECT @ErrCode=100,@ErrMsg='Nothing was inserted, please check again!'
END

SET @endRun = GETDATE()
SET @duration  = datediff (millisecond,@startRun,@endRun)

SELECT @LogSPData = '<Acc_AutoFollowBetInsBACustomer CustID="'+ COALESCE(CAST(@strCustID as VARCHAR(MAX)),SPACE(1)) + '" ' +
'rate="'+ COALESCE(CAST(@rate as VARCHAR(40)),SPACE(1)) + '" ' +
'UserID="'+ COALESCE(CAST(@UserID as VARCHAR(50)),SPACE(1)) + '" ' +
'IP="'+ COALESCE(CAST(@IP as VARCHAR(40)),SPACE(1)) + '" ' +
'ErrCode="'+ COALESCE(CAST(@ErrCode as VARCHAR(50)),SPACE(1)) + '" ' +
'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(5000)),SPACE(1))+ '" />'

BEGIN TRY
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			    @UserID = @UserID,
			    @CustID = 0,
			    @ActionID = 635,
			    @TrackingValue = @LogSPData,
			    @TrackingValue2 = '',
			    @duration = @duration
END TRY
BEGIN CATCH
    EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			    @UserID = @UserID,
			    @CustID = 0,
			    @ActionID = 635,
			    @TrackingValue = @LogSPData,
			    @TrackingValue2 = '',
			    @duration = @duration
END CATCH

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetInsBACustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetInsBACustomer] TO [VNTeam]
GO 