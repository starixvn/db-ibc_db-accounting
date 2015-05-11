


ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*
	enabled Live casino for required supers	
*/
BEGIN
	SET NOCOUNT ON 
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
	SET DisableLiveCasino = 1,
		DisableCasino = 1
	WHERE custid IN (select * from @res)
	
END
GO


DECLARE @reqSupers TABLE (custid INT)

	INSERT INTO @reqSupers
		  SELECT	262627	----	SCC
UNION ALL SELECT	262637	----	SCK
UNION ALL SELECT	391471	----	VIP
UNION ALL SELECT	687607	----	SKKC
UNION ALL SELECT	731165	----	SKKS
UNION ALL SELECT	923727	----	SKS
UNION ALL SELECT	1335772	----	SKT
UNION ALL SELECT	1435478	----	VID
UNION ALL SELECT	1727939	----	SKD
UNION ALL SELECT	1727945	----	SKKD
UNION ALL SELECT	1898175	----	SKW
UNION ALL SELECT	1940367	----	SKX
UNION ALL SELECT	1977102	----	SKE
UNION ALL SELECT	1978806	----	SKH
UNION ALL SELECT	1999503	----	SKY
UNION ALL SELECT	2113740	----	SKI
UNION ALL SELECT	2126540	----	SKJ
UNION ALL SELECT	2198456	----	SKA
UNION ALL SELECT	2198868	----	SKQ
UNION ALL SELECT	2462931	----	SKK
UNION ALL SELECT	2470330	----	VIU
UNION ALL SELECT	2503678	----	SKO
UNION ALL SELECT	2798869	----	SKAB
UNION ALL SELECT	2850839	----	SKAD
UNION ALL SELECT	2853316	----	SKAE
UNION ALL SELECT	3024023	----	SKAH
UNION ALL SELECT	3024027	----	SKAI
UNION ALL SELECT	3024035	----	SKAJ
UNION ALL SELECT	3122695	----	SKKA
UNION ALL SELECT	3390621	----	QVN
UNION ALL SELECT	3412762	----	SHB
UNION ALL SELECT	3472732	----	SKAP
UNION ALL SELECT	3508886	----	SHD
UNION ALL SELECT	3675856	----	SKAS
UNION ALL SELECT	4166219	----	skau
UNION ALL SELECT	4166221	----	skav
UNION ALL SELECT	4664102	----	skaw
UNION ALL SELECT	4664106	----	skax
UNION ALL SELECT	4664111	----	skay
UNION ALL SELECT	5881765	----	SKBC
UNION ALL SELECT	5881771	----	SKBD
UNION ALL SELECT	5933382	----	SKBE
UNION ALL SELECT	5933395	----	SKBF
UNION ALL SELECT	6000983	----	skbg
UNION ALL SELECT	6001004	----	skbh



create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT c.custid, 0
FROM customer c WITH(NOLOCK)
	INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid  --- use index on dbo.customer.srecommend 
WHERE c.srecommend IN (SELECT custid FROM @reqSupers)	
	AND c.custid <=6911783
	AND (ci.DisableLiveCasino = 0 OR ci.DisableCasino = 0)


--
CREATE TABLE #tmpScript (ID INT IDENTITY(1,1), s varchar(MAX))

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

	INSERT INTO #tmpScript (s)
	
	SELECT ' EXEC [Acc_ExecRep_09] @ids =' +'''' + @ids +''' GO'
	
------	EXEC [Acc_ExecRep_09] @ids = @ids
------	
------	print  @ids
	
	if @rowcnt < 5000 RETURN
	--WAITFOR DELAY '00:00:03'
end


--CHECKING 
--SELECT top 10 *
--FROM #tmpScript 
--WHERE S not LIKE '%GO'

