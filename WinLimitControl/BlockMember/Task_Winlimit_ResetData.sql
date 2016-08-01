USE bodb02
GO

ALTER PROCEDURE dbo.Task_Winlimit_ResetData @WinlostDate SMALLDATETIME
AS
/*   
	Create: 20151019@Patrick
	Task : Reset data
	DB: DBTXN/bodb02
	Revisions:
	
		- 20160714@Helen: CWL - Phase 2 [Redmine: 57722]
	Param's Explanation:
		
*/
BEGIN
	DECLARE @RowId INT, @BetType SMALLINT
	
	--get product setting
	CREATE TABLE #ProductSetting(RowId INT IDENTITY(1,1), ProductId TINYINT, Bettype SMALLINT)
	
	INSERT INTO #ProductSetting(ProductId, Bettype)
	SELECT DISTINCT ProductID, BettypeID
	FROM DBCUST.CUSTDB.dbo.Winlimit_ProductSetting WITH (NOLOCK)
	WHERE SettingStatus IN (0,1)

	--get blocked list members
	CREATE TABLE #BlockedListMember (CustId INT, ProductId TINYINT, BetType SMALLINT)

	INSERT INTO #BlockedListMember(CustId,ProductId , BetType)
	SELECT CustId, ProductId, BetTypeID
	FROM DBCUST.CUSTDB.dbo.WinLimit_CustGameStatus WITH(NOLOCK)
	WHERE IsBlockedPlaceBet = 1 OR IsBlockedTransfer = 1

	SET @RowId = 1
	WHILE EXISTS (SELECT TOP 1 1 FROM #ProductSetting WHERE RowId = @RowId)
	BEGIN
		SELECT @BetType = BetType FROM #ProductSetting WHERE RowId = @RowId
		SET @RowId = @RowId + 1

		--
		WHILE 1 = 1
		BEGIN
			DELETE TOP(50000) g
			FROM dbo.Winlimit_CreditGame g WITH(ROWLOCK)
				LEFT JOIN #BlockedListMember t ON g.CustId = t.CustId AND g.BetType = t.BetType
			WHERE WinlostDate < @WinlostDate
				AND g.BetType = @BetType
				AND t.CustId IS NULL
			OPTION (MAXDOP 4)
			
			IF @@ROWCOUNT < 50000
				BREAK
		END
		--
		WHILE 1 = 1
		BEGIN
			DELETE TOP(50000) g
			FROM dbo.Winlimit_DebitGame g WITH(ROWLOCK)
				LEFT JOIN #BlockedListMember t ON g.CustId = t.CustId AND g.BetType = t.BetType
			WHERE WinlostDate < @WinlostDate
				AND g.BetType = @BetType
				AND t.CustId IS NULL
			OPTION (MAXDOP 4)

			IF @@ROWCOUNT < 50000
				BREAK
		END
	END

	DROP TABLE #ProductSetting
	DROP TABLE #BlockedListMember
END
GO
