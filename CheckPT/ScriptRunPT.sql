

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
		AND srecommend NOT IN (	SELECT custid FROM Dep_CustSuper WITH (NOLOCK))


---EXEC dbo.[DBA_CheckPT_Setting] @srecommend = 1, @SportType = 1
--select * from #temp

SET NOCOUNT ON 
DECLARE @CustId INT, @SportType SMALLINT, @rowcnt INT

WHILE (1 = 1)
BEGIN	
	declare @msg varchar(200)
	
	UPDATE TOP(1) #temp
	SET		@CustId = CustId  
			,@SportType=SportType
			,IsFinished = 1
	FROM	#temp
	WHERE	IsFinished = 0

	EXEC dbo.[DBA_CheckPT_Setting] @srecommend = @CustId, @SportType = @SportType with RECOMPILE --@SportType 

	set @msg='Done for custid = ' + cast(@CustId as varchar(50)) + ' sporttype='+ cast(@SportType as  varchar(20))
	RAISERROR (@msg,0,1) WITH NOWAIT

	--WAITFOR DELAY '00:00:01'
END

SELECT * FROM CheckPTRule

DROP TABLE #temp

GO
 