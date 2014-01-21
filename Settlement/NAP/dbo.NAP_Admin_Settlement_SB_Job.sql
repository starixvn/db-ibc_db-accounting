ALTER PROCEDURE [NAP_Admin_Settlement_SB_Job]
AS
/*
	Created: 20130109@Kathy
	Task: select a match from list to perform calculating (Sportsbook)
	DB: DBTXN\bodb02
	
	Revisions:
*/
BEGIN
	SET NOCOUNT ON 
	
	IF EXISTS (SELECT TOP 1 1 FROM  Single_WaitingList WITH(NOLOCK) WHERE IsCalculating = 1)
	BEGIN
		--- check Starttime if needed		
		RETURN
	END
	
	DECLARE @MatchId int,
			@AdminId int,
			@IP varchar(15),
			@Action varchar(20),
			@ErrCode INT,
			@ErrMsg NVARCHAR(200),
			@sqlCommand nvarchar(max),
			@keyId int
	
	SELECT @ErrCode = 0, @ErrMsg = ''

	SET @keyId = (SELECT TOP 1 keyid
						FROM dbo.Single_WaitingList WITH(NOLOCK)
						where IsCalculating = 0
						ORDER BY TryCount, starttime )

	UPDATE TOP (1) dbo.Single_WaitingList WITH(ROWLOCK, UPDLOCK)
	SET IsCalculating = 1, 	
		@MatchId = matchid,	
		@Adminid = AdminId,
		@IP = IP,
		@Action = Action,
		@sqlCommand = sqlCommand
	WHERE keyid = @keyId

	IF @@ROWCOUNT = 0 RETURN	
	
	BEGIN TRY
		exec sys.sp_executesql @sqlCommand,
			N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT',
			@ErrMsg = @ErrMsg OUTPUT, @ErrCode = @ErrCode OUTPUT					
	END TRY
	BEGIN CATCH	
		SET @ErrMsg = @ErrMsg + '-' + ERROR_MESSAGE()
	END CATCH

	IF ISNULL(@ErrCode,0) <> 0 or ISNULL(@ErrMsg,'') <> '' --- calculate failed set calculateing = 0 back
	BEGIN
		IF @ErrCode = 1000000
		BEGIN
			UPDATE Single_WaitingList WITH(ROWLOCK,UPDLOCK)
			SET IsCalculating = 0,
				TryCount = TryCount + 1
			WHERE keyid = @keyId	

			INSERT INTO Settled_Message(AdminId, MatchId, IP, Starttime, Action, Message, Warning)
			SELECT @AdminId, @MatchId, @IP, GETDATE(),@Action, NULL, @ErrMsg
		END	
		ELSE
		BEGIN
			UPDATE Single_WaitingList WITH(ROWLOCK,UPDLOCK)
			SET IsCalculating = 0,
				TryCount = TryCount + 1
			WHERE keyid = @keyId	

			INSERT INTO Settled_Message(AdminId, MatchId, IP, Starttime, Action, Message, Warning)
			SELECT @AdminId, @MatchId, @IP, GETDATE(),@Action, @ErrMsg, NULL
		END 	
	END
	ELSE 
	BEGIN
		UPDATE Single_WaitingList WITH(ROWLOCK,UPDLOCK)
		SET IsCalculating = 2
		WHERE keyid = @keyId
	END
END


GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_SB_Job] TO [vnteam]
GO