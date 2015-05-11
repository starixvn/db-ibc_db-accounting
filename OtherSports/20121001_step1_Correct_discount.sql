



ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*
	correct discount on member: set discount = playerdiscount
*/
BEGIN
	SET NOCOUNT ON 
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsetting') AND type = 'U') <> 1
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

	UPDATE custsetting WITH(ROWLOCK,UPDLOCK)
	SET discount = playerdiscount
	WHERE sporttype = 99 AND bettype = 9
		AND custid IN (select * from @res)
	
END
GO


create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT c.custid, 0
FROM custsetting cs WITH(NOLOCK)
	INNER JOIN custinfo c WITH(NOLOCK) ON cs.custid = c.custid
WHERE c.roleid = 1
AND sporttype = 99 AND bettype = 9
AND playerdiscount > discount


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
