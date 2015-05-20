ALTER PROCEDURE [dbo].[Task_ABTransaction_Del]

AS
	/*
		Created: Johnson
		Date: 2012-09-14
		Task: Delete old ABS transactions out ABTransaction table
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @max_transidBK BIGINT
	
	SELECT @max_transidBK = ISNULL(CONVERT(BIGINT, VValue),0) + 1
	FROM DBTrans.bodb02.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName = 'ABMaxTransID_BK'
	
	DELETE ABTransaction WITH(UPDLOCK,ROWLOCK)
	WHERE transid <= @max_transidBK
	
	DELETE ABMatch_Remark WITH(UPDLOCK,ROWLOCK)
	WHERE transid <= @max_transidBK
GO 