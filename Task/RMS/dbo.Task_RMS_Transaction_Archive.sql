ALTER PROCEDURE [dbo].[Task_RMS_Transaction_Archive]
AS
	/*
		Created: Johnson	
		Date: 2012-12-12
		Task: Archive RMS's transactions
		DB: DB054.bodb_RMS
		
		Revisions:
			- 20130124@Jamie: Copy tickets by batch
		
		Paramter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON

	DECLARE @from_transid	BIGINT,
			@to_transid		BIGINT,
			@maxTransID14	BIGINT

	SELECT	@from_transid = ISNULL(CONVERT(BIGINT,VValue),0) + 1
	FROM	rmSettings WITH(NOLOCK)
	WHERE	VName = 'rmTransaction'

	SELECT TOP 1 @maxTransID14 = transid
	FROM	bodb02.dbo.bettrans14 WITH(NOLOCK)
	WHERE	transid >= @from_transid
	ORDER BY transid DESC

	SELECT @maxTransID14 MaxTransID14

	IF @maxTransID14 IS NULL RETURN 

	CREATE TABLE #tmpTrans(	TransID BIGINT)	

	DECLARE	 @rowCnt		INT
			,@errCode		INT
			,@errMesg		VARCHAR(500)
			,@maxtmpTransID	BIGINT
			
	SELECT	 @rowCnt		= 0
			,@errCode		= 0
			,@errMesg		= ''
			,@maxtmpTransID	= 0
			
		-- Copy tickets from rmTransaction to rmTransaction_BK

	WHILE(1=1)
	BEGIN
		INSERT INTO [bodb_RMS].[dbo].[rmTransaction_BK]
			   ([transid]
			   ,[refno]
			   ,[custid]
			   ,[combo])
		OUTPUT INSERTED.TransID INTO #tmpTrans
		SELECT TOP 30000
				[transid]
			   ,[refno]
			   ,[custid]
			   ,[combo]
		 FROM	rmTransaction WITH(NOLOCK)
		 WHERE	transid BETWEEN @from_transid AND @maxTransID14
		 
		 SELECT  @rowcnt	= @@ROWCOUNT
				,@errCode	= @@ERROR
	     
		 IF @errCode <> 0 
		 BEGIN
			SELECT	@errMesg = 'FAILED: Archiving rmTransaction unsucessful!'	
			RAISERROR(@errMesg, 16,1)
			RETURN 
	     
		 END    
	     
		 IF @rowCnt <> 0 
		 BEGIN
			IF @rowCnt < 30000
			BEGIN
				SELECT	@to_transid = @maxTransID14
				UPDATE	rmSettings WITH(UPDLOCK,ROWLOCK)
				SET		VValue = CAST(@to_transid AS VARCHAR(50))
				WHERE	VName = 'rmTransaction'
				
				DROP TABLE #tmpTrans
				
				BREAK
			END
			
			SELECT	@maxTmpTransID = MAX(TransID)
			FROM	#tmpTrans WITH (NOLOCK) 
			
			SELECT	@to_transid = @maxtmpTransID
			
			SELECT	@from_transid = @to_transid + 1 
			
			UPDATE rmSettings WITH(UPDLOCK,ROWLOCK)
			SET VValue = CAST(@to_transid AS VARCHAR(50))
			WHERE VName = 'rmTransaction'
			
			TRUNCATE TABLE #tmpTrans
	     
		 END      	 
	END

-- END :Copy tickets from rmTransaction to rmTransaction_BK

	---- DELETE Old rmTransaction 

	--DECLARE	 @maxTransID_Del	BIGINT
	--		,@minRMTrans		BIGINT

	--SELECT	@maxTransID_Del = ISNULL(CONVERT(BIGINT,VValue),0) 
	--FROM	rmSettings WITH(NOLOCK)
	--WHERE	VName = 'rmTransaction'

	--SELECT	@minRMTrans = MIN(TransID)
	--FROM	rmTransaction WITH (NOLOCK)

	--IF	@minRMTrans > @maxTransID_Del RETURN

	--WHILE (1=1)
	--BEGIN
	--	DELETE TOP (30000)
	--	FROM	rmTransaction WITH (ROWLOCK)
	--	WHERE	transid <= @maxTransID_Del
		
	--	IF @@ROWCOUNT < 30000
	--		BREAK

	--END


	---- END: DELETE Old rmTransaction  
END
GO 
