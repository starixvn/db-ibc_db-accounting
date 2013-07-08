

ALTER PROCEDURE [dbo].[Admin_Settlement_Parlay_Job]
AS
/*
	Created: 20130625@Lukas
	Task: select a match from list to perform calculating
	DB: DBTXN\bodb02
	
	Revisions:
*/
BEGIN
	SET NOCOUNT ON 
	
	IF EXISTS (SELECT TOP 1 1 FROM Parlay_WaitingList WITH(NOLOCK) WHERE IsCalculating = 1)
	BEGIN
		--- check Starttime if needed		
		RETURN
	END
	
	DECLARE @matchids VARCHAR(2000),
			@creator INT,
			@action VARCHAR(10),
			@IP VARCHAR(15),
			@ErrCode INT,
			@ErrMsg NVARCHAR(200)

			
	
	UPDATE TOP (1) dbo.Parlay_WaitingList WITH(ROWLOCK, UPDLOCK)
	SET IsCalculating = 1, 		
		@matchIDs = matchid, 
		@action  = [action],
		@creator = creator,
		@IP		 = IP
	WHERE matchid = (	SELECT TOP 1 matchid 
						FROM dbo.Parlay_WaitingList WITH(NOLOCK)
						ORDER BY TryCount, starttime 
					)

	BEGIN TRY
		EXEC [Admin_Settlement_Parlay_xtest]
				@matchids	= @matchids,
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
		WHERE matchid = @matchids
		
		SET @ErrMsg = @ErrMsg + '-' + ERROR_MESSAGE()
		RAISERROR(@ErrMsg,16,1)
	END CATCH
	
	IF @ErrCode <> 0 OR @ErrMsg <> ''  --- calculate failed set calculateing = 0 back
	BEGIN
		UPDATE Parlay_WaitingList WITH(ROWLOCK,UPDLOCK)
		SET IsCalculating = 0,
			TryCount = TryCount + 1
		WHERE matchid = @matchids
	
	END
	
END
