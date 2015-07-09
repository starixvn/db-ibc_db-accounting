

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update maxpermatch	
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
	SET MaxPerMatch152_UK = maxpermatch151_OT,	
		MaxPerMatch152_AU = MaxPerMatch151_AU,
		MaxPerMatch153_AU = MaxPerMatch151_AU
	WHERE custid IN (SELECT * FROM @res)
	
END

go

declare @maxCustid int 
set @maxCustid = 10000

create table #temp (custid int primary key, isfinished bit)

INSERT INTO #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM custinfo c with(nolock)	
WHERE c.srecommend IN (SELECT * FROM dbo.f_depsuper_1('12BET')
						UNION ALL
						SELECT * FROM dbo.f_depsuper_1('mansion88')
						UNION ALL
						SELECT * FROM dbo.f_depsuper_1('Alog')
						UNION ALL
						SELECT * FROM dbo.f_depsuper_1('Mayfair')
						UNION ALL 
						SELECT * FROM dbo.f_depsuper_1('AsiaBet88')
						)	
	and (
			MaxPerMatch152_UK <> maxpermatch151_OT or 
			MaxPerMatch152_AU <> MaxPerMatch151_AU or 
			MaxPerMatch153_AU <> MaxPerMatch151_AU
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


