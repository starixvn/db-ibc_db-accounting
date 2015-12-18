USE bodb_CustomerLog
GO

ALTER PROCEDURE dbo.Task_Winlimit_InsertHistoryData @XmlData NVARCHAR(MAX)
AS
/*   
	Create: 20151016@Patrick
	Task : Winlimit - Insert history data
	DB: DBTXN/bodb02
	Revisions:
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @_hdoc INT
	EXEC sp_xml_preparedocument @_hdoc OUTPUT, @XmlData

	SELECT CustId
		, ProductId
		, MaxWinLimit
		, TotalWinAmt
		, IsBlocked
		, BlockedDate
		, UnBlockedDate
		, IsNotified
		, BetType
		, BlockedWinAmt
		, ModifiedBy
		, CreatedBy
		, WinlostDate
	INTO #TempData	
	FROM OPENXML(@_hdoc,'/root/r', 2) 
	WITH (CustId INT '@a1'
		, ProductId TINYINT '@a2'
		, MaxWinLimit MONEY '@a3'
		, TotalWinAmt MONEY '@a4'
		, IsBlocked BIT '@a5'
		, BlockedDate DATETIME '@a6'
		, UnBlockedDate DATETIME '@a7'
		, IsNotified BIT '@a8'
		, BetType SMALLINT '@a9'
		, BlockedWinAmt MONEY '@b1'
		, ModifiedBy INT '@b2'
		, CreatedBy INT '@b3'
		, WinlostDate SMALLDATETIME '@b4'
	 ) 
 
	EXEC sp_xml_removedocument @_hdoc

	--;MERGE dbo.WinLimit_Game_History WITH(ROWLOCK, UPDLOCK) AS t
	--USING #TempData AS s 
	--	ON (t.CustId = s.CustId AND t.BetType = s.BetType 
	--		AND t.WinlostDate = s.WinlostDate AND t.BlockedDate = s.BlockedDate)
	--WHEN MATCHED THEN 
	--	UPDATE SET t.ProductId = s.ProductId
	--	, t.MaxWinLimit = s.MaxWinLimit
	--	, t.TotalWinAmt = s.TotalWinAmt
	--	, t.IsBlocked = s.IsBlocked
	--	, t.UnBlockedDate = s.UnBlockedDate
	--	, t.IsNotified = s.IsNotified
	--	, t.BlockedWinAmt = s.BlockedWinAmt
	--	, t.ModifiedBy = s.ModifiedBy
	--	, t.CreatedBy = s.CreatedBy
	--WHEN NOT MATCHED THEN
	--	INSERT(CustId, ProductId, MaxWinLimit, TotalWinAmt, IsBlocked, BlockedDate, UnBlockedDate
	--		, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate)
	--	VALUES(s.CustId, s.ProductId, s.MaxWinLimit, s.TotalWinAmt, s.IsBlocked, s.BlockedDate, s.UnBlockedDate
	--		, s.IsNotified, s.BetType, s.BlockedWinAmt, s.ModifiedBy, s.CreatedBy, s.WinlostDate);

	INSERT INTO dbo.WinLimit_Game_History(CustId, ProductId, MaxWinLimit, TotalWinAmt, IsBlocked, BlockedDate, UnBlockedDate
			, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate)
	SELECT CustId, ProductId, MaxWinLimit, TotalWinAmt, IsBlocked, BlockedDate, UnBlockedDate
			, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate
	FROM #TempData

	DROP TABLE #TempData
END
GO
