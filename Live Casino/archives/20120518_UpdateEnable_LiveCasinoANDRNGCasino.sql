 

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*
	enabled RNG casino & LiveCasino for required supers	
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
	SET SyncLiveCasino = 1,
		DisableLiveCasino = 0,
		SyncCasino=1,
		DisableCasino=0
	WHERE custid IN (select * from @res)
	
END

GO
	DECLARE @reqSupers TABLE (custid INT)

	INSERT INTO @reqSupers
		  SELECT 	5480712	--	AZ1
UNION ALL SELECT 	5480716	--	AZ2
UNION ALL SELECT 	5480721	--	AZ3
UNION ALL SELECT 	5480731	--	AZ4
UNION ALL SELECT 	4873460	--	BC
UNION ALL SELECT 	5241927	--	BC1
UNION ALL SELECT 	5241945	--	BC2
UNION ALL SELECT 	5241964	--	BC3
UNION ALL SELECT 	5311953	--	BC5
UNION ALL SELECT 	5311961	--	BC6
UNION ALL SELECT 	5311965	--	BC7
UNION ALL SELECT 	5362682	--	BC8
UNION ALL SELECT 	5362687	--	BC9
UNION ALL SELECT 	5362694	--	BCA
UNION ALL SELECT 	4908230	--	BD
UNION ALL SELECT 	4947571	--	BE
UNION ALL SELECT 	4996099	--	BG
UNION ALL SELECT 	5015348	--	BH
UNION ALL SELECT 	4870143	--	BK
UNION ALL SELECT 	5015371	--	BL
UNION ALL SELECT 	5060788	--	BM
UNION ALL SELECT 	5060793	--	BN
UNION ALL SELECT 	5108723	--	BO
UNION ALL SELECT 	5108730	--	BP
UNION ALL SELECT 	5108737	--	BR
UNION ALL SELECT 	5160159	--	BX
UNION ALL SELECT 	5160163	--	BY
UNION ALL SELECT 	5160175	--	BZ
UNION ALL SELECT 	5362712	--	EA1
UNION ALL SELECT 	5362720	--	EA2
UNION ALL SELECT 	5362724	--	EA3
UNION ALL SELECT 	5362729	--	EA4
UNION ALL SELECT 	5718827	--	EA6
UNION ALL SELECT 	5718831	--	EA7
UNION ALL SELECT 	5718851	--	EAA
UNION ALL SELECT 	6456973	--	EEA
UNION ALL SELECT 	4870194	--	HC
UNION ALL SELECT 	4841141	--	QC
UNION ALL SELECT 	4815149	--	QT
UNION ALL SELECT 	4833640	--	QU
UNION ALL SELECT 	4900076	--	QV
UNION ALL SELECT 	3967000	--	XXA


create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT c.custid, 0
FROM customer c WITH(NOLOCK)
	INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid  --- use index on dbo.customer.srecommend 
WHERE c.srecommend IN (SELECT custid FROM @reqSupers)	
	AND c.custid <=6911977
	AND ( ci.syncLiveCasino =0 OR ci.syncCasino =0 OR ci.DisableLiveCasino = 1 OR ci.DisableCasino = 1)


--

CREATE table #tmpScript (id INT IDENTITY(1,1), s VARCHAR(MAX))
--

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

	--EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 5000 RETURN

	--WAITFOR DELAY '00:00:03'
end

--CHECKING 
--SELECT top 10 *
--FROM #tmpScript 
--WHERE S not LIKE '%GO'



