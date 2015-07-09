



ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update P2P comm setting
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('P2PGroupComm') AND type = 'U') <> 1
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
	
		
	UPDATE P2PGroupComm WITH(ROWLOCK,UPDLOCK)
	SET sdiscount = 0.67,
		adiscount = 0,
		discount  = 0,
		playerdiscount = 0	
	WHERE custid IN (SELECT * FROM @res)
		
END

GO


DECLARE @specialComm TABLE(custid INT, roleid INT)

INSERT INTO @specialComm
		  SELECT 1584509	, 4	-- BA
UNION ALL SELECT 2430074	, 2	-- 6666AEU
UNION ALL SELECT 3144218	, 3	-- JPG
UNION ALL SELECT 3023		, 2	-- 6666BP
UNION ALL SELECT 3139575	, 4	-- SF8
UNION ALL SELECT 549191		, 4	-- S6RUP
UNION ALL SELECT 706886		, 4	-- S6US
UNION ALL SELECT 835418		, 4	-- S6ARUP
UNION ALL SELECT 2078394	, 4	-- DA
UNION ALL SELECT 966789		, 2	-- 666ius
UNION ALL SELECT 5957920	, 4	-- VF
UNION ALL SELECT 58969		, 3	-- M6ARUP
UNION ALL SELECT 60809		, 3	-- M6BRUP
UNION ALL SELECT 5711971	, 4	-- S6BP
UNION ALL SELECT 5969746	, 4	-- GA
UNION ALL SELECT 31073		, 3	-- M6IRUP
UNION ALL SELECT 4548911	, 4	-- VC
UNION ALL SELECT 5938255	, 4	-- VM
UNION ALL SELECT 1575555	, 4	-- AA
UNION ALL SELECT 4505274	, 4	-- FA
UNION ALL SELECT 5931006	, 4	-- VD
UNION ALL SELECT 7984		, 2	-- 6666US
UNION ALL SELECT 9636		, 2	-- 6666EU
UNION ALL SELECT 11266		, 3	-- M6BP
UNION ALL SELECT 527906		, 4	-- S6EU



create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select custid, 0
FROM custinfo with(nolock)
where srecommend IN (select custid from @specialComm where roleid = 4)
	and roleid in (1,4)
	and custid <= @maxcustid 

GO

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


