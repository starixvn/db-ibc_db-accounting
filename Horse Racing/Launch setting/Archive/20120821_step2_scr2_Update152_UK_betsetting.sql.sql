


ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update bet setting 152 UK for 12bet, fun88, dafabet
	
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsetting3rd') AND type = 'U') <> 1
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

	UPDATE g WITH(ROWLOCK,UPDLOCK)	
	SET g.minbet = r.minbet,
		g.maxbet = r.maxbet
	FROM custsetting3rd g 
		INNER JOIN custsetting3rd r WITH(NOLOCK) ON g.custid = r.custid AND g.bettype = r.bettype
	WHERE g.custid IN (SELECT * FROM @res)
		AND g.sporttype = 152 AND g.bettype BETWEEN 41 AND 42
		AND r.sporttype = 151 AND r.bettype BETWEEN 41 AND 42
	
END

go


declare @maxCustid int 
set @maxCustid = xxx


create table #temp (custid int primary key, isfinished bit)

INSERT INTO #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM custinfo c with(nolock)
	inner join custsetting3rd g with(nolock) on c.custid = g.custid
	INNER JOIN custsetting3rd r WITH(NOLOCK) ON g.custid = r.custid AND g.bettype = r.bettype
WHERE c.srecommend IN (	SELECT * FROM dbo.f_depsuper_1('12BET')
						UNION ALL
						SELECT * FROM dbo.f_depsuper_1('AsiaBet88')
						UNION ALL
						SELECT * FROM dbo.f_depsuper_1('Alog')
					  )
	AND g.sporttype = 152 AND g.bettype BETWEEN 41 AND 42
	AND r.sporttype = 151 AND r.bettype BETWEEN 41 AND 42
	and (
			g.minbet <> r.minbet or
			g.maxbet <> r.maxbet			
		)
	and c.custid <= @maxCustid
go

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

	EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 5000 RETURN

	WAITFOR DELAY '00:00:01'
end



