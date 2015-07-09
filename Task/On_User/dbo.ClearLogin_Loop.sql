SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ClearLogin_Loop]
AS

/*
	Task:  
	DB: DB03.ON_USER
	Original SP: 	
	Revisions:
	Param's Explanation: 
	
*/
 SET NOCOUNT ON
 Declare @start datetime
 SELECT @start = CURRENT_TIMESTAMP

 WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)
 BEGIN
  EXEC ClearLogin
  WAITFOR DELAY '00:00:30'
 END
GO
GRANT VIEW DEFINITION ON [dbo].[ClearLogin_Loop] TO [vnteam]