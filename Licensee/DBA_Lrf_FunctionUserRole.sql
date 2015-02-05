USE [bodb_licensee]
GO

ALTER   PROCEDURE [dbo].[DBA_Lrf_FunctionUserRole]
(
	@UserRole	VARCHAR(50),
	@ErrCode int = 0 OUTPUT , 
	@ErrMsg nvarchar(1000) = '' OUTPUT 	
)
/*
Created: 20140502@Jim
Task : re-structure create new licensee flow
DB: DBLIC.bodb_licensee
Original :
	
Revisions:
	
Param's Explanation:
		@UserRole : admin , who get all of funtion with typeid=2
					normal , who get all of funtion with typeid=1
	
*/		

AS
DECLARE @tblFunctions AS TABLE (FunctionId INT,TypeID INT)
IF (@UserRole='normal')
	BEGIN 
		INSERT INTO  @tblFunctions (FunctionId,TypeID) 
		SELECT FunctionID,1 AS TypeID 
		FROM dbo.Functions WITH (NOLOCK)
		WHERE FunctionId IN (1,2,3,4,52)
				OR ParentId IN (1,2,3,4,52)
		
			
	END
IF (@UserRole='admin')
	BEGIN	
		INSERT INTO  @tblFunctions (FunctionId,TypeID) 

		SELECT FunctionID,1 AS TypeID
		FROM dbo.Functions WITH (NOLOCK)
		WHERE (FunctionId IN (1,2,3,4,52)
				OR ParentId IN (1,2,3,4,52)
				)
				AND FunctionID <> 56
		UNION ALL 
		
		SELECT FunctionID,11 AS TypeID
		FROM dbo.Functions WITH (NOLOCK)
		WHERE  (FunctionId = 6 OR ParentId = 6)
	
	END
IF EXISTS (SELECT TOP 1 1  FROM @tblFunctions )
	BEGIN 
		INSERT INTO @tblFunctions(FunctionId,TypeID) 
		SELECT FunctionID,3 AS TypeID 
		FROM dbo.OA_Functions WITH (NOLOCK)
		WHERE FunctionID IN 
				(
					4, --Total Transaction
					5, --Win Loss Report
					11,--Currency Win Loss Report
					20,--Licensee Win Loss
					23,--Performance
					24,--Performance
					25,--Performance by Turnover
					26 --Performance by Licensing Fee
				)
	END 
	/*
---revoke redundancy permision
DELETE 	@tblFunctions
WHERE FunctionID IN (
						23 -- NumberGam
						,34 --- Racing Commission
						,35 --- Daily Racing Win Loss
						,59 --- WinLoss By League
						,61 --- Playtech Casino Win Loss
						,62 --- AG Casino Win Loss
					)
					*/
SELECT * FROM @tblFunctions
	/*
		EXEC DBA_FunctionUserRole @UserRole='admin'
	*/