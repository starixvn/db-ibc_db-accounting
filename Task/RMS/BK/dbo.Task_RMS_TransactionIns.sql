 ALTER PROCEDURE [dbo].[Task_RMS_TransactionIns]
 
 AS
	/*
		Created: Johnson
		Date: 2012-10-25
		Task: copy parlay tickets of special members into RMS
		DB: DBRMS/bodb_RMS
		
		Revisions:
			- 20130125@Johnson: move betrransParlay from bodb02 to bodb_RMS and rename to rmBettrans
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @max_transid BIGINT
	
	SELECT @max_transid = ISNULL(max(transid),0)
	FROM rmTransaction WITH(NOLOCK)
	
	INSERT INTO rmTransaction (transid, refno, custid, combo)
	SELECT TOP 10000 transid, refno, custid, right(betcheck,len(betcheck)-1) as combo
	FROM rmBettrans b WITH(NOLOCK)
	WHERE b.transid > @max_transid		
		AND b.matchid = 9
		AND b.statusid = 0
	
GO
