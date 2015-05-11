
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	set Live Casino PT setting for 12BET agent: 93%
*/
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsettinggame') AND type = 'U') <> 1
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

	UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
	SET spositiontaking = 0,
		mpositiontaking = 0,
		apositiontaking = 0.93
	WHERE sporttype = 162 AND bettype = 1101
		AND custid in (select * from @res)	

END

--drop table #temp
CREATE TABLE #temp (custid int primary key, isfinished bit)


DECLARE @maxCustID INT
SET @maxCustID = 1200000000


INSERT INTO #temp (custid, isfinished)
SELECT c.custid, 0
FROM custinfo c WITH(NOLOCK)
WHERE srecommend IN (SELECT custid FROM f_depsuper_1('12bet'))
AND mrecommend NOT IN (
						791048	,--- 12BETACCUS$
						791052	,--- 12BETACCEURO
						832125	,--- 12BETACCTB
						835094	,--- 12BETACCGBP
						835036	,--- 12BETACCRM
						835044	,--- 12BETACCRMB
						1255629	,--- 12BETACCUUS
						1015436	,--- 12BETACCAUD
						1015563	,--- 12BETACCCHF
						1752427	,--- 12BETACCSD$
						1813588	,--- 12BETACCIN
						3167467	,--- 12BETACCINH
						6006581	,--- 12BETACCWON
						6006552	,--- 12BETACCINR
						6006574	,--- 12BETACCJPY
						7526067	,--- 12BETACCHK$
						927780  --- 12BETAFF
					)
AND roleid = 1
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

