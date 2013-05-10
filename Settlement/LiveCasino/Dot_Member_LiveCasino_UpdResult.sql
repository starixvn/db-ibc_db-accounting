ALTER PROCEDURE [dbo].[Dot_Member_LiveCasino_UpdResult]
	@matchid int,
	@Banker int = NULL ,
	@Player int,
	@resultdata nvarchar(50) = NULL,
	@Updresult bit = 0 output	
AS
/*
Created: Jack Chang
Task : Input result data in match table, calling from live casino by [Dot_Casino] user
DB: DB02.BODB02
--20120907@Victor: add @Banker int = NULL
*/
BEGIN
	SET NOCOUNT ON;	
	
	IF EXISTS (SELECT matchid FROM dbo.match with (nolock) WHERE matchid = @matchid and sporttype = 162)
	BEGIN
		UPDATE match with (ROWLOCK, UPDLOCK)
		SET finalhomescore = @Player,
			finalawayscore = @Banker,
			betstatus = @resultdata
		WHERE matchid = @matchid and sporttype = 162	

		SET @Updresult = 1
	END
	
	DECLARE @LogData as nvarchar(200) 
	SET @LogData = 'UpdateResult for Live Casino ' 
		+ ' matchid:' + cast(isnull(@matchid,0) as nvarchar(10))		
		+ ' banker:'+ cast(isnull(@Banker,0) as nvarchar(10)) 
		+ ' player:'+ cast(isnull(@Player,0) as nvarchar(10)) 
		+ ' result:' + @resultdata 
	EXEC dbo.WriteLog_UserLog 162, @LogData

END

GO
GRANT EXECUTE ON [dbo].[Dot_Member_LiveCasino_UpdResult] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Member_LiveCasino_UpdResult] TO [Dot_Casino]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Member_LiveCasino_UpdResult] TO [vnteam]