CREATE PROCEDURE [NAP_Admin_Settlement_Parlay_Job]
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

	IF EXISTS (
			SELECT TOP 1 1
			FROM Parlay_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 1
			)
	BEGIN
		--- check Starttime if needed		
		RETURN
	END

	DECLARE @matchid VARCHAR(2000)
		,@creator INT
		,@action VARCHAR(20)
		,@IP VARCHAR(15)
		,@ErrCode INT
		,@ErrMsg NVARCHAR(200)
		,@keyId INT
		,@trycount INT

	UPDATE TOP (1) dbo.Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
	SET IsCalculating = 1
		,@matchID = matchid
		,@action = [action]
		,@creator = creator
		,@IP = IP
		,@keyId = keyid
	WHERE matchid = (
			SELECT TOP 1 matchid
			FROM dbo.Parlay_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 0
			ORDER BY TryCount
				,starttime
			) AND IsCalculating = 0

	IF @@ROWCOUNT = 0 RETURN

	BEGIN TRY
		EXEC [NAP_Admin_Settlement_Parlay] @matchids = @matchid
			,@creator = @creator
			,@action = @action
			,@IP = @IP
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT
	END TRY

	BEGIN CATCH
		SET @ErrMsg = ERROR_MESSAGE()
	END CATCH

	IF ISNULL(@ErrCode, 0) <> 0 OR ISNULL(@ErrMsg, '') <> '' --- calculate failed set calculateing = 0 back
	BEGIN
		IF @ErrCode = 1000000
		BEGIN
			UPDATE Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
			SET IsCalculating = 0
				,TryCount = TryCount + 1
			WHERE keyid = @keyId

			IF NOT EXISTS (
					SELECT 1
					FROM Settled_Message WITH (NOLOCK)
					WHERE AdminId = @creator AND MatchId = @MatchId AND Action = @Action AND Warning = @ErrMsg
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
				SELECT @creator
					,@MatchId
					,@IP
					,GETDATE()
					,@Action
					,NULL
					,@ErrMsg
			END

			SELECT @trycount = TryCount
			FROM Parlay_Calculate_Queue WITH (NOLOCK)
			WHERE keyid = @keyId

			IF @trycount = 3
			BEGIN
				UPDATE Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
				SET IsCalculating = 3
				WHERE keyid = @keyId
			END
		END
		ELSE
		BEGIN
			UPDATE Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
			SET IsCalculating = 0
				,TryCount = TryCount + 1
			WHERE keyid = @keyId

			IF NOT EXISTS (
					SELECT 1
					FROM Settled_Message WITH (NOLOCK)
					WHERE AdminId = @creator AND MatchId = @MatchId AND Action = @Action AND Warning = @ErrMsg
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
				SELECT @creator
					,@MatchId
					,@IP
					,GETDATE()
					,@Action
					,@ErrMsg
					,NULL
			END

			SELECT @trycount = TryCount
			FROM Parlay_Calculate_Queue WITH (NOLOCK)
			WHERE keyid = @keyId

			IF @trycount = 3
			BEGIN
				UPDATE Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
				SET IsCalculating = 3
				WHERE keyid = @keyId
			END
		END
	END
END

GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Parlay_Job] TO [vnteam] AS [dbo]
GO


