 ALTER PROCEDURE [dbo].[Task_ABTransaction_InsLoop]
	/*
		Created: Johnson
		Date: 07Nov2011
		Task: Copy ABD member's transactions into ABTransaction
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Parameters Explanation:
	*/
AS
SET NOCOUNT ON

	DECLARE @start DATETIME, @duration INT, @wait_time DATETIME
	
	SELECT @start = CURRENT_TIMESTAMP
	
	WHILE (1=1)
	BEGIN
		EXEC [Task_ABTransaction_Ins] @numberTicket = 1000000, @duration =@duration OUTPUT
		
		IF (DATEDIFF(ss,@start,CURRENT_TIMESTAMP) > 52)
			BREAK
			
		SELECT @wait_time = CASE WHEN @duration < 1 THEN '00:00:02'
								WHEN @duration < 2 THEN '00:00:01'
								ELSE '00:00:00' END
		WAITFOR DELAY @wait_time
	END
	
GO
GRANT VIEW DEFINITION ON [dbo].[Task_ABTransaction_InsLoop] TO [vnteam]