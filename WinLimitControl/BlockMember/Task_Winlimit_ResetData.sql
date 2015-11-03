USE bodb02
GO

ALTER PROCEDURE dbo.Task_Winlimit_ResetData @WinlostDate SMALLDATETIME
AS
/*   
	Create: 20151019@Patrick
	Task : Reset data
	DB: DBTXN/bodb02
	Revisions:
	Param's Explanation:
		
*/
BEGIN
	DECLARE @RowId INT, @BetType SMALLINT
	
	--get product setting
	CREATE TABLE #ProductSetting(RowId INT IDENTITY(1,1), ProductId TINYINT, Bettype SMALLINT)
	INSERT INTO #ProductSetting(ProductId, Bettype)
	SELECT ProductId, BetType
	FROM dbo.f_Winlimit_GetProductSetting() WHERE IsActive_Company = 1

	--get blocked list members
	DECLARE @BlockedListMember TABLE(CustId INT, BetType SMALLINT)

	INSERT INTO @BlockedListMember(CustId, BetType)
	SELECT CustId, BetType
	FROM dbo.WinLimit_Game WITH(NOLOCK)
	WHERE IsBlocked = 1

	SET @RowId = 1
	WHILE EXISTS (SELECT TOP 1 1 FROM #ProductSetting WHERE RowId = @RowId)
	BEGIN
		SELECT @BetType = BetType FROM #ProductSetting WHERE RowId = @RowId
		SET @RowId = @RowId + 1

		--
		WHILE 1 = 1
		BEGIN
			DELETE TOP(20000) dbo.Winlimit_CreditGame WITH(ROWLOCK) 
			WHERE CustId NOT IN (SELECT CustId FROM @BlockedListMember WHERE BetType = @BetType)
				AND WinlostDate < @WinlostDate
				AND BetType = @BetType
			
			IF @@ROWCOUNT < 20000
				BREAK
		END
		--
		WHILE 1 = 1
		BEGIN
			DELETE TOP(20000) dbo.Winlimit_DebitGame WITH(ROWLOCK) 
			WHERE CustId NOT IN (SELECT CustId FROM @BlockedListMember WHERE BetType = @BetType)
				AND WinlostDate < @WinlostDate
				AND BetType = @BetType

			IF @@ROWCOUNT < 20000
				BREAK
		END
	END

	DROP TABLE #ProductSetting

END
GO
