ALTER PROCEDURE [dbo].[Acc_UpdateNumberGameBalls]
	@matchid int,
	@firstball_value tinyint = NULL, -- 0 means N/A	
	@secondball_value tinyint = NULL, -- 0 means N/A
	@thirdball_value tinyint = NULL, -- 0 means N/A
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:[Viet]
	Date:[20111219]
	Task: change the result of numbergame
	DB: DBPRO/BODB02
	
	Revisions:
	- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
					   . Add @ErrCode, @ErrMsg to raise error
	- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table															
	- 20130121@Elodie:  Change link server DBTRANS to DBTXN
						Write more log on UserLog table in case of DBLOG server failure
		
*/
BEGIN	

SET NOCOUNT ON
-- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM DBTXN.bodb02.dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 103,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

DECLARE @LogData NVARCHAR(300)
INSERT INTO DBTXN.bodb02.dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
IF (@@Error = 0)
BEGIN 
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName = Acc_UpdateNumberGameBalls'
	END TRY
	BEGIN CATCH
		SELECT @LogData = 'ADD SUCCESS SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData		
	END CATCH
END
ELSE 
BEGIN
	SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---------

	UPDATE match with(rowlock, updlock)
	SET hthomescore = @firstball_value
	WHERE matchid = @matchid
		
	UPDATE match with(rowlock, updlock)
	SET livehomescore = @thirdball_value
		,finalhomescore = @thirdball_value  
	WHERE matchid = @matchid
						
	DELETE bingoball
	WHERE matchid = @matchid

	-- FIRST ball
	IF @firstball_value IS NULL 
	BEGIN 
		DELETE FROM DBTXN.bodb02.dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK) 
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN	
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = 5838421, --dbaAdmin
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls'
			END TRY
			BEGIN CATCH
				SELECT @LogData = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
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
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls'
			END TRY
			BEGIN CATCH
				SELECT @LogData = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
				EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
									  @Doing = @LogData	
			END CATCH					
		END
		RETURN
	END
	ELSE	
	INSERT INTO bingoball(matchid, seq, number, updatetime)
	VALUES(@matchid, 1, @firstball_value, CURRENT_TIMESTAMP)

	-- SECOND ball
	IF @secondball_value IS NULL 
	BEGIN 
		DELETE FROM DBTXN.bodb02.dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK) 
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN	
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = 5838421, --dbaAdmin
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls'
			END TRY
			BEGIN CATCH
				SELECT @LogData = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
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
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls'
			END TRY
			BEGIN CATCH
				SELECT @LogData = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
				EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
									  @Doing = @LogData	
			END CATCH					
		END
		RETURN
	END	
	ELSE
	INSERT INTO bingoball(matchid, seq, number, updatetime)
	VALUES(@matchid, 2, @secondball_value, CURRENT_TIMESTAMP)

	-- THIRD ball
	IF @thirdball_value IS NULL 
	BEGIN 
		DELETE FROM DBTXN.bodb02.dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK) 
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN	
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = 5838421, --dbaAdmin
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls'
			END TRY
			BEGIN CATCH
				SELECT @LogData = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
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
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls'
			END TRY
			BEGIN CATCH
				SELECT @LogData = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
				EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
									  @Doing = @LogData	
			END CATCH					
		END
		RETURN
	END	
	ELSE	
	INSERT INTO bingoball(matchid, seq, number, updatetime)
	VALUES(@matchid, 3, @thirdball_value, CURRENT_TIMESTAMP)
	
	   
----
DELETE FROM DBTXN.bodb02.dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK) 
WHERE KeyID = 1 AND KeyValue = @matchid	
IF (@@Error = 0)
BEGIN	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls'
	END TRY
	BEGIN CATCH
		SELECT @LogData = 'DEL SUCCESS SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
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
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls'
	END TRY
	BEGIN CATCH
		SELECT @LogData = 'DEL FAILED SPName = Acc_UpdateNumberGameBalls MatchID=' + @matchid + ' KeyID=1 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData	
	END CATCH					
END

END

GO
GRANT EXECUTE ON [dbo].[Acc_UpdateNumberGameBalls] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UpdateNumberGameBalls] TO [vnteam]