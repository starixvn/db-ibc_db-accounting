 
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	Correct mixparlay commission
*/
BEGIN
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
			
	UPDATE mp WITH(ROWLOCK,UPDLOCK)
	SET mp.playerdiscount = cs.playerdiscount
	FROM custsetting mp
		INNER JOIN CustSetting cs WITH(NOLOCK) ON mp.custid = cs.custid		
	WHERE mp.custid IN (SELECT * FROM @res)	
	AND cs.sporttype = 1 AND cs.bettype = 4
	AND mp.sporttype = 99 AND mp.bettype = 9
	
END

--drop table #temp
CREATE TABLE #temp (custid int primary key, isfinished bit)
DECLARE @maxCustID INT
SET @maxCustID = 1200000000

INSERT INTO #temp (custid, isfinished)
SELECT c.custid, 0
from custInfo c with(nolock)
	inner join CustSetting cs with(nolock) on  c.custid = cs.custid
	inner join custsetting mp with(nolock) on cs.custid = mp.custid
where c.roleid = 1 and c.srecommend not in (select custid from f_DepSuper_1('all'))
	and cs.sporttype = 1 and cs.bettype = 4
	and mp.sporttype = 99 and mp.bettype = 9
	and cs.playerdiscount <> mp.playerdiscount
	AND c.custid <= @maxCustID


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
	WAITFOR DELAY '00:00:01'
end

