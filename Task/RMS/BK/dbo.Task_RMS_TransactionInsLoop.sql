ALTER PROCEDURE [dbo].[Task_RMS_TransactionInsLoop] 

AS
	/*
		Created: Johnson
		Date: 2012-10-25
		Task: Copy special member's tickets into rmTransaction
		DB: DB054.bodb_RMS
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @start DATETIME, @duration INT, @wait_time DATETIME
	
	SELECT @start = CURRENT_TIMESTAMP
	
	WHILE (1=1)
	BEGIN
		EXEC Task_RMS_TransactionIns
		
		IF (DATEDIFF(ss,@start,CURRENT_TIMESTAMP) > 52)
			BREAK
			
		SELECT @wait_time = CASE WHEN @duration < 1 THEN '00:00:02'
								WHEN @duration < 2 THEN '00:00:01'
								ELSE '00:00:00' END
		WAITFOR DELAY @wait_time
	END


GO
