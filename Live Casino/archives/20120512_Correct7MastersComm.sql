 

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*	
	topic: http://ccs.nexcel.vn/viewtopic.php?p=31198#p31198
*/
BEGIN

	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsettingGame') AND type = 'U') <> 1
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
		

	UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
	SET adiscount = 0,
		discount = 0,
		playerdiscount = 0
	WHERE custid IN (select custid from @res)  --- master
		AND sporttype = 162 AND bettype = 1101	
END

GO


----------------

DECLARE @directmaster TABLE(custid INT)
INSERT INTO @directmaster
		  SELECT 	141452	----	M09RM
UNION ALL SELECT 	11266	----	M6BP
UNION ALL SELECT 	819161	----	M79AH
UNION ALL SELECT 	691593	----	M79AR
UNION ALL SELECT 	801965	----	M863RMB
UNION ALL SELECT 	764760	----	MKPRM
UNION ALL SELECT 	169526	----	MMYBSD

--------------------------
declare @maxCustid int
set @maxCustid = 6657310

create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select c.custid, 0
from custinfo c with(nolock)
where mrecommend IN (select custid from @directmaster) and custid <= @maxCustid
	and roleid = 1



-- run

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (10000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount
	
	EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 10000 RETURN
	WAITFOR DELAY '00:00:03'
end

