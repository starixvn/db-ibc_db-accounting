



ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update PT setting to zero for 12bet racing products
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('Dep_Custsetting3rd') AND type = 'U') <> 1
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

	UPDATE Dep_Custsetting3rd WITH(ROWLOCK,UPDLOCK)
	SET apositiontaking = 0,
		mpositiontaking = 0,
		spositiontaking = 0
	WHERE custid IN (SELECT * FROM @res)
	AND sporttype IN (151,152,153)		
	
END

GO


declare @maxCustid int 
set @maxCustid = XXX


create table #temp (custid int primary key, isfinished bit)

INSERT INTO #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM custinfo c WITH(NOLOCK)
WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('12BET'))
	AND roleid IN (1,2)
	AND (	apositiontaking = 0,
			OR mpositiontaking = 0,
			OR spositiontaking = 0
		)
	AND c.custid <= @maxCustid
go

/*
	total customers		: 185320 
	total rows affected	: 2223840 (each customer get 12 rows)
*/

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (1000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount	

	EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 1000 RETURN

	WAITFOR DELAY '00:00:01'
end
