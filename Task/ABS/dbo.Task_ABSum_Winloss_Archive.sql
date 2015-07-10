ALTER PROCEDURE [dbo].[Task_ABSum_Winloss_Archive]

AS
	/*
		Created: Johnson
		Date: 2012-09-13
		Task: Archive ABSum_Winloss table
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON 
	DECLARE @from_date	DATETIME,
			@to_date	DATETIME
	
	SELECT @to_date = MIN(winlostdate)
	FROM bodb02.dbo.Sum_Winloss WITH(NOLOCK)
	
	SELECT @to_date = DATEADD(dd,-1,@to_date)
	
	SELECT @from_date = CONVERT(DATETIME,VValue)
	FROM DBTrans.bodb02.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName = 'ABMaxSum_Date'
	
	SELECT @from_date = DATEADD(dd,1,@from_date)
	
	IF EXISTS (SELECT top 1 1 FROM ABSum_Winloss WITH(NOLOCK) WHERE winlostdate BETWEEN @from_date AND @to_date)
	BEGIN
		INSERT INTO [dbo].[ABSum_winloss_Old]
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
		SELECT [winlostdate],[punterid],[leagueid],[matchid],[bettype],[currency],[statusid],[turnover],[comm],[winlost],[betcount]
		FROM dbo.ABSum_Winloss WITH(NOLOCK)
		WHERE winlostdate BETWEEN @from_date AND @to_date
		
		IF @@ERROR <> 0
			RETURN
		
		UPDATE DBTrans.bodb02.dbo.SystemSettings WITH(UPDLOCK,ROWLOCK)
		SET VValue = CONVERT(VARCHAR(10),@to_date,120)
		WHERE VName = 'ABMaxSum_Date'
	END
	
GO
