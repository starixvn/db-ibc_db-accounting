

-----Create Table CheckPTRule

IF NOT EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[CheckPTRule]') AND OBJECTPROPERTY(ID, N'IsTable') = 1)
BEGIN 
	CREATE TABLE CheckPTRule (RuleId TINYINT, RuleName NVARCHAR(100), BetType SMALLINT, SportType SMALLINT, CustId_A INT, CustId_B INT, A SMALLMONEY, B SMALLMONEY)
END 
ELSE 
BEGIN  
	TRUNCATE TABLE CheckPTRule
END 
 	 

---- Execute 
CREATE TABLE #temp (CustId INT, SportType SMALLINT, IsFinished BIT)

INSERT INTO #temp (CustId, SportType, IsFinished)
SELECT	DISTINCT ci.CustId , cs.SportType,  0 
FROM	CustInfo ci WITH (NOLOCK)
CROSS JOIN (SELECT DISTINCT Sporttype FROM CustSetting WITH (NOLOCK) WHERE CustID = 1) cs
WHERE   RoleID = 4

 
DECLARE @CustId INT, @SportType SMALLINT, @rowcnt INT

WHILE (1 = 1)
BEGIN
	 
	UPDATE TOP(1) #temp
	SET		@CustId = CustId  
			,IsFinished = 1
	FROM	#temp
	WHERE	IsFinished = 0

	EXEC dbo.[DBA_CheckPT_Setting] @srecommend = @CustId, @SportType = @SportType

	--WAITFOR DELAY '00:00:01'
END

SELECT * FROM CheckPTRule

DROP TABLE #temp

GO
 