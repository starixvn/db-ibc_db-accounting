ALTER PROCEDURE [dbo].[Task_EAS_ClearLogin]
	
AS

/*
	Created:  20121116@Dan
	Task: EAS - Clear Login
	DB: DB052.bodb_EAS 
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM rmOn_User WITH (UPDLOCK,ROWLOCK)
WHERE	reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) 

GO
GRANT VIEW DEFINITION ON [dbo].[Task_EAS_ClearLogin] TO [vnteam] 