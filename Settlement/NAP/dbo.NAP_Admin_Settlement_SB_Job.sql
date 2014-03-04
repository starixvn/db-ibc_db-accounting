CREATE PROCEDURE [NAP_Admin_Settlement_SB_Job]
AS
/*
	Created: 20130109@Kathy
	Task: select a match from list to perform calculating (Sportsbook)
	DB: DBTXN\bodb02
	
	Revisions:
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS (
			SELECT TOP 1 1
			FROM Single_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 1
			)
	BEGIN
		--- check Starttime if needed		
		RETURN
	END

	DECLARE @MatchId INT
		,@AdminId INT
		,@IP VARCHAR(15)
		,@Action VARCHAR(20)
		,@ErrCode INT
		,@ErrMsg NVARCHAR(200)
		,@sqlCommand NVARCHAR(max)
		,@keyId INT
		,@trycount INT

	SELECT @ErrCode = 0
		,@ErrMsg = ''

	SET @keyId = (
			SELECT TOP 1 keyid
			FROM dbo.Single_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 0
			ORDER BY TryCount
				,starttime
			)

	UPDATE TOP (1) dbo.Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
	SET IsCalculating = 1
		,@MatchId = matchid
		,@Adminid = AdminId
		,@IP = IP
		,@Action = Action
		,@sqlCommand = sqlCommand
	WHERE keyid = @keyId

	IF @@ROWCOUNT = 0 RETURN

	BEGIN TRY
		EXEC sys.sp_executesql @sqlCommand
			,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
			,@ErrMsg = @ErrMsg OUTPUT
			,@ErrCode = @ErrCode OUTPUT
	END TRY

	BEGIN CATCH
		SET @ErrMsg = @ErrMsg + ERROR_MESSAGE()
	END CATCH

	IF (ISNULL(@ErrCode, 0) <> 0 OR ISNULL(@ErrMsg, '') <> '') -- calculate failed set calculateing = 0 and back
			AND ISNULL(@ErrCode, 0) <> 1000006 --- 1000006: Betfair & Betdaq - Warning message
	BEGIN
		IF @ErrCode = 1000000 -- Check concurrent running
		BEGIN
			UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
			SET IsCalculating = 0
				,TryCount = TryCount + 1
			WHERE keyid = @keyId

			IF NOT EXISTS (
					SELECT 1
					FROM Settled_Message WITH (NOLOCK)
					WHERE AdminId = @AdminId AND MatchId = @MatchId AND Action = @Action AND Warning = @ErrMsg
					)
			BEGIN
				INSERT INTO Settled_Message (
					AdminId
					,MatchId
					,IP
					,Starttime
					,Action
					,Message
					,Warning
					)
				SELECT @AdminId
					,@MatchId
					,@IP
					,GETDATE()
					,@Action
					,NULL
					,@ErrMsg
			END

			SELECT @trycount = TryCount
			FROM Single_Calculate_Queue WITH (NOLOCK)
			WHERE keyid = @keyId

			IF @trycount = 3
			BEGIN
				UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
				SET IsCalculating = 3
				WHERE keyid = @keyId
			END
		END
		ELSE
		BEGIN
			UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
			SET IsCalculating = 0
				,TryCount = TryCount + 1
			WHERE keyid = @keyId

			IF NOT EXISTS (
					SELECT 1
					FROM Settled_Message WITH (NOLOCK)
					WHERE AdminId = @AdminId AND MatchId = @MatchId AND Action = @Action AND Message = @ErrMsg
					)
				INSERT INTO Settled_Message (
					AdminId
					,MatchId
					,IP
					,Starttime
					,Action
					,Message
					,Warning
					)
				SELECT @AdminId
					,@MatchId
					,@IP
					,GETDATE()
					,@Action
					,@ErrMsg
					,NULL

			SELECT @trycount = TryCount
			FROM Single_Calculate_Queue WITH (NOLOCK)
			WHERE keyid = @keyId

			IF @trycount = 3
			BEGIN
				UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
				SET IsCalculating = 3
				WHERE keyid = @keyId
			END
		END
	END
	ELSE
	BEGIN
		IF @ErrCode = 1000006
		BEGIN
			INSERT INTO Settled_Message (
					AdminId
					,MatchId
					,IP
					,Starttime
					,Action
					,Message
					,Warning
					)
				SELECT @AdminId
					,@MatchId
					,@IP
					,GETDATE()
					,@Action
					,@ErrMsg
					,NULL
		END
		UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating = 2
		WHERE keyid = @keyId
	END
END

GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_SB_Job] TO [vnteam] AS [dbo]
GO


