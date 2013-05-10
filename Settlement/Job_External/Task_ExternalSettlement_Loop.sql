 
ALTER PROCEDURE [dbo].[Task_ExternalSettlement_Loop]
AS
/*
	Created by:Lukas
	Date:20110112
	Task: execute Settlement (job)
	DB: DB052.BODB02, DB053.BODB02
	
	Revisions:
		- 20110912@Lukas: apply for DB053
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @start DATETIME
	SELECT @start = CURRENT_TIMESTAMP

	WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 30)
	BEGIN
		EXEC [Task_ExternalSettlement]
		WAITFOR DELAY '00:00:01'
	END
END


GO
GRANT VIEW DEFINITION ON [dbo].[Task_ExternalSettlement_Loop] TO [vnteam]
