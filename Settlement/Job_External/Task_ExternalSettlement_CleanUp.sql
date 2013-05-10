ALTER PROCEDURE [dbo].[Task_ExternalSettlement_CleanUp]
AS
/*
	Created by:Lukas
	Date:20110118
	Task: execute Settlement (job)
	DB: DB053.BODB02, DB053.BODB02
	
	Revisions:
		- 20110912@Lukas: apply for DB053
		- 20120608@Jamie: Apply for DB054
		- 20120904@Lukas: Change statusID when clear data
		- 20121109@Jamie: Add betcount in ExtLog 
		- 20121122@Jamie: Change the statusID for Completed to 100
	Param explanation:
		- ServerID column in Acc_ExternalSettlement_Log table:
			+ 1: DB052
			+ 2: Db053
			+ 3: DB054
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @movedDate	DATETIME,
			@LogDate	DATETIME,	
			@errmsg		VARCHAR(200)

	SELECT	@movedDate = DATEADD(d,-1,CONVERT(CHAR(12),GETDATE(), 101)),
			@LogDate = GETDATE()

	IF @@SERVERNAME = 'DB052'
	BEGIN
		INSERT INTO [bodb_customerLog].[dbo].[Acc_ExternalSettlement_Log](LogDate, execID, SPName, SQLCommand, CreatedDate, ExecutedDate, MatchID, Bettype, Duration, ServerID, ServerName, BetCount,AllowedDate)
														SELECT  @LogDate, execID, SPName, SQLCommand, CreatedDate, ExecutedDate, MatchID, Bettype, Duration, 1, 'DB052',BetCount,AllowedDate 
														FROM [dbo].[Acc_ExternalSettlement]
														WHERE	StatusID = 100
																AND 
																CreatedDate < @movedDate
		IF @@ERROR <> 0
			RETURN
	END
	IF @@SERVERNAME IN ( 'DB053')
	BEGIN
		INSERT INTO DBLOG.[bodb_customerLog].[dbo].[Acc_ExternalSettlement_Log](LogDate, execID, SPName, SQLCommand, CreatedDate, ExecutedDate, MatchID, Bettype, Duration, ServerID, ServerName,BetCount,AllowedDate)
														SELECT  @LogDate, execID, SPName, SQLCommand, CreatedDate, ExecutedDate, MatchID, Bettype, Duration, 2, 'DB053', BetCount,AllowedDate 
														FROM [dbo].[Acc_ExternalSettlement]
														WHERE	StatusID = 100
																AND 
																CreatedDate < @movedDate
		IF @@ERROR <> 0
			RETURN
	END
	
	IF @@SERVERNAME IN ( 'DB054')
	BEGIN
		INSERT INTO DBLOG.[bodb_customerLog].[dbo].[Acc_ExternalSettlement_Log](LogDate, execID, SPName, SQLCommand, CreatedDate, ExecutedDate, MatchID, Bettype, Duration, ServerID, ServerName, BetCount,AllowedDate)
														SELECT  @LogDate, execID, SPName, SQLCommand, CreatedDate, ExecutedDate, MatchID, Bettype, Duration, 3, 'DB054', BetCount,AllowedDate 
														FROM [dbo].[Acc_ExternalSettlement]
														WHERE	StatusID = 100
																AND 
																CreatedDate < @movedDate
		IF @@ERROR <> 0
			RETURN
	END
	
	DELETE FROM [dbo].[Acc_ExternalSettlement] WITH(ROWLOCK,UPDLOCK)
	WHERE 
		StatusID = 100
		AND
		CreatedDate < @movedDate

	IF @@ERROR <> 0
	BEGIN
		SET @errmsg  = 'Cannot delete data after moving the data to log (moved date: ' + CONVERT(VARCHAR(20),@movedDate) + ')'
		RAISERROR(@errmsg,16,1)
	END
END


 

GO
GRANT VIEW DEFINITION ON [dbo].[Task_ExternalSettlement_CleanUp] TO [vnteam] 
