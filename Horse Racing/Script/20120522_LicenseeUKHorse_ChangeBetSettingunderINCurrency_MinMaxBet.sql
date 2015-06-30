/*
	Change Min/Max bet for UK Horse Racing for Licensee under IN currency 

*/

	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
		@ids varchar(max)
	AS

	/*
		enabled Live casino for required supers	
	*/
	BEGIN
		SET NOCOUNT ON 

		IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('CustSetting3rd') AND type = 'U') <> 1
			RETURN

		DECLARE @res AS TABLE (custid INT)
		DECLARE @splitter CHAR(1), @string VARCHAR(MAX)

		SELECT @splitter = ',', @string = @ids

		IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
			  SET @string= @string+@splitter

		DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
		SET @i=1
		SET @START=1
		SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
		WHILE (@CHARINDEX <> 0)BEGIN
			SET @word= SUBSTRING( @string, @START, @CHARINDEX - @START)
			SET @START= @CHARINDEX +1
			SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
			INSERT INTO @res  VALUES(CAST(@word AS INT))
			SET @i=@i+1
		END

		UPDATE CustSetting3rd WITH (UPDLOCK,ROWLOCK)
        SET		minbet = 100,
				maxbet = 120000
        WHERE	custid IN (select * from @res)
				AND sporttype =151
				AND bettype BETWEEN 41 AND 42  
		
	END
	GO

----DECLARE @MinBet MONEY,
----        @MaxBet MONEY,
----        @MaxperMatch MONEY
----
----SELECT    @MinBet = 100,
----        @MaxBet = 120000,
----        @MaxperMatch = 240000



create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM CustSetting3rd c WITH (NOLOCK)
WHERE custid IN (
        SELECT  CustID
        FROM    custInfo WITH (NOLOCK)
        WHERE    srecommend IN (
            1574102    , --    MS88SuperIN
            3544377    , --    MFSuperIN
            3544783    , --    SUGSuperIN
            3670780    , --    BEZBETSuperIN
            3782799    , --    AlogSuperIN
            6446438      --    TycoonSuperIN
        )
     )
    AND ( minbet <> 100 OR maxbet <> 120000)
    AND sporttype =151
    AND bettype BETWEEN 41 AND 42 
	AND CustID <=7132512


--
CREATE TABLE #tmpScript (ID INT IDENTITY(1,1), s varchar(MAX))

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (5000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount

	INSERT INTO #tmpScript (s)
	
	SELECT ' EXEC [Acc_ExecRep_09] @ids =' +'''' + @ids +''' GO'
	
------	EXEC [Acc_ExecRep_09] @ids = @ids
------	
------	print  @ids
	
	if @rowcnt < 5000 RETURN
	--WAITFOR DELAY '00:00:03'
end


--CHECKING 
--SELECT top 10 *
--FROM #tmpScript 
--WHERE S not LIKE '%GO'

