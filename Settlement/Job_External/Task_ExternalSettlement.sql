ALTER PROCEDURE [dbo].[Task_ExternalSettlement]
AS
/*
	Created by:Lukas
	Date:20110112
	Task: execute Settlement (job)
	DB: DBAGE/BODB02; DBEXT/BODB02
	
	Revisions:
		- 20110912@Lukas: Apply this SP for DB053
		- 20121109@Jamie: Check total tickets between the current server and DBTRANS before executing the command. 
		- 20121120@Lukas: correct betcount in case of settle abandoned matches
		- 20121122@Jamie: Update new range for delay execution - tickets not match 
		- 20130708@Jamie: Update statusID = 98 in case SQL Command NULL 

	Param explanation:				
		StatusID & Status
			+ 0		Waiting	
			+ 1		Running
			+ 2		Failed & retry 1
			+ 3		Failed & retry 2
			+ 4		Failed & retry 3
			
			+ 11	Failed & skip "Running" step 
			+ 12	Failed & delay execution 1 
			+ 13	Failed & delay execution 2 
			+ 14	Failed & delay execution 3 
				
			+ 98	Failed & waiting for notification
			+ 99	Failed & notified
			+ 100	Completed (successful)
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @sql			NVARCHAR(MAX),
			@execID			INT,
			@startTime		DATETIME,
			@endTime		DATETIME,
			@allowedDate	DATETIME,
			@statusID		INT,
			@matchID		INT,
			@bettype		INT,
			@betCount		INT,
			@betCount_DB	INT,
			@errMesg		VARCHAR(1000)

	SELECT TOP 1	@sql = SQLCommand, 
					@execID = execID, 
					@statusID = statusID,
					@matchID = MatchID,
					@bettype = Bettype, 
					@betCount = BetCount 
	FROM	Acc_ExternalSettlement WITH(NOLOCK)
	WHERE	(	StatusID <=10
				OR (StatusID BETWEEN 11 AND 14 AND AllowedDate < GETDATE())
			)
			AND StatusID <> 1  -- Running
	ORDER BY statusID, execID
	
	IF @sql IS NULL
	BEGIN
		UPDATE	Acc_ExternalSettlement WITH (UPDLOCK,ROWLOCK)
		SET		 StatusID		= 98	
				,[Status]		= 'Failed & waiting for notification'
				,ExecutedDate	= GETDATE()
		WHERE	execID = @execID
		RETURN 
	END

	IF @bettype >= 1201  --Apply for bettype without checking the total tickets 
	BEGIN 
		SELECT	@betCount_DB = COUNT(1)
		FROM	bettrans WITH (NOLOCK)
		WHERE	matchid = @matchID
				AND bettype = @bettype 
		
		IF (@betCount_DB <> @betCount) 
		BEGIN
			SELECT	@errMesg='WARNING External settlement: The number of tickets on this server does not match with DBTRANS!'
								+ ' MatchID:' + CAST(@matchID AS VARCHAR(50)) 
								+ ' Bettype:' + CAST(@bettype AS VARCHAR(50)) 
								+ ' DBTRANS:' + CAST(@betCount AS VARCHAR(50)) 
								+ ' The current Server:' + CAST(@betCount_DB AS VARCHAR(50))
								+ ' StatusID:' + CAST(@statusID AS VARCHAR(10))
			
			--- UPDATE STATUS
			UPDATE Acc_ExternalSettlement WITH(ROWLOCK,UPDLOCK)
			SET StatusID		= CASE	WHEN @statusID = 0	THEN 11		-- Failed & skip "Running" step 
										WHEN @statusID = 11 THEN 12		-- Failed & delay execution 1 
										WHEN @statusID = 12 THEN 13		-- Failed & delay execution 2 
										WHEN @statusID = 13 THEN 14		-- Failed & delay execution 3 						
										ELSE 98 END,					-- Failed & waiting for notification
										
				Status			= CASE	WHEN @statusID =0   THEN 'Failed & skip "Running" step' 
										WHEN @statusID = 11 THEN 'Failed & delay execution 1'		
										WHEN @statusID = 12 THEN 'Failed & delay execution 2'		
										WHEN @statusID = 13 THEN 'Failed & delay execution 3'							
										ELSE 'Failed & waiting for notification' END,					
										
				ExecutedDate	= CASE	WHEN @statusID = 0 THEN GETDATE()
										ELSE ExecutedDate END,
																
				AllowedDate		= CASE  WHEN @statusID = 0  THEN DATEADD(MINUTE,1,GETDATE())		--Delay in 1 minute	
										WHEN @statusID = 11 THEN DATEADD(MINUTE,3,GETDATE())
										WHEN @statusID = 12 THEN DATEADD(MINUTE,5,GETDATE())
										WHEN @statusID = 13 THEN DATEADD(MINUTE,7,GETDATE()) 
										ELSE AllowedDate END
			WHERE execID = @execID
		
			RAISERROR(@errMesg,16,1) 
			
			RETURN			 
		END
	END

	--- UPDATE STATUS
	UPDATE Acc_ExternalSettlement WITH(ROWLOCK,UPDLOCK)
	SET StatusID		= 1,
		ExecutedDate	= GETDATE(),
		Status			= 'running'
	WHERE execID = @execID

	BEGIN TRY

		--SET @startTime = GETDATE()

		EXEC sp_executesql @sql

		--SET @endTime = GETDATE()

		IF @@ERROR = 0
		BEGIN
			UPDATE Acc_ExternalSettlement WITH(ROWLOCK,UPDLOCK)
			SET StatusID	= 100, --- successed	
				Duration	= DATEDIFF(ms,ExecutedDate,GETDATE()),
				Status		= 'Completed'
			WHERE 
				execID = @execID
		END

	END TRY

	BEGIN CATCH
		UPDATE Acc_ExternalSettlement WITH(ROWLOCK,UPDLOCK)
		SET StatusID	= CASE	WHEN @statusID  = 0 THEN 2  -- Failed & retry 1
								WHEN @statusID  = 2 THEN 3	-- Failed & retry 2
								WHEN @statusID  = 3 THEN 4  -- Failed & retry 2
								ELSE 98 END,				-- Failed & waiting for notification
			Duration	= DATEDIFF(ms,ExecutedDate,GETDATE()),
			Status		= CASE	WHEN @statusID  = 0 THEN 'Failed & retry 1'  -- put to retry 1
								WHEN @statusID  = 2 THEN 'Failed & retry 2'	 -- put to retry 2
								WHEN @statusID  = 3 THEN 'Failed & retry 3'	 -- put to retry 2						
								ELSE 'Failed & waiting for notification' END
		WHERE 
			execID = @execID
	END CATCH
END

GO

GRANT VIEW DEFINITION ON [dbo].[Task_ExternalSettlement] TO [vnteam]
