

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*	
	Disable P2P game for all customer before offering by batches
*/
BEGIN

	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custinfo') AND type = 'U') <> 1
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
		

	UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
	SET DisableP2P = 1		
	WHERE custid IN (select custid from @res) 
		
END



create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select c.custid, 0
from custinfo c with(nolock)
where DisableP2P = 0 
		AND SRecommend NOT IN (
				6173539, --LC-RM
				1373389, --TESTCS
				615976,  --ACGUUS
				1426163	 --U3S 
			)
		AND Recommend NOT IN (98626) --billma01 (RM)
		AND custid <= xxx
-- run

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
	
	--EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 5000 RETURN
	--WAITFOR DELAY '00:00:03'
end

--CHECKING 
--SELECT top 10 *
--FROM #tmpScript 
--WHERE S not LIKE '%GO'

