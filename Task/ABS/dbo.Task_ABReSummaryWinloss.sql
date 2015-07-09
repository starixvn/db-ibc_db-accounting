ALTER PROCEDURE [dbo].[Task_ABReSummaryWinloss]
	@winlostdate DATETIME
AS
	/*
		Created: Johnson
		Date: 18Nov2011
		DB: DB054.bodb_ABS
		Task: Re-summary winlost for ABD
		
		Revisions:
		
		Parameters Explanation:
	*/ 
SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM bodb02.dbo.Sum_Winloss WITH(NOLOCK) WHERE winlostdate = @winlostdate)
	BEGIN
		DELETE ABSum_Winloss WHERE winlostdate = @winlostdate
		
		EXEC [Task_DailyABSummaryWinloss] @winlostdate
	END
	ELSE
	BEGIN
		PRINT('Your input date not in sum_winloss table.')		
	END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_ABReSummaryWinloss] TO [vnteam]