


ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update P2P comm setting for special request
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('P2PGroupComm','custinfo') AND type = 'U') <> 2
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
	
		
	UPDATE p WITH(ROWLOCK,UPDLOCK)
	SET sdiscount = CASE WHEN roleid IN (1,4) THEN 0.67 ELSE 0 END,
		adiscount = 0,
		discount  = 0,
		playerdiscount = 0	
	FROM P2PGroupComm p
		INNER JOIN custinfo c WITH(NOLOCK) ON p.custid = c.custid
	WHERE c.custid IN (SELECT * FROM @res)
		
END

GO

DECLARE @specialSuper TABLE (custid INT)
		INSERT INTO @specialSuper
				  SELECT 706886	 -- S6US
		UNION ALL SELECT 835418	 -- S6ARUP
		UNION ALL SELECT 5711971	 -- S6BP
		UNION ALL SELECT 527906	 -- S6EU
		UNION ALL SELECT 5931006	 -- VD
		UNION ALL SELECT 1584509	 -- BA
		UNION ALL SELECT 1575555	 -- AA
		UNION ALL SELECT 4505274	 -- FA
		UNION ALL SELECT 5957920	 -- VF
		UNION ALL SELECT 549191	 -- S6RUP
		UNION ALL SELECT 2078394	 -- DA
		UNION ALL SELECT 5938255	 -- VM
		UNION ALL SELECT 3139575	 -- SF8
		UNION ALL SELECT 5969746	 -- GA
		UNION ALL SELECT 4548911	 -- VC


DECLARE @maxCustID INT
SET @maxCustID = 7880186
--DROP TABLE #temp
create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select DISTINCT c.custid, 0
FROM custinfo c with(nolock)
	INNER JOIN dbo.P2PGroupComm p ON c.custid = p.custid 
WHERE srecommend IN (SELECT custid FROM @specialSuper)
	AND (	sdiscount <> 0.67 OR 
			adiscount <> 0 OR 
			discount <> 0 OR 
			playerdiscount <> 0
		)
AND roleid = 4 

insert into #temp (custid, isfinished)
select DISTINCT c.custid, 0
FROM custinfo c with(nolock)
	INNER JOIN dbo.P2PGroupComm p ON c.custid = p.custid 
WHERE srecommend IN (SELECT custid FROM @specialSuper)
	AND (	sdiscount <> 0 OR 
			adiscount <> 0 OR 
			discount <> 0 OR 
			playerdiscount <> 0
		)
AND roleid IN (2,3) 
AND c.custid > @maxCustID

insert into #temp (custid, isfinished)
select DISTINCT c.custid, 0
FROM custinfo c with(nolock)
	INNER JOIN dbo.P2PGroupComm p ON c.custid = p.custid 
WHERE srecommend IN (SELECT custid FROM @specialSuper)
	AND (	sdiscount <> 0.67 OR 
			adiscount <> 0 OR 
			discount <> 0 OR 
			playerdiscount <> 0
		)
AND roleid = 1
AND c.custid > @maxCustID
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


