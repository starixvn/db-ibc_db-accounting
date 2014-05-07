USE CheckResultDB
/*
	Created: 20140215@Tom.Vo
		
	Revisions:
		-2014.04.22@Tom.Vo: Change source table : DBLIC.Licensee -> CheckLicenseeDB
*/
SET NOCOUNT ON  

IF OBJECT_ID('tempdb..#temp') IS NOT NULL		DROP TABLE #temp

---- Execute 
CREATE TABLE #temp (SITE VARCHAR(100),IsFinished BIT)

TRUNCATE TABLE CheckResultDB.[dbo].[CheckPTResult_Deposit]
TRUNCATE TABLE CheckResultDB.dbo.CheckCommResult_Deposit

INSERT  INTO #temp (SITE,IsFinished)
SELECT LicenseeName,0 FROM CheckLicenseeDB.dbo.Licensees li WITH(NOLOCK) WHERE LicenseeName = '12Bet'

DECLARE @site VARCHAR(100),@Rowcnt INT,@srecommend VARCHAR(1000)
DECLARE @Begin		DATETIME,@BeginSite		DATETIME,@page_number_from INT,@page_number_to INT,@page_length INT

DECLARE @Duration	INT

SELECT @page_length=10

SELECT @BeginSite=GETDATE()

DECLARE @RestoreCustDB SmallDateTime='2014-04-10'

SELECT @RestoreCustDB = CONVERT(Varchar(10),@RestoreCustDB,101)

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

	SELECT @page_number_from=COUNT(1)
	FROM CheckCustDB.dbo.Dep_CustSuper tbl WITH(NOLOCK)		
	Where Site = @Site AND Currency NOT IN (20,27,28)

	SELECT @page_number_to=(@page_number_from/@page_length)+CASE WHEN @page_number_from%@page_length<>0 THEN 1 ELSE 0 END
	SELECT @page_number_from=0

	WHILE (@page_number_to>@page_number_from)
	BEGIN

		SELECT @srecommend='',@Begin= GETDATE()
		;WITH CTE AS
			(
				SELECT 
					Row_Number() OVER (ORDER BY Custid desc) as row_num
					,Custid 
				FROM CheckCustDB.dbo.Dep_CustSuper tbl WITH(NOLOCK)		
				Where Site = @Site AND Currency NOT IN (20,27,28)
			)
			Select @srecommend = COALESCE(@srecommend + ',', '') + convert(NVARCHAR(50),ISNULL(CTE.Custid,'')) 
			FROM CTE
			WHERE row_num >= 
				(@page_number_from*@page_length +1)
				AND row_num <=(@page_number_from+1)*@page_length
		
		SELECT @srecommend=CASE WHEN LEFT(@srecommend,1)=',' THEN RIGHT(@srecommend,LEN(@srecommend)-1) ELSE @srecommend END

		EXEC dbo.DBA_CheckPT_Dep @RestoreCustDB = @RestoreCustDB, @sporttype = -1,@site = @site,@srecommend=@srecommend

		EXEC dbo.DBA_CheckComm_Dep  @RestoreCustDB = @RestoreCustDB,@sporttype = -1 ,@site = @site,@srecommend=@srecommend

		PRINT '										Duration:' + CONVERT(VARCHAR(100),DATEDIFF(second,@Begin,GETDATE())) + ' second for srecommend:' + @srecommend
		
		SELECT @page_number_from=@page_number_from+1
	END
 
	PRINT '						Duration ' + @site +' : ' + CONVERT(VARCHAR(100),DATEDIFF(second,@BeginSite,GETDATE()))

	--WAITFOR DELAY '00:00:01'

END

GO
 