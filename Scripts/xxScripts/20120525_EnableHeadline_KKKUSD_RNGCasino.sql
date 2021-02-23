


ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*	
	topic: http://ccs.nexcel.vn/viewtopic.php?f=35&t=6660&start=0&st=0&sk=t&sd=a
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
	SET DisableCasino = 0,
		syncCasino = 1
	WHERE custid IN (select custid from @res) 
		
END

DECLARE @super TABLE (custid INT)
INSERT INTO @super
		  SELECT 	3412762	----	SHB
UNION ALL SELECT 	3508886	----	SHD
UNION ALL SELECT 	2853316	----	SKAE
UNION ALL SELECT 	3024027	----	SKAI
UNION ALL SELECT 	3472732	----	SKAP
UNION ALL SELECT 	4664111	----	skay
UNION ALL SELECT 	1727939	----	SKD
UNION ALL SELECT 	2462931	----	SKK
UNION ALL SELECT 	1727945	----	SKKD
UNION ALL SELECT 	731165	----	SKKS
UNION ALL SELECT 	923727	----	SKS


create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select c.custid, 0
from custinfo c with(nolock)
where srecommend IN (select custid from @super) and custid <= xxx
	and (DisableCasino = 1 OR syncCasino = 0)
-- run

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
	WAITFOR DELAY '00:00:03'
end


