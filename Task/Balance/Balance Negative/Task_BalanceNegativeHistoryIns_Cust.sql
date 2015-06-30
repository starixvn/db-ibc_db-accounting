ALTER PROCEDURE [dbo].[Task_BalanceNegativeHistoryIns_Cust]

AS 
/*
	Created by: Jamie
	Date: 2013-06-25
	Task: Add Customers together with their Negative Balance 
	DB: DBTXN/BODB02
	
	Revision: 
		- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo by link database)
*/
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE	@Site VARCHAR(50)

	SELECT	@Site='haifa'

	DECLARE	@MatchID INT

	CREATE TABLE #tmpBalanceLic (custid INT PRIMARY KEY, balance MONEY)

	DECLARE @tmpMatch TABLE (
		MatchID INT PRIMARY KEY 
	)

	SELECT	c.custid INTO #tmpRecommend
	FROM	CustDB.dbo.custinfo c WITH(NOLOCK)
			INNER JOIN DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH(NOLOCK) ON c.custid = lc.custid
	WHERE	srecommend IN (SELECT custid FROM f_depsuper_1(@site))
			AND c.roleid = 2
		
			
	INSERT INTO @tmpMatch( MatchID)
	SELECT	DISTINCT MatchID 
	FROM	dbo.BalanceNegative WITH (NOLOCK)
	WHERE	StatusID = 0
			AND CustID IN (	
				SELECT	CustID
				FROM	CustDB.dbo.custInfo WITH (NOLOCK)
				WHERE	Recommend IN (SELECT custid FROM #tmpRecommend WITH (NOLOCK))			
			)

	IF @@ROWCOUNT = 0 RETURN  -- No match found 

	INSERT INTO #tmpBalanceLic( CustID, Balance)
	SELECT	c.custid, c.balance - d.balance
	FROM	balanceCredit c WITH(NOLOCK)
			INNER JOIN balanceDebit d WITH(NOLOCK) ON c.custid = d.custid
	WHERE	c.custid IN (	SELECT	custid 
							FROM	CustDB.dbo.custinfo WITH(NOLOCK) 
							WHERE	recommend IN (SELECT custid FROM #tmpRecommend WITH (NOLOCK))
						)
			AND c.balance - d.balance < 0  -- negative balance

	IF @@ROWCOUNT <> 0 
	BEGIN
		INSERT INTO dbo.BalanceNegativeHistory(
			LogDate
			, ExecDate
			, MatchID
			, ActionID
			, GroupID
			, CustID
			, Balance
			, TotalBalance
			, StatusID
			, Site
			, Remark
		)
		
		SELECT	GETDATE()
				, bn.ExecDate
				, bn.MatchID
				, bn.ActionID
				, bn.GroupID
				, bn.CustID
				, bn.Balance
				, t.balance
				, 0
				, @Site
				, bn.Remark 
		FROM	#tmpBalanceLic t WITH (NOLOCK)
				INNER JOIN dbo.BalanceNegative bn WITH (NOLOCK) ON t.custID = bn.CustID 
		WHERE	bn.MatchID IN (SELECT MatchID FROM @tmpMatch ) 
				AND bn.StatusID = 0 
		
	END

	UPDATE	dbo.BalanceNegative WITH(UPDLOCK,ROWLOCK)
	SET		StatusID = 1 
	WHERE	MatchID IN (SELECT MatchID FROM @tmpMatch ) 
			AND StatusID = 0 
	
	DROP TABLE #tmpBalanceLic
	DROP TABLE #tmpRecommend
END 