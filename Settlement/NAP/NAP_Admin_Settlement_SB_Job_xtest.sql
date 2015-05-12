USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_SB_Job]
AS
/*
	Created: 20130109@Kathy
	Task: select a match from list to perform calculating (Sportsbook)
	DB: DBTXN/bodb02
	
	Revisions:
		- 20140326@Kathy: Get match values from DBPRO
		- 20140502@Kathy: Add new column execTime, duration for Single_Calculate_Queue
		- 20140505@Kathy: Re-run match if time of execution more than 5 minutes
		- 20140507@Kathy: - Add more settlement actions
						  - Modify betstatus, goalrecord format before send to Apollo site
		- 20140528@Kathy: rotate calculating sports in queue
		- 20140825@Kathy: Support 1H FGLG (127) for Apollo [Redmine:#16276]
		- 20150511@Jamie: Sync PS for Betradar2 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MatchId	INT
		,@AdminId		INT
		,@IP			VARCHAR(15)
		,@Action		VARCHAR(20)
		,@ErrCode		INT
		,@ErrMsg		NVARCHAR(200)
		,@sqlCommand	NVARCHAR(max)
		,@keyId			INT
		,@fth 			SMALLINT
		,@fta 			SMALLINT
		,@hth 			SMALLINT
		,@hta 			SMALLINT
		,@GoalRecord	VARCHAR(50)
		,@BetStatus		NVARCHAR(50)
		,@ActionId		INT
		,@duration		INT
		,@pre_Sporttype TINYINT
		,@sporttype		INT 

	SELECT TOP 1 @duration	= DATEDIFF(ms, execTime, GETDATE())
		,@keyId				= keyid
		,@matchid			= matchid
	FROM Single_Calculate_Queue WITH (NOLOCK)
	WHERE IsCalculating = 1

	IF isnull(@duration, 0) > 300000 -- 5 minutes
	BEGIN
		UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating	= 0
			,execTime		= NULL
		WHERE keyid = @keyId
	END
	ELSE IF EXISTS (
			SELECT TOP 1 1
			FROM Single_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 1
			)
	BEGIN		
		RETURN
	END

	SELECT @ErrCode = 0
		,@ErrMsg	= ''

	-- get sporttype of previous calculated match
	SELECT TOP 1 @pre_Sporttype = SportType
	FROM Single_Calculate_Queue WITH (NOLOCK)
	WHERE IsCalculating IN (2, 3)
	ORDER BY execTime DESC

	-- giving priority to calcualate the match which has sporttype <> previous calculated match
	SET @keyId = (
			SELECT TOP 1 keyid
			FROM dbo.Single_Calculate_Queue WITH (NOLOCK)
			WHERE IsCalculating = 0
			ORDER BY CASE 
						WHEN SportType = @pre_Sporttype THEN 1
						ELSE 0
					 END
				,TryCount
				,starttime
				,keyid
			)

	UPDATE TOP (1) dbo.Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
	SET IsCalculating	= 1
		,execTime 		= GETDATE()
		,@MatchId 		= matchid
		,@Adminid 		= AdminId
		,@IP			= IP
		,@Action		= Action
		,@sqlCommand	= sqlCommand
		,@sporttype		= SportType
	WHERE keyid = @keyId

	IF @@ROWCOUNT = 0 RETURN

	BEGIN TRY
		EXEC sys.sp_executesql @sqlCommand
			,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
			,@ErrMsg	= @ErrMsg	OUTPUT
			,@ErrCode	= @ErrCode	OUTPUT
	END TRY

	BEGIN CATCH
		SET @ErrMsg = @ErrMsg + ERROR_MESSAGE()
	END CATCH

	IF (ISNULL(@ErrCode, 0) <> 0 OR ISNULL(@ErrMsg, '') <> '' ) -- calculate failed set calculating = 0 and back
		AND ISNULL(@ErrCode, 0) <> 1000006 --- 1000006: Betfair & Betdaq - Warning message
	BEGIN
		UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating	= 0
			,TryCount		= TryCount + 1
		WHERE keyid = @keyId

		IF NOT EXISTS (
				SELECT 1
				FROM Settled_Message WITH (NOLOCK)
				WHERE AdminId	= @AdminId
				AND MatchId		= @MatchId
				AND Action		= @Action
				AND @ErrMsg		= CASE 
									WHEN @ErrCode = 1000000 THEN Warning
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
				,CASE 
					WHEN @ErrCode = 1000000 THEN NULL
					ELSE @ErrMsg
					END
				,CASE 
					WHEN @ErrCode = 1000000 THEN @ErrMsg
					ELSE NULL
					END
		END

		UPDATE Single_Calculate_Queue WITH (ROWLOCK, UPDLOCK)
		SET IsCalculating	= 3
			,duration		= DATEDIFF(ms, execTime, GETDATE())
		WHERE keyid = @keyId
			AND TryCount = 3
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
		SET IsCalculating	= 2
			,duration		= DATEDIFF(ms, execTime, GETDATE())
		WHERE keyid = @keyId

		IF @sporttype = 1
		BEGIN
			BEGIN TRY
				EXEC DBPRO.bodb02.dbo.NAP_Task_BetRadar_SyncPS @MatchID = @MatchID
			END TRY 
			BEGIN CATCH 
				PRINT 'Synchronize failed!'  
			END CATCH  
		END 

		SELECT @ActionId	= CASE 
									WHEN @Action = 'CAL-HT'			THEN 2
									WHEN @Action = 'CAL-FT'			THEN 3
									WHEN @Action = 'CAL'			THEN 4
										--WHEN @Action = 'CAL-FGLG' OR @Action = 'CAL-FTFGLG' OR @Action = 'CAL-HTFGLG' THEN 1
									WHEN @Action = 'CAL-FTFGLG'		THEN 1
									WHEN @Action = 'CAL-HTFGLG'		THEN 7
									WHEN @Action = 'Refund-HT'		THEN 11
									WHEN @Action = 'Refund-FT'		THEN 12
									WHEN @Action = 'Refund'			THEN 13
										--WHEN @Action = 'Refund-FGLG' OR @Action = 'Refund-FTFGLG' THEN 17
										--WHEN @Action = 'Refund-LG' OR @Action = 'Refund-FTLG' THEN 18
									WHEN @Action = 'Refund-FTFGLG'	THEN 17
									WHEN @Action = 'Refund-FTLG'	THEN 18
									WHEN @Action = 'Refund-HTFGLG'	THEN 19
									WHEN @Action = 'Refund-HTLG'	THEN 21
									WHEN @Action = 'Refund-FGLG'	THEN 20 -- Refund all FGLG
									WHEN @Action = 'Refund-LG'		THEN 22 -- Refund all LG
									WHEN @Action = 'UNDO'			THEN 0
									ELSE - 1
							  END
			,@fth 			= m.finalhomescore
			,@fta 			= m.finalawayscore
			,@hth 			= m.hthomescore
			,@hta 			= m.htawayscore
			,@GoalRecord	= m.GoalRecord
			,@BetStatus		= m.betstatus
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		IF @ActionId <> - 1
		BEGIN
			EXEC Acc_Set_ConfirmedAction 
				@matchid 		= @MatchId
				,@action 		= @ActionId
				,@fth 			= @fth
				,@fta 			= @fta
				,@hth 			= @hth
				,@hta 			= @hta
				,@goalrecord	= @GoalRecord
				,@betstatus		= @BetStatus
		END
	END
END
