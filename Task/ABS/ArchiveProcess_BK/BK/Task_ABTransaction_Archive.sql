ALTER PROCEDURE dbo.Task_ABTransaction_Archive 
@errCode INT = 0 OUTPUT,
@errMesg VARCHAR(1000) ='' OUTPUT
AS 
/*	Created by: Jamie 
	Date: 2012-11-15
	Task: Archive [ABTransaction] to [ABTransaction_BK] 
	DB: DB052.bodb_ABS 
	
	Revisions: 
	

*/
SET NOCOUNT ON 
IF EXISTS (
	SELECT	TOP 1 1  
	FROM	dbo.ABTransaction t WITH (NOLOCK) 
			LEFT JOIN bodb02.dbo.bettrans b WITH (NOLOCK) ON t.transID = b.transID 
			LEFT JOIN bodb02.dbo.bettrans14 b14 WITH (NOLOCK) ON t.transID = b14.transID 
	WHERE	t.transID IS NOT NULL
			AND b.transID IS NULL
			AND b14.transID IS NULL 
)
BEGIN 
	DECLARE	@rowCount	BIGINT

	CREATE TABLE #tmpABTrans(TransID BIGINT PRIMARY KEY, IsCopied BIT)
	
	INSERT INTO #tmpABTrans(TransID, isCopied)
	SELECT	t.[transid],0
	FROM	[bodb_ABS].[dbo].[ABTransaction] t WITH (NOLOCK) 
			LEFT JOIN bodb02.dbo.bettrans b WITH (NOLOCK) ON t.transID = b.transID 
			LEFT JOIN bodb02.dbo.bettrans14 b14 WITH (NOLOCK) ON t.transID = b14.transID 
	WHERE	t.transID IS NOT NULL
			AND b.transID IS NULL
			AND b14.transID IS NULL 
	
	WHILE (1=1)
	BEGIN 
		UPDATE TOP (10000) #tmpABTrans WITH (ROWLOCK)
		SET		isCopied = 1
		WHERE	isCopied = 0 
		
		SELECT	@rowCount = @@ROWCOUNT 	
			
		INSERT INTO [bodb_ABS].[dbo].[ABTransaction_BK]
				   ([transid]
				   ,[punterid]
				   ,[custid]
				   ,[remark]
				   ,[matchid]
				   ,[bettype])
		SELECT	[transid]
			   ,[punterid]
			   ,[custid]
			   ,[remark]
			   ,[matchid]
			   ,[bettype]
		FROM	[bodb_ABS].[dbo].[ABTransaction] WITH (NOLOCK) 
		WHERE	transid IN (
					SELECT	transid FROM #tmpABTrans WITH (NOLOCK) WHERE isCopied = 1 
				)	
		
		IF @@ERROR = 0 
		BEGIN
			DELETE FROM [bodb_ABS].[dbo].[ABTransaction] WITH (ROWLOCK) 
			WHERE	TransID IN (
						SELECT	transid FROM #tmpABTrans WITH (NOLOCK) WHERE isCopied = 1 
					)	
			DELETE FROM #tmpABTrans WITH (ROWLOCK) WHERE isCopied = 1 
		END
		ELSE 
		BEGIN
			SELECT	@errCode = 200,
					@errMesg = 'FAILED: Archiving the transaction(s).'
			RETURN
		END 
		
		IF @rowCount < 10000 BREAK 
				
	END 
	
	DROP TABLE #tmpABTrans
END 


