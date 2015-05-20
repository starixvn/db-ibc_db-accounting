ALTER PROCEDURE dbo.Task_ABSumWinloss_Archive 
@winlostdate	DATETIME,
@errCode		INT = 0 OUTPUT,
@errMesg		VARCHAR(1000) = '' OUTPUT

AS 
/*	Created by: Jamie 
	Date: 2012-11-15
	Task: Archive [ABSum_winloss] to [[ABSum_winloss_Old]] 
	DB: DB052.bodb_ABS 
	
	Revisions: 
	

*/
SET NOCOUNT ON 
BEGIN 
	INSERT INTO [bodb_ABS].[dbo].[ABSum_winloss_Old]
			   ([winlostdate]
			   ,[punterid]
			   ,[leagueid]
			   ,[matchid]
			   ,[bettype]
			   ,[currency]
			   ,[statusid]
			   ,[turnover]
			   ,[comm]
			   ,[winlost]
			   ,[betcount])
	           
	SELECT	[winlostdate]
		   ,[punterid]
		   ,[leagueid]
		   ,[matchid]
		   ,[bettype]
		   ,[currency]
		   ,[statusid]
		   ,[turnover]
		   ,[comm]
		   ,[winlost]
		   ,[betcount]
	FROM	[bodb_ABS].[dbo].[ABSum_winloss] WITH (NOLOCK) 
	WHERE	winlostdate = @winlostdate
	
	IF @@ERROR = 0 
	BEGIN
		DELETE FROM [bodb_ABS].[dbo].[ABSum_winloss] WITH (ROWLOCK)
		WHERE	winlostdate = @winlostdate 
	END
	ELSE
	BEGIN
		SELECT	@errCode = 300,
				@errMesg = 'FAILED: Archiving Sum Win/Loss.'
		RETURN
	END
END 