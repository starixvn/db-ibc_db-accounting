USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Acc_ResetWinning_SelByDate14]    Script Date: 07/10/2014 03:43:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Acc_ResetWinning_SelByDate14    Script Date: 7/4/2014 2:56:07 PM ******/
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
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON

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

    DECLARE @uus    tinyint  = 0
            
    SELECT @uus = c.currency
      FROM custInfo c WITH(NOLOCK)
INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
     WHERE c.custid = (SELECT MIN(custid)
                         FROM bodb_ACC.dbo.Acc_DWLList
                        WHERE custid > 0
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
 LEFT JOIN bodb_ACC.dbo.Acc_DWLList d WITH(NOLOCK) ON b.custid = d.custid
	 WHERE b.ruben = 1
	   AND b.winlostdate = @winlostdate
	   AND b.statusid NOT IN (101, 102, 103, 121)
	   AND (@uus = 20 AND b.custid NOT IN (6911909, 6911911, 6911913, 6911914, 6911916,
                                           6911917, 6911918, 6911919, 6911920, 6913085,
                                           8158305, 14054918
                                          )
         OR @uus <> 20)	   
  GROUP BY CASE
             WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid
             ELSE -1
           END, b.bettype
	HAVING SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                              WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                              ELSE actualrate
	                                                                            END), 0)) <> 0

	---- get total balance
	SELECT @totalBalance = ISNULL(SUM(winlost), 0)
	  FROM #source
	 WHERE custid NOT IN (SELECT custid
	                        FROM bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
	                       WHERE custid <> 0
	                     )
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
	   AND custid NOT IN (SELECT custid 
	                        FROM bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
	                       WHERE custid <> 0
	                     )

	----- calculate reset
	;WITH rs AS
	(
		SELECT 'All products' AS product,
		       SUM(ISNULL(winlost, 0)) AS reset
		  FROM #source b			
    INNER JOIN bodb_ACC.dbo.Acc_DWLList d WITH(NOLOCK) ON b.custid = d.custid
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
GRANT EXECUTE ON Acc_ResetWinning_SelByDate14 TO bodbAdminNet
GO
GRANT VIEW DEFINITION ON Acc_ResetWinning_SelByDate14 TO vnteam


