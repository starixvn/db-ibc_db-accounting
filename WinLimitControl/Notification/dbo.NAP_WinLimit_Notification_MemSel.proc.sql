ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemSel]
(
	@ErrCode 		INT = 0 OUTPUT,
	@ErrMsg 		NVARCHAR(200) = '' OUTPUT
)
AS
/*
Created: 20150702@bobby.nguyen
Task : Win Limit Control - Notification
DB: DBTXN.bodb02
Original:
Revisions:
	- 20150702@bobby.nguyen: Initial
	
Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @custList	NVARCHAR(MAX)
		, @remoteQuery	NVARCHAR(MAX)

	CREATE TABLE #tempCust
	(
		custid			INT
		, username		NVARCHAR(30)
		, username2		NVARCHAR(30)
		, currency		VARCHAR(10)
	)
	
	-- RESET output
	SELECT 	@ErrCode 	= 0
			, @ErrMsg 	= ''
	
	SELECT 
		g.CustID
		, g.ProductID
		, g.MaxWinLimit
		, g.TotalWinAmt
	INTO #tempWLGame		
	FROM dbo.WinLimit_Game g WITH(NOLOCK)
	
	WHERE g.IsBlocked 		= 1
		AND g.IsNotified 	= 0
	
	IF ( @@ROWCOUNT = 0 )
	BEGIN
		SELECT 	@ErrCode 	= 100
			, @ErrMsg 		= 'There is no information.'
			
		RETURN;
	END
	
	SELECT @custList	= COALESCE(@custList + ',', '') + CAST(g.custid AS NVARCHAR(10))
	FROM #tempWLGame g
	GROUP BY g.custid
	
	SELECT @remoteQuery = N'
		INSERT INTO #tempCust 
		SELECT q.custid
			, q.username
			, q.username2
			, q.code AS currency
	
		FROM OPENQUERY([DBTXN], ''SELECT c.custid
				, c.username
				, c.username2
				, e.code
			FROM CustDB.dbo.customer c WITH(NOLOCK)
				INNER JOIN CustDB.dbo.exchange e WITH(NOLOCK)
				ON c.currency = e.exchangeid
			WHERE custid IN (' + @custList + ')'') AS q'
	
	BEGIN TRY
		EXEC sp_executesql @remoteQuery
	END TRY
	BEGIN CATCH
		SELECT 	@ErrCode 	= 101
			, @ErrMsg 		= ERROR_MESSAGE()
	END CATCH

	SELECT g.custid
		, c.username
		, ISNULL(c.username2, '') AS username2
		, g.productid
		, p.ProductName
		, g.MaxWinLimit
		, g.TotalWinAmt
		, (g.TotalWinAmt * 100 / g.MaxWinLimit) AS percentage
			
	FROM #tempWLGame g
		INNER JOIN #tempCust c
		ON g.custid 		= c.custid
		INNER JOIN dbo.Products p WITH(NOLOCK)
		ON g.ProductID 		= p.ProductID
		
	WHERE p.ProductType 	= 2
	
	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [vnteam]
GO

