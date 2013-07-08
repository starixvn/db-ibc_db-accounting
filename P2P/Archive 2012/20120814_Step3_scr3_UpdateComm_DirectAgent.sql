

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update P2P comm setting
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
	SET sdiscount = CASE WHEN roleid = 1 THEN 0.55 ELSE 0 END,
		adiscount = CASE WHEN roleid = 1 THEN 0.55 ELSE 0 END,
		discount  = 0.4,
		playerdiscount = 0	
	FROM P2PGroupComm p
		INNER JOIN custinfo c WITH(NOLOCK) ON p.custid = c.custid
	WHERE c.custid IN (SELECT * FROM @res)
		
END

GO

DECLARE @dAgent TABLE(custid INT)
	INSERT INTO @dAgent
			  SELECT 1376571	 -- ADBP
	UNION ALL SELECT 122300	 -- 8188BP
	UNION ALL SELECT 966789	 -- 666ius
	UNION ALL SELECT 7984	 -- 6666US
	UNION ALL SELECT 5933788	 -- A31U
	UNION ALL SELECT 577870	 -- 9222EU
	UNION ALL SELECT 1038818	 -- TBT
	UNION ALL SELECT 4487220	 -- ANT
	UNION ALL SELECT 4776071	 -- A7US
	UNION ALL SELECT 102085	 -- CBUS
	UNION ALL SELECT 174095	 -- 6666AUD
	UNION ALL SELECT 9515	 -- LUKUS
	UNION ALL SELECT 1038826	 -- TBI
	UNION ALL SELECT 5106	 -- VT1US
	UNION ALL SELECT 2831919	 -- 312BP
	UNION ALL SELECT 9636	 -- 6666EU
	UNION ALL SELECT 3522681	 -- APEU
	UNION ALL SELECT 2430074	 -- 6666AEU
	UNION ALL SELECT 3023	 -- 6666BP
	UNION ALL SELECT 2460833	 -- ASA
	UNION ALL SELECT 210710	 -- CJEU

DECLARE @maxCustID INT
SET @maxCustID = xxx

--DROP TABLE #temp
create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select DISTINCT c.custid, 0
FROM custinfo c with(nolock)
	INNER JOIN dbo.P2PGroupComm p ON c.custid = p.custid 
WHERE recommend IN (SELECT custid FROM @dAgent)
	AND (	sdiscount <> 0 OR 
			adiscount <> 0 OR 
			discount <> 0.4 OR 
			playerdiscount <> 0
		)
AND roleid = 2 

insert into #temp (custid, isfinished)
select DISTINCT c.custid, 0
FROM custinfo c with(nolock)
	INNER JOIN dbo.P2PGroupComm p ON c.custid = p.custid 
WHERE recommend IN (SELECT custid FROM @dAgent)
	AND (	sdiscount <> 0.55 OR 
			adiscount <> 0.55 OR 
			discount <> 0.4 OR 
			playerdiscount <> 0
		)
AND roleid = 1 
AND c.custid <= @maxCustID

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
