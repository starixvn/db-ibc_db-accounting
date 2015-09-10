ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelByDate14]
	@winlostdate	DATETIME,	
	@totalBalance	MONEY = 0 OUTPUT
AS
/*	
	Created: 20120612@Lukas
	Task: Reset Winning - Get data by Date
	DB: DBACC.BODB02
	
	Revision:
		- 20120723@Lukas: Excluding transfered transactions of dummy balance accounts
		- 20120725@Lukas: define IBC racing net income instead of gross income
		- 20120820@Sophia: Separate Poker into 2 rows, 1 for IBC net income and Poker (Due to Partners)
		- 20120919@Sophia: Add Virtual Sports
		- 20121102@Elodie: No need execute Acc_ResetWinning_SelByDate_Original (@winlostdate < '2012-09-01')		
		- 20140310@Kathy: Automation of Keno's income account. [Redmine:#13106]
		- 20140626@Logan: Improve performance. [Redmine: #17345]
		- 20150604@Sophia: . Apply Gold Deluxe  
						   . Remove P2P (Poker)
						   . Revise Code
						   . Apply AG Casino and Vegas Game [#37683]
		- 20150909@Sophia: Exclude Colosuss Bets [#43352]
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON

	DECLARE @DummyCust AS TABLE (CustId INT, Product VARCHAR(50) )

	DECLARE @isTest BIT,@SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)
	IF (@SQL like '%_xtest%')
	BEGIN
		SELECT @isTest = 1
	END
	ELSE
	BEGIN
		SELECT @isTest = 0
	END
	
	IF @isTest = 0
	BEGIN 
		INSERT INTO @DummyCust (CustID, Product)
		SELECT CustID, Product
		FROM bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance','Poker', 'Poker (Due to Partners)')----, 'Racing (Due to Partners)') 
	END 
	ELSE
	BEGIN 
		INSERT INTO @DummyCust (CustID, Product)
		SELECT CustID, Product
		FROM bodb_ACC.dbo.Acc_DWLList_xtest WITH(NOLOCK)
		WHERE Product NOT IN ('Total Balance','Poker', 'Poker (Due to Partners)')  ---'Racing (Due to Partners)')
	END 


	DECLARE @Winning TABLE 
	(
		product VARCHAR(50),
		winlost MONEY					
	)	
			
	CREATE TABLE #source
	(
	    custid        INT,
	    bettype       INT,
	    winlost       MONEY
	)


	INSERT INTO #source
	SELECT CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
	         ELSE -1
	       END AS custid,
           bettype,
           SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                              WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                              ELSE actualrate
	                                                                            END), 0)) as winlost
    FROM bettrans b WITH(READPAST, INDEX = IX_Report)
	LEFT JOIN @DummyCust d ON b.custid = d.custid
	WHERE b.ruben = 1
	   AND b.bettype > 19000
	   AND b.winlostdate = @winlostdate
	   AND b.statusid NOT IN (101, 102, 103, 121) 
	GROUP BY CASE
             WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
             ELSE -1
           END, b.bettype
	HAVING SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                              WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                              ELSE actualrate
	                                                                            END), 0)) <> 0
	UNION ALL 
		
	SELECT -1 AS custid,
           bettype,
           SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * actualrate, 0)) as winlost
    FROM bettrans14 b WITH(READPAST, INDEX = IX_Report)
	LEFT JOIN @DummyCust d ON b.custid = d.custid
	WHERE  b.bettype <> 18000
	   AND b.winlostdate = @winlostdate
	   AND b.statusid NOT IN (101, 102, 103, 121) 
	GROUP BY  b.bettype
	HAVING SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * actualrate, 0)) <> 0

	
	

	

	---- get total balance
	SELECT @totalBalance = ISNULL(SUM(winlost), 0)
	  FROM #source
	 WHERE custid NOT IN (SELECT custid FROM @DummyCust)
	   AND bettype <> 20000


	IF EXISTS (SELECT 1 
	             FROM #source
	            WHERE bettype = 20000) --- openning balance
	BEGIN
		INSERT INTO @Winning(product, winlost)		
		SELECT 'Openning Balance', SUM(ISNULL(winlost, 0))
		  FROM #source 
		 WHERE bettype = 20000
	END

	INSERT INTO @Winning(product, winlost)
	--- all product
	SELECT 'All products',
	       SUM(ISNULL(winlost, 0)) as winlost
	  FROM #source
	 WHERE bettype = 19999 
	   AND custid NOT IN (SELECT custid FROM @DummyCust)

	----- calculate reset
	;WITH rs AS
	(
		SELECT 'All products' AS product
				,SUM(ISNULL(winlost, 0)) AS reset
		FROM #source b
		INNER JOIN @DummyCust d
			ON b.custid = d.custid
		WHERE b.bettype IN (21001, 21002)
			AND d.custid <> 0
	) 	
	SELECT w.product,
	       ROUND(ISNULL(w.winlost, 0), 2) AS winlost,
	       ROUND(ISNULL(rs.reset, 0), 2) AS reset
	FROM @winning w	
	LEFT JOIN rs rs ON w.product = rs.product

	DROP TABLE #source	
END

GO

GRANT EXECUTE ON [dbo].[Acc_ResetWinning_SelByDate14] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_ResetWinning_SelByDate14] TO [vnteam] AS [dbo]
GO 