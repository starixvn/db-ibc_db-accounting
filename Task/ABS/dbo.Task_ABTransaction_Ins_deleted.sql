 ALTER PROCEDURE [dbo].[Task_ABTransaction_Ins]
	@NumberTicket	INT,
	@duration		INT = 0 OUTPUT
	/*
		Created: Johnson
		Date: 04Nov2011
		Task: Copy transactions of ABS member into ABTransaction
		DB: DB054.bodb_ABS
		
		Revisions:
			- 05Dec2011@Johnson: Change the way to copy transactions
		Parameters Explanation:
	*/
AS

SET NOCOUNT ON

	--DECLARE @fromTransID BIGINT, @toTransID BIGINT, @maxTransID BIGINT, @logTransID BIGINT, @ErrMsg VARCHAR(1000)
	
	DECLARE @start DATETIME, @end DATETIME, @maxtrans BIGINT
	
	SELECT @start = CURRENT_TIMESTAMP
	
	/*SELECT @fromTransID = CAST(VValue AS BIGINT)
	FROM DBTRANS.bodb02.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName = 'ABMaxTransID'
	
	IF @fromTransID IS NULL RETURN
	
	SELECT @maxTransID = ISNULL(MAX(TransID),0)
	FROM bettrans WITH(NOLOCK)
	WHERE TransID >= @fromTransID
	
	IF @maxTransID = 0 RETURN
	
	SELECT @toTransID = @fromTransID + @NumberTicket
	
	IF @toTransID > @maxTransID
		SELECT @toTransID = @maxTransID
	
	--waiting replicate new record
	IF @fromTransID = @toTransID
		WAITFOR DELAY '00:00:01'*/		
	SELECT @maxtrans = ISNULL(MAX(transid),0) FROM ABTransaction WITH(NOLOCK)
			  
	INSERT INTO ABTransaction (transid, punterid, custid)
	SELECT TOP 10000 b.transid , ab.punterid , ab.custid 
	FROM ABPunterCode p WITH(NOLOCK)
		INNER JOIN ABCustomer ab WITH(NOLOCK) ON p.punterid = ab.punterid
		INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON ab.custid = b.custid
		INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
	WHERE p.enabled = 1
		AND b.transid > @maxtrans		
		AND b.bettype IN (1,3,5,7,8,15)
		AND m.sporttype = 1
		
		
	--check to write the last transaction 
	/*IF @@ERROR > 0
	BEGIN
		SELECT @logTransID = ISNULL(MAX(TransID),0) + 1
		FROM ABTransaction WITH(NOLOCK)
		WHERE transid >= @fromTransID
		
		SET @ErrMsg = 'The process insert transactions into ABTransaction failed.'
		RAISERROR(@ErrMsg,16,1)
		
		IF @logTransID <= @fromTransID
			RETURN
	END
	ELSE 
		SELECT @logTransID = @toTransID + 1
	
	UPDATE DBTrans.bodb02.dbo.SystemSettings WITH(ROWLOCK,UPDLOCK)
	SET VValue = CAST(@logTransID AS VARCHAR(20))
	WHERE VName = 'ABMaxTransID'*/
	
	SELECT @end = CURRENT_TIMESTAMP
	
	SELECT @duration = DATEDIFF(ss,@start,@end)
	
GO
GRANT VIEW DEFINITION ON [dbo].[Task_ABTransaction_Ins] TO [vnteam]