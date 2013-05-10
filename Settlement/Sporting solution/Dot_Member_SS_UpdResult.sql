ALTER PROCEDURE [dbo].[Dot_Member_SS_UpdResult]
	@matchid int,
	@betstatus	nvarchar(50),
	@Updresult bit = 0 output	
AS
/*
Created: VictorSu
Task : Input result data in match table, calling from Sporting Solution api
DB: DB02.BODB02
*/
BEGIN
	SET NOCOUNT ON;	
	
	IF EXISTS (SELECT matchid FROM dbo.match with (nolock) WHERE matchid = @matchid  )
	BEGIN
		UPDATE match with (ROWLOCK, UPDLOCK)
		SET betstatus = @betstatus
		WHERE matchid = @matchid 

		SET @Updresult = 1
	END
	
	DECLARE @LogData as nvarchar(200) 
	SET @LogData = 'UpdateResult for Sporting Solution ' 
		+ ' matchid:' + cast(isnull(@matchid,0) as nvarchar(10))		
		+ ' betstatus :' + @betstatus 
	EXEC dbo.WriteLog_UserLog 111, @LogData

END
 