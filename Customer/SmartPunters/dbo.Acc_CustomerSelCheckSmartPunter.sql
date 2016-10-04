ALTER PROCEDURE [dbo].[Acc_CustomerSelCheckSmartPunter]
	@custid INT = NULL,
	@username VARCHAR(50) = '',
	@isSmartPunter BIT = 0 OUTPUT,
	@UserId	INT,
	@IsRestricted	BIT,
	@ActionID		INT,
	@IP	VARCHAR(15)=NULL 
AS
/*
	Created: Johnson
	Date: 2014-05-20
	DB: DBCUST.CustDB
	Task: Check customer is smart punter or not
	Revisions:  
		- 20150609@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20161004@Winnie: Write log data smart punter monitoring RedmineID: #58901
*/
BEGIN
	SET NOCOUNT ON
	
	IF @custid IS NULL
		SELECT @custid = custid FROM customer WITH(NOLOCK) WHERE username = @username
				
	IF EXISTS (SELECT 1 FROM SmartPunterList WITH(NOLOCK) WHERE custid = @custid)
		SELECT @isSmartPunter = 1
	ELSE 
		SELECT @isSmartPunter = 0
	IF @isSmartPunter = 0
	BEGIN	
	EXEC DBLOG.bodb_CustomerLog.dbo.NAP_UserLog_SmartPunterIns
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = @ActionID,
			@IP = @IP,
			@IsRestricted = @IsRestricted
	END
END


GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckSmartPunter] TO [bodbAdminNet]