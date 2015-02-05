USE [bodb_licensee]
GO


ALTER   PROCEDURE [dbo].[DBA_FunctionProduct]
(
	@ProductCode VARCHAR(100) = ''
)
/*
Created: 20140502@Jim
Task : re-structure create new licensee flow
DB: DBLIC.bodb_licensee
Original :
	
Revisions:
- 20150112@Winnie: add OR @ProductCode='' to get all product
	
Param's Explanation:
		
	
*/
AS
BEGIN 
	DECLARE @tblFunctions AS TABLE (ProductId INT,FunctionId INT,TypeID INT)
	IF @ProductCode = 'SB' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	0 AS ProductId -- SB
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId NOT IN (22 -- Racing
									,23 -- Number Game
									,34 -- Racing Commission
									,35 -- Daily Racing Win Loss
									,58 -- AGENCY SYSTEM 
									,59 -- WinLoss By League
									,60 -- AGENCY SYSTEM 
									,61 -- Playtech Casino Win Loss
									,62 -- AG Casino Win Loss
									
									)	
		END
	IF @ProductCode = 'RB' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	1 AS ProductId -- RB
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 1  -- TOTAL BETS
									,3  -- REPORTS
									,52 -- CUSTOMER REPORTS
									,22 -- Racing
									,27 -- Licensee Win Loss
									,28 -- Settled Match Count
									,31 -- Match Win Loss
									,32 -- Win Loss By Products
									,33 -- Win Loss By Bet Type
									,34 -- Racing Commission
									,35 -- Daily Racing Win Loss
									,36 -- Cancelled Bets
									,37 -- Daily Bet List
									,38 -- Live Report
									,39 -- Turnover
									,53 -- Mobile Win Loss
									,41 -- Results
									,42 -- Balance
									,29 -- Customer Win Loss
									,30 -- Customer Pending Funds
									,40 --Customer Balance
									)
			UNION ALL 
			SELECT 	1 AS ProductId -- RB
			,7 AS FunctionID ---Racing		
			,2 AS TypeId	--- LA Function
			
		END
	IF @ProductCode = 'NG' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	2 AS ProductId -- NG
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 3  -- REPORTS
									,23 -- Number Game 
									,27 -- Licensee Win Loss
									,28 -- Settled Match Count
									,31 -- Match Win Loss
									,32 -- Win Loss By Products
									,33 -- Win Loss By Bet Type
									,36 -- Cancelled Bets
									,37 -- Daily Bet List
									,38 -- Live Report
									,39 -- Turnover
									,52 -- CUSTOMER REPORTS
									,53 -- Mobile Win Loss
									,41 -- Results
									,42 -- Balance
									,29 -- Customer Win Loss
									,30 -- Customer Pending Funds
									,40 --Customer Balance
									,51 -- Customer Turnover
									)
			UNION ALL 
			SELECT 	2 AS ProductId -- NG
			,15 AS FunctionID ---Number Game Win Loss		
			,2 AS TypeId	--- LA Function
			
		END
	IF @ProductCode = 'BA' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	3 AS ProductId -- BA
					,FunctionID  
					,3 AS TypeId	 -- Lrf special Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 54  -- SpecialBA
									)
		END
	IF @ProductCode = 'LC' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	4 AS ProductId -- lC
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 3  -- REPORTS
									,27 -- Licensee Win Loss
									,28 -- Settled Match Count
									,31 -- Match Win Loss
									,32 -- Win Loss By Products
									,33 -- Win Loss By Bet Type
									,36 -- Cancelled Bets
									,37 -- Daily Bet List
									,38 -- Live Report
									,39 -- Turnover
									,52 -- CUSTOMER REPORTS
									,53 -- Mobile Win Loss
									,41 -- Results
									,42 -- Balance
									,29 -- Customer Win Loss
									,30 -- Customer Pending Funds
									,40 --Customer Balance
									
									)
			UNION ALL 
			SELECT 	4 AS ProductId -- LC
			,17 AS FunctionID ---Live Casino Win Loss
			,2 AS TypeId	--- LA Function	
		END
	IF @ProductCode = 'VS' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	5 AS ProductId -- VS
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 3  -- REPORTS
									,27 -- Licensee Win Loss
									,28 -- Settled Match Count
									,31 -- Match Win Loss
									,32 -- Win Loss By Products
									,33 -- Win Loss By Bet Type
									,36 -- Cancelled Bets
									,37 -- Daily Bet List
									,38 -- Live Report
									,39 -- Turnover
									,52 -- CUSTOMER REPORTS
									,53 -- Mobile Win Loss
									,41 -- Results
									,42 -- Balance
									,29 -- Customer Win Loss
									,30 -- Customer Pending Funds
									,40 --Customer Balance
									,51 -- Customer Turnover
									)
			UNION ALL 
			SELECT 	5 AS ProductId -- VS
			,16 AS FunctionID ---Virtual Sports
			,2 AS TypeId	--- LA Function
			
		END
	IF @ProductCode = 'CS' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	6 AS ProductId -- CS
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 3  -- REPORTS
									,27 -- Licensee Win Loss
									,32 -- Win Loss By Products
									,33 -- Win Loss By Bet Type
									,36 -- Cancelled Bets
									,37 -- Daily Bet List
									,38 -- Live Report
									,39 -- Turnover
									,52 -- CUSTOMER REPORTS
									,41 -- Results
									,42 -- Balance
									,29 -- Customer Win Loss
									,40 --Customer Balance
									)
			UNION ALL 
			SELECT 	6 AS ProductId -- CS
			,21 AS FunctionID ---RNG Casino Win Loss
			,2 AS TypeId	--- LA Function
			
		END
	IF @ProductCode = 'KN' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	8 AS ProductId -- KN
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 3  -- REPORTS
									,27 -- Licensee Win Loss
									,32 -- Win Loss By Products
									,36 -- Cancelled Bets
									,37 -- Daily Bet List
									,38 -- Live Report
									,39 -- Turnover
									,52 -- CUSTOMER REPORTS
									,42 -- Balance
									,29 -- Customer Win Loss
									,40 --Customer Balance
									)
		END
	IF @ProductCode = 'PTCS' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	9 AS ProductId -- PTCS
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 3  -- REPORTS
									,61 -- Playtech Casino Win Loss
									)
		END
	IF @ProductCode = 'AGC' OR @ProductCode=''
		BEGIN 
			INSERT INTO @tblFunctions (ProductId, FunctionId,TypeID)
			SELECT	10 AS ProductId -- AGC
					,FunctionID  
					,1 AS TypeId	 -- Lrf Function
			FROM dbo.Functions WITH (NOLOCK)
			WHERE FunctionId    IN (
									 3  -- REPORTS
									,62 -- AG Casino Win Loss
									)
		END	
	
	SELECT * FROM @tblFunctions ORDER BY ProductId,FunctionId  ASC
		/*
			EXEC DBA_FunctionProduct
		*/
END	