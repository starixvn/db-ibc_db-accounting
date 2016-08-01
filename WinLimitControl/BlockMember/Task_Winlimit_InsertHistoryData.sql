ALTER PROCEDURE dbo.Task_Winlimit_InsertHistoryData @XmlData NVARCHAR(MAX)
AS
/*   
	Create: 20160623@Helen
	Task : Winlimit - Insert history data
	DB: DBCUST/CUSTDB
	Revisions:
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @_hdoc INT
	EXEC sp_xml_preparedocument @_hdoc OUTPUT, @XmlData

	SELECT 
		CustId
		, ProductId 
		, BettypeID
		, MaxWinLimit 
		, TotalWinAmt 
		, WinAmt 
		, LevelID 
		, ActionID 
		, ModifiedDate 
		, IsNotified 
		, ModifiedBy 
		, CreatedBy 
		, WinlostDate 
	INTO #TempData   
	FROM OPENXML(@_hdoc,'/root/r', 2)   
	WITH (CustId INT 'a1'
		, ProductId TINYINT 'a2'
		, BettypeID SMALLINT 'a3'
		, MaxWinLimit MONEY 'a4'
		, TotalWinAmt MONEY 'a5'
		, WinAmt MONEY  'a6'
		, LevelID TINYINT  'a7'
		, ActionID TINYINT 'a8'
		, ModifiedDate DATETIME  'a9'
		, IsNotified BIT  'a10'
		, ModifiedBy INT  'a11'
		, CreatedBy  INT 'a12'
		, WinlostDate DATETIME  'a13'
	)   
	
	EXEC sp_xml_removedocument @_hdoc  

	INSERT INTO WinLimit_CustGameMonitoring_History( CustId, ProductId,BettypeID, MaxWinLimit, TotalWinAmt,WinAmt,LevelID,ActionID,ModifiedDate
		, IsNotified, ModifiedBy, CreatedBy, WinlostDate)

	SELECT CustId, ProductId,BettypeID, MaxWinLimit, TotalWinAmt,WinAmt,LevelID,ActionID,ModifiedDate
		, IsNotified, ModifiedBy, CreatedBy, WinlostDate

	FROM #TempData
	
	DROP TABLE #TempData
END
GO

