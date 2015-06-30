ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON
/*
	Enable VS
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
	SET  HideVirtualSports= 0,
		DisableVirtualSports=0
	WHERE custid IN (SELECT * FROM @res)		
END

GO
/*
DECLARE @customers TABLE (custid INT, roleid INT)

INSERT INTO @customers
          SELECT 747037	, 4	-- GI
UNION ALL SELECT 901858	, 4	-- ST5T


-- remember to set maxcustid
-- select min(custid),max(custid) from custinfo with(nolock) 

DECLARE @maxCustID INT
SET @maxCustID = 8143104 

--DROP TABLE #temp
create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select custid, 0
FROM custinfo c with(nolock)	
WHERE srecommend IN (SELECT custid FROM @customers WHERE roleid = 4)
	AND c.custid <= @maxCustID

insert into #temp (custid, isfinished)
select c.custid, 0
FROM custinfo c with(nolock)	
WHERE mrecommend IN (SELECT custid FROM @customers WHERE roleid = 3)
AND c.custid <= @maxCustID

insert into #temp (custid, isfinished)
select DISTINCT c.srecommend, 0
FROM custinfo c with(nolock)	
WHERE mrecommend IN (SELECT custid FROM @customers WHERE roleid = 3)
AND roleid = 3
AND srecommend NOT IN (SELECT custid FROM #temp)


insert into #temp (custid, isfinished)
select c.custid, 0
FROM custinfo c with(nolock)	
WHERE recommend IN (SELECT custid FROM @customers WHERE roleid = 2)
AND c.custid <= @maxCustID

insert into #temp (custid, isfinished)
select DISTINCT c.srecommend, 0
FROM custinfo c with(nolock)	
WHERE recommend IN (SELECT custid FROM @customers WHERE roleid = 2)
AND roleid = 2
AND srecommend NOT IN (SELECT custid FROM #temp)

insert into #temp (custid, isfinished)
select DISTINCT c.mrecommend, 0
FROM custinfo c with(nolock)	
WHERE recommend IN (SELECT custid FROM @customers WHERE roleid = 2)
AND roleid = 2
AND mrecommend NOT IN (SELECT custid FROM #temp)

--SELECT * FROM #temp

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

drop table #temp
*/