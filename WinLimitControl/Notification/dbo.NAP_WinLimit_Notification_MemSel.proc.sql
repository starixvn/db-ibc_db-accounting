USE bodb02
GO
ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemSel]
(
	@ErrCode 		INT = 0 OUTPUT,
	@ErrMsg 		NVARCHAR(200) = '' OUTPUT
)
AS
/*
Created: 20150702@bobby.nguyen
Task : #35215 - Win Limit Control - Notification select member
DB: DBTXN.bodb02
Original:
Revisions:
	- 20150702@bobby.nguyen: Initial
	- 20160507@Patrick: #57213 - Voidbridge integration
	
Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tempCust
	(
		custid			INT
		, username		NVARCHAR(50)
		, username2		NVARCHAR(50)
		, currency		VARCHAR(10)
		, SiteName		NVARCHAR(100)
	)
	
	-- RESET output
	SELECT 	@ErrCode 	= 0
			, @ErrMsg 	= ''
	
	SELECT g.CustID
		, g.WinlostDate
		, g.bettype
	INTO #tempWLGame		
	FROM dbo.WinLimit_Game g WITH(NOLOCK)
	WHERE g.IsBlocked = 1 AND g.IsNotified = 0
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'There is no information.'
		RETURN
	END
	-- SELECT cust info
	;WITH CTE_CustId AS (
		SELECT custid
		FROM #tempWLGame
		GROUP BY custid
	)
	INSERT INTO #tempCust 
	SELECT c.custid
		, c.username
		, c.username2
		, e.code
		, CASE	WHEN s.site IS NOT NULL THEN s.site 
				ELSE 
					CASE	WHEN (s.site IS NULL AND sc.site = '789y') THEN 'maxbet789y'
							ELSE 'maxbet'
					END 
		END AS SiteName
	FROM CustDB.dbo.Customer c WITH(NOLOCK)
		INNER JOIN CTE_CustId temp ON c.custid = temp.custid
		INNER JOIN CustDB.dbo.Customer sc WITH(NOLOCK) ON c.srecommend = sc.custid -- credit member
		LEFT JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) ON c.srecommend = s.custid-- deposit member
		INNER JOIN CustDB.dbo.exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
	WHERE sc.roleid = 4
		
	SELECT g.custid
		, c.username
		, ISNULL(c.username2, '') AS username2
		, c.currency
		, c.SiteName
		, g.productid
		, p.ProductName
		, g.MaxWinLimit
		, g.BlockedWinAmt
		, g.TotalWinAmt
		, (g.TotalWinAmt * 100 / g.MaxWinLimit) AS percentage
		, g.WinlostDate
	FROM #tempWLGame t
		INNER JOIN dbo.Winlimit_Game g WITH(NOLOCK) ON t.CustID = g.CustID AND t.WinlostDate = g.WinlostDate AND t.Bettype = g.Bettype
		INNER JOIN dbo.f_Winlimit_GetProductSetting() p ON t.Bettype = p.BetType AND p.IsActive_Company = 1
		LEFT JOIN #tempCust c ON g.custid = c.custid
	WHERE g.MaxWinLimit > 0
	
	DROP TABLE #tempWLGame
	DROP TABLE #tempCust

	RETURN
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [vnteam]
GO
