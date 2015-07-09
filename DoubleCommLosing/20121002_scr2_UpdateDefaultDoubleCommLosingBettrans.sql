ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@ids VARCHAR(max)
AS
/*
	--Update default setting for double comm losing in bettrans to 0
*/
SET NOCOUNT ON 
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('bettrans') AND type = 'U') <> 1
		RETURN

	DECLARE @res AS TABLE (transid BIGINT)
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
		INSERT INTO @res  VALUES(CAST(@word AS BIGINT))
		SET @i=@i+1
	END
	
	
	UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
	SET comstatus = 0
	WHERE transid IN (SELECT * FROM @res)


GO

create table #temp (transid bigint primary key, isfinished bit)

insert into #temp (transid, isfinished)
select transid, 0
from bettrans b with(nolock)
where bettype < 31 or bettype between 121 and 999

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (5000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(transid as varchar(20))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount	

	EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 5000 RETURN

	WAITFOR DELAY '00:00:01'
end

 