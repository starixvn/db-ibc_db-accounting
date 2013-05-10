ALTER PROCEDURE [dbo].[Task_ABSum_Winloss_Del]

AS
	/*
		Created: Johnnson
		Date: 2012-09-14
		Task: Delete old summarry records
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON
	DECLARE @max_sumdate DATETIME
	
	SELECT @max_sumdate = CONVERT(DATETIME,VValue)
	FROM DBTrans.bodb02.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName = 'ABMaxSum_Date'

	DELETE ABSum_Winloss WITH(UPDLOCK,ROWLOCK) WHERE winlostdate <= @max_sumdate
GO
