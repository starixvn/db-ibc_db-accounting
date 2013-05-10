ALTER PROCEDURE [dbo].[Acc_LoginAdmin_Settlement]
	@UserName varchar(50) OUTPUT,
	@UserPwd varchar(50),
	@LoginIP varchar(20),	
	@CustID int OUTPUT,
	@RoleID tinyint OUTPUT,
	@LoginDomain NVARCHAR(253) = NULL,
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@From nvarchar(200) = '',
	@System varchar(50) = '' OUTPUT
AS
/*
Created: 
Task : 
DB: DBTXN/BODB02
Original:

Revisions:
	- 20081217@Phuong.Nguyen: Log data to UserLog_runSP
    - 20090402@Phuc: write log for logout.
    - 20100101@Kiwi: Modify Log.
	- 20100109@Daniel: 
		+ When user does not exist in system => Result:Failed(User_Not_Found) instead of Result:Failed(Not_Admin)
		+ After typing wrong password > 5 times, show err msg "A/C closed...", not wait to 7th
		+ Discard check A/C exists in DB03.Acc_Customer when checking existing of user
	- 20100714@Henry: return ACCTHAI if GroupName is THB, others: ACCOUNTING
	- 20101022@Johnson: record execution time
	- 20101110@Steven: return ACCINDO if GroupName is INDO
	- 20101130@Johnson: get @system from GroupName
	- 20110621@Sophia: Do not update closed = 1 when login wrong more than 5 times, because it will be checked on web
	- 20111114@Jamie: Add Domain, CountryCode, Browser and Plaform in LOG.
	- 20120223@Dan: check @failedcount < max size of tinyint before updating
	- 20130118@Elodie: Change link server DB03 to DBPOLICY	
					   Write more log on DBTXN server in case of DBLOG server failure
Param's Explanation:
*/
SET NOCOUNT ON

DECLARE @Begin		DATETIME
DECLARE @End		DATETIME
DECLARE @Duration	INT

SET @Begin = GETDATE()

declare @LogData nvarchar(200),
	@db_userpwd nvarchar(50),
	@failedcount tinyint, @closed bit--, @Groupname nvarchar(50)

SELECT @LogData = '', @ErrMsg = '', @ErrCode = 0 -- initial value

SELECT @CustID = c.custid, @db_userpwd = c.userpwd, @RoleID = roleid, @failedcount = IsNull(logincount, 0),
		@UserName = username
FROM dbo.customer c with (nolock)
WHERE username = @UserName

IF @@ROWCOUNT = 0 -- user not found
BEGIN
		SELECT  @ErrMsg = case @Language 
							when 'E' then 'Wrong username or password.'
							when 'CS' then N'Wrong username or password.'
							when 'J' then N'IDまたはパスワードが正しくありません。'
							else N'Wrong username or password.'
						end,
		@ErrCode = 101,
		@CustID = 0,
		@LogData = 'Admin:' + @UserName + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(User_Not_Found) From:' + @From
END
ELSE IF @RoleID NOT IN (5,6,7,8,9,10)
BEGIN
	SELECT  @ErrMsg = N'Wrong username or password.',
		@ErrCode = 102, 
		@LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(Not_Admin) From:' + @From
END
ELSE IF @UserPWD <> @db_userpwd
BEGIN
	SELECT @ErrMsg = N'Wrong username or password.',
		@ErrCode = 103,
		@LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(Password) From:' + @From,
		@failedcount = @failedcount + 1

--	IF @failedcount > 5  -- already failed for 5 times, this is 6th time , LOCK THE A/C
--	BEGIN
--	
--		UPDATE custinfo with (rowlock, updlock) SET closed = 1 WHERE custid = @custid
--		--Phuong.Nguyen, log data
--		DECLARE @LogSPData varchar(1000)
--		SELECT @LogSPData = '<Acc_LoginAdmin IP="'+ @LoginIP + '" ' + 'From="' + @From + '" />'
--		SET @End = GETDATE()
--		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
--		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
--			@UserID = @CustID,
--			@CustID = @CustID,
--			@ActionID = 905,
--			@TrackingValue = @LogSPData,
--			@Duration = @Duration
--		--END
--
--		SELECT  @ErrMsg = 'Your A/C was Closed, Please contact your supervisor.',
--			@ErrCode = 104
--	END
--	IF @failedcount <= 6
	IF (@failedcount <= 255) -- max of tinyint
	BEGIN
		UPDATE customer with (rowlock, updlock) SET logincount = @failedcount WHERE custid = @custid
	END
END

--Get @system by CustID 

EXEC DBPOLICY.BODB02.dbo.Acc_Con_AdminSelSystembyCustID_Settlement @CustID = @CustID, @System = @System OUTPUT 

--IF @Groupname = 'THB'
--	SET @System = 'ACCTHAI'
--ELSE IF @Groupname = 'INDO'
--	SET @System = 'ACCINDO'
--ELSE 
--	SET @System = 'ACCOUNTING'


IF (@ErrMsg = '') AND (@LogData = '')
BEGIN
	SELECT @closed = closed FROM dbo.custinfo with (nolock) WHERE custid = @CustID

	IF @closed = 1
		SELECT  @ErrMsg = 'Your A/C was Closed, Please contact your supervisor.',
			@ErrCode = 104,
			@LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(A/C_Closed) From:' + @From	
	ELSE
	BEGIN
		UPDATE customer with (rowlock, updlock)
		SET logincount = 0, iplogin = @LoginIP, lastlogged = CURRENT_TIMESTAMP, on_sessionid = 0
		WHERE custid = @custid

		SET @LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Success From:' + @From
	END
END
	
	
	IF @LogData <> ''
	BEGIN		
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
				 @UserID = @CustID, 
				 @RoleID = @RoleID, 
				 @SubAccID = 0,
				 @ServerID = 0,
				 @LoginIP = @LoginIP,
				 @ActionID = 1306,
				 @Doing = @LogData,
				 @DomainName = @LoginDomain,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration
		END TRY
		BEGIN CATCH
			SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login 
				 @UserID = @CustID, 
				 @RoleID = @RoleID, 
				 @SubAccID = 0,
				 @ServerID = 0,
				 @LoginIP = @LoginIP,
				 @ActionID = 1306,
				 @Doing = @LogData,
				 @DomainName = @LoginDomain,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration
		END CATCH				 
	END
GO
GRANT EXECUTE ON [dbo].[Acc_LoginAdmin_Settlement] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_LoginAdmin_Settlement] TO [vnteam]