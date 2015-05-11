USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_BalanceNegative]
AS
/*
	Created by: Viet
	Date: 2014-01-06
	Task: Add Customers together with their Negative Balance 
	DB: DBTXN/BODB02
	ORIGINAL SP: Task_BalanceNegativeHistoryIns_Cust, Task_BalanceNegativeDel_CustCredit
	
	Revision: 		
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@Site VARCHAR(50)
	SET	@Site='haifa'

	CREATE TABLE #tmpBalanceLic (custid INT PRIMARY KEY, balance MONEY)
	DECLARE @tmpMatch TABLE (MatchID INT PRIMARY KEY)

	SELECT custid
	INTO #tmpRecommend
	FROM DBLIC.bodb_licensee.dbo.LicenseeCust
	WHERE licenseeid IN (
			SELECT licenseeid
			FROM DBLIC.bodb_licensee.dbo.Licensees WITH (NOLOCK)
			WHERE licenseename = @Site
			)
					
	INSERT INTO @tmpMatch (MatchID)
	SELECT DISTINCT MatchID
	FROM dbo.BalanceNegative WITH (NOLOCK)
	WHERE StatusID = 0 
		AND CustID IN (
			SELECT CustID
			FROM CustDB.dbo.custInfo WITH (NOLOCK)
			WHERE Recommend IN (SELECT custid FROM #tmpRecommend) 
				AND roleid = 1
			)

	IF @@ROWCOUNT > 0 -- found some matches
	BEGIN
		-- turn to use bettrans in realtime
		INSERT INTO #tmpBalanceLic (CustID, Balance)
		SELECT custid, SUM(winlost - actual_stake + playercomm)
		FROM bettrans WITH (NOLOCK)
		WHERE custid IN (
				SELECT custid
				FROM CustDB.dbo.custinfo WITH (NOLOCK)
				WHERE Recommend IN (SELECT custid FROM #tmpRecommend)
					AND roleid = 1 
				)
		GROUP BY custid
		HAVING SUM(winlost - actual_stake + playercomm) < 0 -- negative balance


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

		UPDATE dbo.BalanceNegative WITH(UPDLOCK,ROWLOCK)
		SET StatusID = 1
		WHERE MatchID IN (SELECT MatchID FROM @tmpMatch ) 
			AND StatusID = 0 
		
		DROP TABLE #tmpBalanceLic
	END

	-- Remove Credit Customer (Not Haifa) out BalanceNegative
	SELECT distinct CustID
	INTO #TempCustomer
	FROM dbo.BalanceNegative WITH (NOLOCK)
	
	IF @@ROWCOUNT > 0
	BEGIN
		DELETE #TempCustomer
		WHERE CustID IN (
			SELECT custid
			FROM CustDB.dbo.custinfo WITH (NOLOCK)
			WHERE Recommend IN (SELECT custid FROM #tmpRecommend)
				AND roleid = 1
			)
			
		DELETE dbo.BalanceNegative
		FROM #TempCustomer c
		WHERE dbo.BalanceNegative.CustID = c.CustID
	END
	
	DROP TABLE #TempCustomer
	DROP TABLE #tmpRecommend
END 