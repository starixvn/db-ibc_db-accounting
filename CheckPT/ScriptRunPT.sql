


---- Execute 
CREATE TABLE #temp (CustId INT, SportType SMALLINT, IsFinished BIT)

INSERT  INTO #temp (CustId, SportType, IsFinished)
SELECT	DISTINCT ci.CustId , cs.SportType,  0 
FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
CROSS JOIN (SELECT DISTINCT Sporttype FROM CheckCustDB.dbo.CustSetting WITH (NOLOCK) WHERE CustID = 1) cs
WHERE   RoleID = 4
 

SET NOCOUNT ON 
DECLARE @CustId INT, @SportType SMALLINT, @Rowcnt INT

WHILE (1 = 1)
BEGIN	
	DECLARE @Msg VARCHAR(200)
	
	UPDATE  TOP(1) #temp
	SET		@CustId = CustId  
			,@SportType=SportType
			,IsFinished = 1
	FROM	#temp
	WHERE	IsFinished = 0

	SELECT @Rowcnt = @@ROWCOUNT	
	IF @Rowcnt = 0 RETURN

	EXEC dbo.[DBA_CheckPT_Credit] @srecommend = @CustId, @SportType = @SportType with RECOMPILE --@SportType 

	SET @msg = 'Done for custid = ' + cast(@CustId AS VARCHAR(50)) + ' sporttype=' + cast(@SportType AS VARCHAR(20))
	RAISERROR (@msg,0,1) WITH NOWAIT

	--WAITFOR DELAY '00:00:01'

END

SELECT	R.RuleName, C.* 
FROM	CheckPTResult_Credit C 
INNER JOIN Rule_Credit R ON C.RuleId = R.RuleId

 
DROP TABLE #temp

GO
 