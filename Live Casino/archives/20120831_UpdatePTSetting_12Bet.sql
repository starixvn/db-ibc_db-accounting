ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update Live casino PT setting 
	
*/
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsettingGame','custsetting') AND type = 'U') <> 2
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

	UPDATE cg WITH(ROWLOCK,UPDLOCK)
	SET cg.apositiontaking		= cs.alivepositiontaking,
		cg.mpositiontaking		= cs.mlivepositiontaking,
		cg.spositiontaking		= cs.slivepositiontaking,
		cg.autopositiontaking	= cs.autolivepositiontaking,		
		cg.isautopositiontaking = cs.isautolivepositiontaking,
		cg.autompositiontaking	= cs.autolivempositiontaking,
		cg.isautompositiontaking= cs.isautolivempositiontaking
	FROM custsettingGame cg 
		INNER JOIN custsetting cs WITH(NOLOCK) ON cg.custid = cs.custid and cs.sporttype = 1 AND cs.bettype = 1
	WHERE cg.sporttype = 162 AND cg.bettype = 1101		
		AND cg.custid in (select * from @res)	
	
END


CREATE TABLE #temp (custid int primary key, isfinished bit)
DECLARE @maxCustID INT
SET @maxCustID = xxx

INSERT INTO #temp (custid, isfinished)
SELECT custid, 0
FROM custinfo WITH(NOLOCK)
WHERE srecommend IN (SELECT custid FROM dbo.f_depsuper_1('ALL'))
AND custid <= @maxCustID

--

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

