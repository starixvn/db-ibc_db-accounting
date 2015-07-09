

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
	SET sdiscount = CASE WHEN roleid IN (1,4) THEN 0.67 ELSE 0 END,
		adiscount = CASE WHEN roleid IN (1,3) THEN 0.55 ELSE 0 END,
		discount  = 0,
		playerdiscount = 0	
	FROM P2PGroupComm p 
		INNER JOIN custinfo c WITH(NOLOCK) ON p.custid = c.custid
	WHERE c.custid IN (SELECT * FROM @res)
		
END

GO

DECLARE @maxCustID INT

SET @maxCustID = 7880186

create table #temp (custid int primary key, isfinished bit)
--DROP TABLE #temp
INSERT INTO #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM custinfo c WITH(NOLOCK)
	INNER JOIN dbo.P2PGroupComm p WITH(NOLOCK) ON c.custid = p.custid
WHERE currency IN (	3,    --US$
					4,    --TB
					5,    --HK$
					6,    --EURO
					9,    --AUD
					12,    --GBP
					13,    --RMB
					15,    --IN
					16,    --Yen
					17,    --NTD
					22,    --IND
					30,    --NT
					31,    --Pts
					32,    --JPY
					33,    --IDD
					34,    --IDR
					35,    --$US
					37,    --P
					40,    --IRR
					43,    --THB
					44,    --PT
					45,    --Won
					47,    --DDD
					62    --KW
					)
AND srecommend NOT IN (SELECT custid FROM dbo.f_DepSuper_1('all')
					   UNION ALL
					   SELECT custid FROM custinfo WITH(NOLOCK)
					   WHERE username LIKE '3rdSuper%'
					   )
AND (
		sdiscount <> 0.67 OR 
		adiscount <> 0 OR 
		discount <> 0 OR 
		playerdiscount <> 0
	)
AND roleid = 4
AND c.srecommend > 100
AND c.custid > @maxCustID


INSERT INTO #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM custinfo c WITH(NOLOCK)
	INNER JOIN dbo.P2PGroupComm p WITH(NOLOCK) ON c.custid = p.custid
WHERE currency IN (	3,    --US$
					4,    --TB
					5,    --HK$
					6,    --EURO
					9,    --AUD
					12,    --GBP
					13,    --RMB
					15,    --IN
					16,    --Yen
					17,    --NTD
					22,    --IND
					30,    --NT
					31,    --Pts
					32,    --JPY
					33,    --IDD
					34,    --IDR
					35,    --$US
					37,    --P
					40,    --IRR
					43,    --THB
					44,    --PT
					45,    --Won
					47,    --DDD
					62    --KW
					)
AND srecommend NOT IN (SELECT custid FROM dbo.f_DepSuper_1('all')
					   UNION ALL
					   SELECT custid FROM custinfo WITH(NOLOCK)
					   WHERE username LIKE '3rdSuper%'
					   )
AND (
		sdiscount <> 0 OR 
		adiscount <> 0.55 OR 
		discount <> 0 OR 
		playerdiscount <> 0
	)
AND roleid = 3
AND c.srecommend > 100
AND c.custid > @maxCustID


INSERT INTO #temp (custid, isfinished)
SELECT DISTINCT c.custid, 0
FROM custinfo c WITH(NOLOCK)
	INNER JOIN dbo.P2PGroupComm p WITH(NOLOCK) ON c.custid = p.custid
WHERE currency IN (	3,    --US$
					4,    --TB
					5,    --HK$
					6,    --EURO
					9,    --AUD
					12,    --GBP
					13,    --RMB
					15,    --IN
					16,    --Yen
					17,    --NTD
					22,    --IND
					30,    --NT
					31,    --Pts
					32,    --JPY
					33,    --IDD
					34,    --IDR
					35,    --$US
					37,    --P
					40,    --IRR
					43,    --THB
					44,    --PT
					45,    --Won
					47,    --DDD
					62    --KW
					)
AND srecommend NOT IN (SELECT custid FROM dbo.f_DepSuper_1('all')
					   UNION ALL
					   SELECT custid FROM custinfo WITH(NOLOCK)
					   WHERE username LIKE '3rdSuper%'
					   )
AND (
		sdiscount <> 0.67 OR 
		adiscount <> 0.55 OR 
		discount <> 0 OR 
		playerdiscount <> 0
	)
AND roleid = 1
AND c.srecommend > 100
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

