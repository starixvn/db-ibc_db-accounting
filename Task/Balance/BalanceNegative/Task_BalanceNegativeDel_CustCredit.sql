ALTER PROCEDURE [dbo].[Task_BalanceNegativeDel_CustCredit]

AS 
/*
	Created by: Jamie
	Date: 2013-06-25
	Task: Remove Credit Customer ( Not Haifa) out BalanceNegative
	DB: DBTXN/BODB02
	
	Revision: 
*/
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE	@Site VARCHAR(50)

	SELECT	@Site='haifa'

	SELECT	c.custid INTO #tmpRecommend
	FROM	custinfo c WITH(NOLOCK)
			INNER JOIN DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH(NOLOCK) ON c.custid = lc.custid
	WHERE	srecommend IN (SELECT custid FROM f_depsuper_1(@site))
			AND c.roleid = 2
			
	IF EXISTS(
		SELECT	TOP 1 1 
		FROM	dbo.BalanceNegative WITH (NOLOCK)
		WHERE	CustID IN (SELECT custid FROM #tmpRecommend WITH (NOLOCK))	
	)
	BEGIN
		DELETE FROM dbo.BalanceNegative WITH (ROWLOCK)
		WHERE	CustID NOT IN (
					SELECT	custid 
					FROM	custinfo WITH(NOLOCK) 
					WHERE	recommend IN (SELECT custid FROM #tmpRecommend WITH (NOLOCK))					
				)
			
	END
	DROP TABLE #tmpRecommend
END  