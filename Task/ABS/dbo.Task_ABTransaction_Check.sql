 ALTER PROCEDURE [dbo].[Task_ABTransaction_Check]
AS
	/*
		Created: Johnson
		Date: 15Nov2011
		Task: Check missed punter's transactions
		DB: DDB052.BODB02
		
		Revisions:
		
		Parameters Explanation:
	*/
BEGIN 
	SET NOCOUNT ON
	
	DECLARE @fromTransID BIGINT, @toTransID BIGINT
	
	SELECT @fromTransID = CONVERT(BIGINT,VValue)
	FROM DBTrans.bodb02.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName = 'ABCheckTransID'
	
	SET @fromTransID = ISNULL(@fromTransID,0)
	
	SELECT @toTransID = CONVERT(BIGINT, VValue)
	FROM DBTrans.bodb02.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName = 'ABMaxTransID'
	
	IF @toTransID IS NULL 
		RETURN
	
	IF @fromTransID = @toTransID
		RETURN
	
	INSERT INTO ABTransaction (transid , punterid, custid)
	SELECT b.transid, c.punterid, c.custid
	FROM ABPunterCode p WITH(NOLOCK) 
		INNER JOIN ABCustomer c WITH(NOLOCK) ON p.punterid = c.punterid
		INNER JOIN bettrans b WITH(NOLOCK) ON c.custid = b.custid 
	WHERE p.enabled = 1
		 AND b.transid BETWEEN @fromTransID AND @toTransID
		 AND b.bettype IN (1,3,7,8)
		 AND b.transid NOT IN (SELECT ab.transid FROM ABTransaction ab WITH(NOLOCK) WHERE ab.transid BETWEEN @fromTransID AND @toTransID)
		 AND b.transdate >= c.updatedtime
		 
	IF @@ERROR > 0
		RETURN
	
	UPDATE DBTrans.bodb02.dbo.SystemSettings WITH(UPDLOCK, ROWLOCK)
	SET VValue = CONVERT(VARCHAR(20),@toTransID)
	WHERE VName = 'ABCheckTransID' 
	
END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_ABTransaction_Check] TO [vnteam]