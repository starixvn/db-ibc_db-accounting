/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DailyTxn_UpdChecker]
@CheckerID		INT,
@CheckerName	VARCHAR(50),
@Refnos			VARCHAR(8000),
@IsVerified		BIT = 0, 
@IP				VARCHAR(15),
@ErrCode		INT = 0 OUTPUT,
@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS
/*
Created by: Jamie
Date: 2010-09-18 
Task : Daily Transaction - Update Checker 
DB: DBTXN/bodb02

Revisions:
	- 20101229@Lukas: Re-arrange bettype
	- 20130201@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	
Param's Explanation:
	@TransIDs   : '1111,2341,...'
*/
BEGIN
	SET NOCOUNT ON

	--Check permission for account site
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid = @CheckerID, @funcname = '[DailyFinanceTxn]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		IF @ErrCode <> 0 
			RETURN

	DECLARE	@UserID INT, @ActionID INT, @UserName VARCHAR(50)
	SELECT	@UserID = @CheckerID, @Username = @CheckerName , @ActionID = 1600 

	DECLARE	@tmpTransID TABLE (transID BIGINT)

	INSERT INTO @tmpTransID(transID)
	SELECT	transID	FROM Bettrans WITH (NOLOCK) 
	WHERE	refno IN (	SELECT	CONVERT(bigint, val)
						FROM	dbo.strSplit (@Refnos, ',' ))
			AND matchid = 0
			AND bettype > 20000 

	IF @IsVerified = 0 
	BEGIN
		SELECT	@ActionID = 1601, @CheckerID = NULL, @CheckerName ='0'
	END


	UPDATE	Bettrans WITH (UPDLOCK,ROWLOCK)
	SET		betid = @CheckerID, betcheck = @CheckerName, checkTime = GETDATE()	
	WHERE	transID IN (SELECT transID FROM @tmpTransID) 
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg = 'Update failed. Please try again.'
				,@ErrCode = 100
		RETURN
	END

	DECLARE	@LogData VARCHAR(1000)
	SELECT	@LogData = '<Acc_DailyTxn_UpdChecker CheckerName="'+ @Username +'" />'

	--ActionID: 1600 - Verify; 1601 - Unverify 
	BEGIN TRY
		INSERT INTO DBLOG.bodb_CustomerLog.dbo.UserLog_Transaction(UserID, Refno, ActionID, IP, Doing)
		SELECT	@UserID, CONVERT(bigint, val),@ActionID, @IP, @LogData
		FROM	dbo.strSplit (@Refnos, ',' )
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_DailyTxn_UpdChecker CheckerName="'+ @Username +
						  '" ErrMsg="' + error_message() + '" />'
		INSERT INTO bodb_CustomerLog.dbo.UserLog_Transaction(UserID, Refno, ActionID, IP, Doing)
		SELECT	@UserID, CONVERT(bigint, val),@ActionID, @IP, @LogData
		FROM	dbo.strSplit (@Refnos, ',' )
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Acc_DailyTxn_UpdChecker] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_DailyTxn_UpdChecker] TO [vnteam]