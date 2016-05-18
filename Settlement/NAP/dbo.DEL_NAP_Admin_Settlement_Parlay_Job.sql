USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Parlay_Job]    Script Date: 09/16/2015 13:45:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Parlay_Job]
AS
/*
	Created: 20140114@Kathy
	Task: select a match from list to perform calculating
	DB: DBTXN\bodb02
	Original: Admin_Settlement_Parlay_Job

	Revisions:
		- 20140502@Kathy: Add new columns execTime, duration for Parlay_Calculate_Queue
		- 20140505@Kathy: Re-run match if time of execution more than 5 minutes
		- 20140528@Kathy: rotate calculating sports in queue
		- 20150916@Kathy: update IsCalculating = 2 when settlement is done (remove NAP_Task_Calculate_Parlay job) [Redmine:#43566]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchid VARCHAR(2000)
		,@creator INT
		,@action VARCHAR(20)
		,@IP VARCHAR(15)
		,@ErrCode INT
		,@ErrMsg NVARCHAR(200)
		,@keyId INT
		,@ActionId INT
		--,@duration INT
		,@pre_Sporttype smallint 
	
	IF EXISTS (
			SELECT TOP 1 1
			FROM Parlay_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 1
			)
	BEGIN
		--- check Starttime if needed		
		RETURN
	END 

	-- get sporttype of previous calculated match
	SELECT TOP 1 @pre_Sporttype = m.SportType 
	FROM Parlay_Calculate_Queue p with(NOLOCK)
	INNER JOIN match m WITH(NOLOCK) ON m.matchid = p.matchid
	WHERE p.IsCalculating IN (2,3)
	ORDER BY p.execTime DESC

	-- giving priority to calcualate the match which has sporttype <> previous calculated match
	SET @keyId = (
					SELECT TOP 1 p.keyid
					FROM dbo.Parlay_Calculate_Queue p WITH (NOLOCK)
					INNER JOIN match m WITH(NOLOCK) ON m.matchid = p.matchid
					WHERE p.IsCalculating = 0
					ORDER BY CASE WHEN m.SportType = @pre_Sporttype THEN 1 ELSE 0 END
						,p.TryCount
						,p.starttime
						,p.keyid
				)	
	UPDATE TOP (1) dbo.Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
	SET IsCalculating = 1
		,execTime = GETDATE()
		,@matchID = matchid
		,@action = [action]
		,@creator = creator
		,@IP = IP
	WHERE keyid = @keyId

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

	IF ISNULL(@ErrCode, 0) <> 0 OR ISNULL(@ErrMsg, '') <> '' --- calculate failed set calculating = 0 back
	BEGIN
		UPDATE Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating = 0
			,TryCount = TryCount + 1
		WHERE keyid = @keyId

		IF NOT EXISTS (
				SELECT 1
				FROM Settled_Message WITH (NOLOCK)
				WHERE AdminId = @creator AND MatchId = @MatchId AND Action = @Action 
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
			SELECT @creator
				,@MatchId
				,@IP
				,GETDATE()
				,@Action
				,case when @ErrCode = 1000000 then NULL ELSE @ErrMsg END 
				,case when @ErrCode = 1000000 then @ErrMsg ELSE NULL END 
		END

		UPDATE Parlay_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating = 3
			,duration = DATEDIFF(ms, execTime, GETDATE())
		WHERE keyid = @keyId
		AND TryCount = 3
	END
	ELSE
	BEGIN
		UPDATE	dbo.Parlay_Calculate_Queue WITH (UPDLOCK, ROWLOCK)
			SET IsCalculating = 2,
				duration = DATEDIFF(ms,execTime,GETDATE())
		WHERE	matchid = @matchid 
				AND IsCalculating = 1
		
		IF @action = 'CAL'
			EXEC Acc_Set_ConfirmedActionParlay @matchids = @matchid
		ELSE
		BEGIN
			SELECT @ActionId = CASE 
					WHEN @Action = 'REFUND-HT' THEN 14
					WHEN @Action = 'REFUND-FT' THEN 15
					WHEN @Action = 'REFUND' THEN 16
					ELSE - 1
					END

			IF @ActionId <> - 1
				EXEC Acc_Set_ConfirmedAction @matchid = @matchid
					,@action = @ActionId
		END
	END
END


GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Parlay_Job] TO [vnteam] AS [dbo]