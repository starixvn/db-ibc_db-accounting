ALTER PROCEDURE [dbo].[Task_RMS_SumWinloss_Archive_Job]
AS
	/*
		Created: Johnson
		Date: 2012-12-12
		Task: Archive RMS data
		DB: DBRMS/bodb_RMS
		
		Revisions:
			-20130717@Johnson: archive old data before balance up day
			- 20130814@Johnson: check data on rmSumWinloss_Old2
		Parameter's Explanation:	
	*/ 
BEGIN
	SET NOCOUNT ON
	DECLARE @maxDateSum_Old DATETIME,
			@balanceUpDay	DATETIME ,
			@errCode		INT,
			@errMsg			VARCHAR(1000) 
		
	SELECT	@maxDateSum_Old = MAX(winlostdate) + 1  ---Saturday 
	FROM	bodb_RMS.dbo.rmSumWinloss_Old2 WITH (NOLOCK)
	
	SELECT TOP 1 @balanceUpDay = winlostdate
	FROM bodb02.dbo.bettrans WITH(NOLOCK)
	WHERE bettype = 20000 AND matchid =0 AND custid = 3 
	
	WHILE (@maxDateSum_Old < @balanceUpDay) --@Johnson: fix archive data before BUDay
	BEGIN
		EXEC Task_RMS_SumWinloss_Archive @winlostdate = @maxDateSum_Old, @errCode = @ErrCode OUTPUT, @errMsg = @ErrMsg OUTPUT
		
		IF @ErrCode > 0
		BEGIN
			RAISERROR(@ErrMsg,16,1)
			RETURN
		END
		
		SELECT @maxDateSum_Old = @maxDateSum_Old + 1			
	END
END
