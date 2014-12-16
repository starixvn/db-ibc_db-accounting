USE [CheckResultDB]

---- Execute 
CREATE TABLE #temp (CustId INT, IsFinished BIT)

INSERT  INTO #temp (CustId, IsFinished)
SELECT	DISTINCT ci.CustId , 0 
FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
WHERE   RoleID = 4  
		AND CustId NOT IN (select CustId from CheckCustDB.dbo.Dep_CustSuper WITH (NOLOCK)) 
 

SET NOCOUNT ON 
DECLARE @CustId INT, @Rowcnt INT

WHILE (1 = 1)
BEGIN	
	DECLARE @Msg VARCHAR(200)
	
	UPDATE  TOP(1) #temp
	SET		@CustId = CustId  		
			,IsFinished = 1
	FROM	#temp
	WHERE	IsFinished = 0

	SELECT @Rowcnt = @@ROWCOUNT	
	IF @Rowcnt = 0 BREAK

	EXEC dbo.[DBA_CheckPT_Credit] @srecommend = @CustId  

	SET @msg = 'Done for custid = ' + cast(@CustId AS VARCHAR(50))  
	RAISERROR (@msg,0,1) WITH NOWAIT

	--WAITFOR DELAY '00:00:01'

END

SELECT	R.RuleName, C.* 
FROM	CheckPTResult_Credit C 
INNER JOIN Rule_Credit R ON C.RuleId = R.RuleId

 
DROP TABLE #temp

GO