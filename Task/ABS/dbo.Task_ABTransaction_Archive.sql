 ALTER PROCEDURE [dbo].[Task_ABTransaction_Archive]

 AS	
	/*
		Created: Johnson
		Date: 2012-09-13
		Task: Archive transactions for ABS
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Parameters Explanation:
	*/
 SET NOCOUNT ON
	DECLARE @from_transid	BIGINT,
			@to_transid		BIGINT
	
	SELECT @from_TransID = ISNULL(CONVERT(BIGINT, VValue),0) + 1
	FROM DBTrans.bodb02.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName = 'ABMaxTransID_BK'
	
	SELECT @to_transid = MIN(transid) - 1
	FROM bodb02.dbo.bettrans14 WITH(NOLOCK)
			
	IF EXISTS (SELECT top 1 1 FROM ABTransaction WITH(NOLOCK) WHERE transid BETWEEN @from_transid AND @to_transid)
	BEGIN
		INSERT INTO [dbo].[ABTransaction_BK]
           ([transid]
           ,[punterid]
           ,[custid]
           ,[remark])
		SELECT [transid],[punterid],[custid],[remark]
		FROM [dbo].[ABTransaction] WITH(NOLOCK)
		WHERE transid BETWEEN @from_transid AND @to_transid
		
		IF @@ERROR <>0
			RETURN
		
		INSERT INTO [dbo].[ABMatch_Remark_BK]
           ([matchid]
           ,[bettype]
           ,[hdp]
           ,[odds]
           ,[transid])
		SELECT [matchid],[bettype],[hdp],[odds],[transid]
		FROM [dbo].[ABMatch_Remark] WITH(NOLOCK)
		WHERE transid BETWEEN @from_transid AND @to_transid
		
		UPDATE DBTrans.bodb02.dbo.SystemSettings WITH(UPDLOCK,ROWLOCK)
		SET VValue = @to_transid
		WHERE VName = 'ABMaxTransID_BK'
	END
	
	
 GO
 