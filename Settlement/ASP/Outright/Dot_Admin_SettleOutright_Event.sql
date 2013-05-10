ALTER PROCEDURE [dbo].[Dot_Admin_SettleOutright_Event]
	@matchid int,
	@status nvarchar(10),
	@isDeadheat bit=0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : sp for outright settlement

DB: DBPRO/BODB02
Original: 

Revisions:
	- 20120307@MartinChen(DBProduct): add isDeadHeat to save db
	- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
					   . Add @ErrCode, @ErrMsg to raise error
	- 20130103@Elodie:  Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table					
	- 20130121@Elodie:  Change link server DBTRANS to DBTXN
						Write more log on UserLog table in case of DBLOG server failure
	
Param's Explanation:
	- @deadheat = fraction of deadheat to divide (1,2,3  etc)
*/
SET NOCOUNT ON

---- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM DBTXN.bodb02.dbo.TempVariableNumber WHERE KeyID = 2 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

DECLARE @LogData NVARCHAR(300)
INSERT INTO DBTXN.bodb02.dbo.TempVariableNumber (KeyID, KeyValue) VALUES (2, @matchid)
IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Event'
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData		
	END CATCH
ELSE 
BEGIN
	SELECT @ErrCode = 102, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---------

if (@status='won')
begin
	update outright with (updlock,rowlock) 
	set oddsstatus = 'Completed', 
		eventdate = convert(char(10),getdate(),111), 
		[status] = 'WON',
		changetime = getdate(),
		isDeadheat = @isDeadheat
	where orid = @matchid
end 
else if (@status='lose')
begin
	Update outright with (updlock,rowlock)
	set oddsstatus = 'Completed', 
		eventdate = convert(char(10),getdate(),111), 
		[status] = 'LOSE',
		changetime = getdate(),
		isDeadheat = @isDeadheat
	where orid = @matchid
end
ELSE IF @status = 'Refund'
BEGIN
	UPDATE dbo.outright with (updlock,rowlock)
	SET oddsstatus = 'Completed', 
		eventdate = convert(char(10),getdate(),111), 
		[status] = 'Refund',
		changetime = getdate(),
		isDeadheat = @isDeadheat
	WHERE orid = @matchid
END
ELSE
BEGIN
	UPDATE dbo.outright with (updlock,rowlock)
	SET changetime = getdate(),
		isDeadheat = @isDeadheat
	WHERE orid = @matchid
END

----
DELETE FROM DBTXN.bodb02.dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 2 AND KeyValue = @matchid
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = 0, 
			@Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Event'
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData				
	END CATCH
END	
ELSE
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = 0, 
			@Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Event' 
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData					
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Event] TO [Dot_Admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Admin_SettleOutright_Event] TO [vnteam]