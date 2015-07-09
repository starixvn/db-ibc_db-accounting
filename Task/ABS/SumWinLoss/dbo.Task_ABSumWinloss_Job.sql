ALTER PROCEDURE [dbo].[Task_ABSumWinloss_Job]
	/*
		Created:Johnson
		Date: 08Nov2011
		Task: Summary winloss ABD members
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120829@Johnson: Check data in ABSum_Winloss2 instead of ABSum_Winloss
		Parameters Explanation:
	*/ 
AS
SET NOCOUNT ON
	
	DECLARE @MaxWinlostDate_Sum DATETIME,
			@MaxWinlostDate_AB DATETIME, @ErrCode INT
	
	SELECT @MaxWinlostDate_Sum = MAX(winlostdate)
	FROM bodb02.dbo.sum_winloss WITH(NOLOCK)
	
	SELECT @MaxWinlostDate_AB = MAX(winlostdate) + 1
	FROM ABSum_Winloss WITH(NOLOCK)
	
	IF @MaxWinlostDate_AB IS NULL
		SELECT @MaxWinlostDate_AB = MIN(winlostdate)
		FROM bodb02.dbo.bettrans14 WITH(NOLOCK)
	
	WHILE (@MaxWinlostDate_AB <= @MaxWinlostDate_Sum)
	BEGIN
		EXEC [dbo].[Task_ABSumWinloss] @winlostdate = @MaxWinlostDate_AB, @ErrCode = @ErrCode OUTPUT
		
		IF @ErrCode > 0
		BEGIN
			RAISERROR('The process summary data failed.',16,1)
			RETURN
		END
		
		IF @ErrCode < 0 -- move bets not complete
			RETURN 
			
		SELECT @MaxWinlostDate_AB = @MaxWinlostDate_AB + 1 			
	END

GO
