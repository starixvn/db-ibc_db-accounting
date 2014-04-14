USE CheckResultDB

SET NOCOUNT ON  

IF OBJECT_ID('tempdb..#temp') IS NOT NULL		DROP TABLE #temp

---- Execute 
CREATE TABLE #temp (SITE VARCHAR(100),IsFinished BIT)

TRUNCATE TABLE CheckResultDB.[dbo].[CheckPTResult_Deposit]
TRUNCATE TABLE CheckResultDB.dbo.CheckCommResult_Deposit

INSERT  INTO #temp (SITE,IsFinished)
SELECT LicenseeName,0 FROM DBLIC.bodb_licensee.dbo.Licensees li WITH(NOLOCK)

DECLARE @site VARCHAR(100),@Rowcnt INT,@srecommend VARCHAR(1000)
DECLARE @Begin		DATETIME,@page_number_from INT,@page_number_to INT,@page_length INT

DECLARE @Duration	INT

SELECT @page_length=10

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
	
	PRINT 'CHECK Setting on SITE ' +@site 
	--PRINT '										Duration Begin :' + CONVERT(VARCHAR(100),DATEDIFF(second,@Begin,GETDATE()))

	SELECT @page_number_from=COUNT(1)
	FROM CheckCustDB.dbo.Dep_CustSuper tbl WITH(NOLOCK)		
	Where Site = @Site AND Currency <> 20

	IF @page_length>1
	BEGIN
		SELECT @page_number_to=(@page_number_from/@page_length)+CASE WHEN @page_number_from%@page_length<>0 THEN 1 ELSE 0 END
		SELECT @page_number_from=0
	END
	ELSE
	BEGIN
		SELECT @page_number_to=@page_number_from+1
		SELECT @page_number_from=1
	END

	WHILE (@page_number_to>@page_number_from)
	BEGIN

		SELECT @srecommend='',@Begin= GETDATE()
		;WITH CTE AS
			(
				SELECT 
					Row_Number() OVER (ORDER BY Custid desc) as row_num
					,Custid 
				FROM CheckCustDB.dbo.Dep_CustSuper tbl WITH(NOLOCK)		
				Where Site = @Site AND Currency <> 20
			)
			Select @srecommend = COALESCE(@srecommend + ',', '') + convert(NVARCHAR(50),ISNULL(CTE.Custid,'')) 
			FROM CTE
			WHERE row_num >= 
				(@page_number_from)*@page_length 
				AND row_num <(@page_number_from+1)*@page_length
		
		SELECT @srecommend=CASE WHEN LEFT(@srecommend,1)=',' THEN RIGHT(@srecommend,LEN(@srecommend)-1) ELSE @srecommend END

		EXEC dbo.DBA_CheckPT_Dep  @sporttype = -1,@site = @site,@srecommend=@srecommend

		EXEC dbo.DBA_CheckComm_Dep  @sporttype = -1 ,@site = @site,@srecommend=@srecommend

		PRINT '										Duration:' + CONVERT(VARCHAR(100),DATEDIFF(second,@Begin,GETDATE())) + ' second for srecommend:' + @srecommend
		
		SELECT @page_number_from=@page_number_from+1
	END
 
	--WAITFOR DELAY '00:00:01'

END

GO
 