ALTER PROCEDURE [NAP_Admin_Settlement_Parlay_Job]
AS
/*
	Created: 20140114@Kathy
	Task: select a match from list to perform calculating
	DB: DBTXN\bodb02
	Original: Admin_Settlement_Parlay_Job
	Revisions:
*/
BEGIN
	SET NOCOUNT ON 
	
	IF EXISTS (SELECT TOP 1 1 FROM Parlay_WaitingList WITH(NOLOCK) WHERE IsCalculating = 1)
	BEGIN
		--- check Starttime if needed		
		RETURN
	END
	
	DECLARE @matchid VARCHAR(2000),
			@creator INT,
			@action VARCHAR(10),
			@IP VARCHAR(15),
			@ErrCode INT,
			@ErrMsg NVARCHAR(200),
			@keyId int
			
	
	UPDATE TOP (1) dbo.Parlay_WaitingList WITH(ROWLOCK, UPDLOCK)
	SET IsCalculating = 1, 		
		@matchID = matchid, 
		@action  = [action],
		@creator = creator,
		@IP		 = IP,
		@keyId = keyid
	WHERE matchid = (	SELECT TOP 1 matchid 
						FROM dbo.Parlay_WaitingList WITH(NOLOCK)
						where IsCalculating = 0
						ORDER BY TryCount, starttime 
					)
	AND IsCalculating = 0

	IF @@ROWCOUNT = 0 RETURN	
	
	BEGIN TRY
						EXEC [Admin_Settlement_Parlay]
				@matchids	= @matchid,
				@creator	= @creator,
				@action		= @action,
				@IP			= @IP,
				@ErrCode	= @ErrCode OUTPUT,
				@ErrMsg		= @ErrMsg OUTPUT
				
	END TRY
	BEGIN CATCH
		UPDATE Parlay_WaitingList WITH(ROWLOCK,UPDLOCK)
		SET IsCalculating = 0,
			TryCount = TryCount + 1
		WHERE keyid = @keyId
		
		SET @ErrMsg = @ErrMsg + '-' + ERROR_MESSAGE()
		
		INSERT INTO Settled_Message(AdminId, MatchId, IP, Starttime, Action, Message)
		SELECT @creator, @matchID, @IP, GETDATE(),@Action, @ErrMsg
	END CATCH
	
	IF @ErrCode <> 0 OR @ErrMsg <> ''  --- calculate failed set calculateing = 0 back
	BEGIN
		UPDATE Parlay_WaitingList WITH(ROWLOCK,UPDLOCK)
		SET IsCalculating = 0,
			TryCount = TryCount + 1
		WHERE keyid = @keyId
		
		INSERT INTO Settled_Message(AdminId, MatchId, IP, Starttime, Action, Message)
		SELECT @creator, @matchID, @IP, GETDATE(),@Action, @ErrMsg
	END
	ELSE 
	BEGIN
		UPDATE Parlay_WaitingList WITH(ROWLOCK,UPDLOCK)
		SET IsCalculating = 2
		WHERE keyid = @keyId
	END
END

GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Parlay_Job] TO [vnteam]
GO


