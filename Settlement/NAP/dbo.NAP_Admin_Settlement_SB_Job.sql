ALTER PROCEDURE [NAP_Admin_Settlement_SB_Job]
AS
/*
	Created: 20130109@Kathy
	Task: select a match from list to perform calculating (Sportsbook)
	DB: DBTXN/bodb02
	
	Revisions:
		- 20140326@Kathy: Get match values from DBPRO
		- 20140502@Kathy: Add new column execTime, duration for Single_Calculate_Queue
		- 20140505@Kathy: Re-run match if time of execution more than 5 minutes
		- 20140507@Kathy: Add more settlement actions for Apollo site
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MatchId INT
		,@AdminId INT
		,@IP VARCHAR(15)
		,@Action VARCHAR(20)
		,@ErrCode INT
		,@ErrMsg NVARCHAR(200)
		,@sqlCommand NVARCHAR(max)
		,@keyId INT
		,@fth SMALLINT
		,@fta SMALLINT
		,@hth SMALLINT
		,@hta SMALLINT
		,@GoalRecord VARCHAR(50)
		,@BetStatus NVARCHAR(50)
		,@ActionId TINYINT
		,@duration INT

	SELECT TOP 1 @duration = DATEDIFF(ms, execTime, GETDATE())
		,@keyId = keyid
		,@matchid = matchid
	FROM Single_Calculate_Queue WITH (NOLOCK)
	WHERE IsCalculating = 1

	IF isnull(@duration, 0) > 300000
	BEGIN
		UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating = 0
		WHERE keyid = @keyId
	END
	ELSE IF EXISTS (
			SELECT TOP 1 1
			FROM Single_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 1
			)
	BEGIN
		--- check Starttime if needed		
		RETURN
	END

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
		,execTime = GETDATE()
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
		UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating = 0
			,TryCount = TryCount + 1
		WHERE keyid = @keyId

		IF NOT EXISTS (
				SELECT 1
				FROM Settled_Message WITH (NOLOCK)
				WHERE AdminId = @AdminId 
				AND MatchId = @MatchId 
				AND Action = @Action 
				AND @ErrMsg = CASE WHEN @ErrCode = 1000000 THEN Warning
									ELSE Message
								END 
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
				,case when @ErrCode = 1000000 then NULL ELSE @ErrMsg END 
				,case when @ErrCode = 1000000 then @ErrMsg ELSE NULL END 
		END

			UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
			SET IsCalculating = 3
				,duration = DATEDIFF(ms, execTime, GETDATE())
			WHERE keyid = @keyId
			and TryCount = 3
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
			,duration = DATEDIFF(ms, execTime, GETDATE())
		WHERE keyid = @keyId

		SELECT @ActionId = CASE 
				WHEN @Action = 'CAL-HT' THEN 2
				WHEN @Action = 'CAL-FT' THEN 3
				WHEN @Action = 'CAL' THEN 4
				WHEN @Action = 'CAL-FTFGLG' OR @Action = 'CAL-FTLG' THEN 1
				WHEN @Action = 'Refund-HT' THEN 11
				WHEN @Action = 'Refund-FT' THEN 12
				WHEN @Action = 'Refund' THEN 13
				WHEN @Action = 'Refund-FGLG' OR @Action = 'Refund-FTFGLG' THEN 17
				WHEN @Action = 'Refund-LG' OR @Action = 'Refund-FTLG' THEN 18
				WHEN @Action = 'UNDO' THEN 0
				ELSE - 1
				END
			,@fth = m.finalhomescore
			,@fta = m.finalawayscore
			,@hth = m.hthomescore
			,@hta = m.htawayscore
			,@GoalRecord = m.GoalRecord
			,@BetStatus = m.betstatus
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		IF @ActionId <> - 1
			EXEC Acc_Set_ConfirmedAction @matchid = @MatchId
				,@action = @ActionId
				,@fth = @fth
				,@fta = @fta
				,@hth = @hth
				,@hta = @hta
				,@goalrecord = @GoalRecord
				,@betstatus = @BetStatus
	END
END

GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_SB_Job] TO [vnteam] AS [dbo]
GO


