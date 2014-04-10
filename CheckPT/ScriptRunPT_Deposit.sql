USE CheckResultDB

SET NOCOUNT ON  

IF OBJECT_ID('tempdb..#temp') IS NOT NULL		DROP TABLE #temp

---- Execute 
CREATE TABLE #temp (SITE VARCHAR(100),IsFinished BIT)

TRUNCATE TABLE CheckResultDB.[dbo].[CheckPTResult_Deposit]
TRUNCATE TABLE CheckResultDB.dbo.CheckCommResult_Deposit

INSERT  INTO #temp (SITE,IsFinished)
SELECT LicenseeName,0 FROM DBLIC.bodb_licensee.dbo.Licensees li WITH(NOLOCK)

DECLARE @srecommend varchar(100),@site VARCHAR(100),@Rowcnt INT=0
DECLARE @Begin		DATETIME
DECLARE @Duration	INT

WHILE (1 = 1)
BEGIN	
	DECLARE @Msg VARCHAR(200)
	
	UPDATE  TOP(1) #temp
	SET		@site = SITE  
			,IsFinished = 1
	FROM	#temp
	WHERE	IsFinished = 0

	SELECT @Rowcnt = @@ROWCOUNT	
	IF @Rowcnt = 0 RETURN
	
	SET @Begin= GETDATE()
	PRINT 'CHECK Setting on SITE ' +@site 
	--PRINT '										Duration Begin :' + CONVERT(VARCHAR(100),DATEDIFF(second,@Begin,GETDATE()))

	EXEC dbo.DBA_CheckPT_Dep  @sporttype = -1,@site = @site

	EXEC dbo.DBA_CheckComm_Dep  @sporttype = -1 ,@site = @site

	PRINT '										Duration:' + CONVERT(VARCHAR(100),DATEDIFF(second,@Begin,GETDATE()))
 
	--WAITFOR DELAY '00:00:01'

END

GO
 