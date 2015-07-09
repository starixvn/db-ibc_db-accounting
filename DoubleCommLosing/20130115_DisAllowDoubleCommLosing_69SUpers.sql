 ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@ids	VARCHAR(max)
 AS
 /*
	--Allow double comm losing for SMA
	--OFF double comm losing on members
 */
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
	SET DoubleCommLosing = 0
	WHERE custid IN (SELECT * FROM @res)
 
 
 GO
 
 
CREATE TABLE #temp (custid INT PRIMARY KEY, isfinished BIT)

 
DECLARE @mincustid INT,@maxcustid INT
SELECT @mincustid= 1,
	@maxcustid= 9666208 --8414563 SELECT MAX(CustID) FROM Custinfo WITH (NOLOCK) 
	

DECLARE @tmpSuper TABLE( CustID INT PRIMARY KEY)

INSERT INTO @tmpSuper(CustID)  
SELECT CustID
FROM Custinfo WITH (NOLOCK)
WHERE username IN (
'SKW ',
'SKX ',
'SKE ',
'SKF ',
'SKG ',
'SKH ',
'SKY ',
'SKZ ',
'SKI ',
'SKJ ',
'SKA ',
'SKB ',
'SKL ',
'SKQ ',
'SKK ',
'VIU ',
'SKO ',
'skn ',
'skp ',
'SKAA ',
'SKAB ',
'SKAC ',
'SKAD ',
'SKAE ',
'SKAF ',
'SKAG ',
'SKAH ',
'SKAI ',
'SKAJ ',
'SKKA ',
'QHN ',
'QVN ',
'SKAN ',
'SHB ',
'SKAO ',
'SKAP ',
'SHD ',
'SKAR ',
'SKAS ',
'SKAT ',
'skau ',
'skav ',
'skaw ',
'skax ',
'skay ',
'skaz ',
'skba ',
'skbb ',
'SKBC ',
'SKBD ',
'SKBE ',
'SKBF ',
'skbg ',
'skbh ',
'SKBI ',
'SKBJ ',
'SKBK ',
'SKBL ',
'SKBM ',
'skbn ',
'SCC ',
'SCK ',
'VIP ',
--'MVKU ',  master 
'SKKS ',
'SKS ',
'SKT ',
'VID ',
'SKD ',
'SKKD '
)
and roleid = 4 

INSERT INTO #temp (custid, isfinished)
SELECT custid, 0 
from custinfo with (nolock)
where srecommend in (
	select custid from @tmpSuper
)
AND DoubleCommLosing = 1
AND custid <= @maxcustid


GO

DECLARE @ids VARCHAR(MAX), @rowcnt INT

WHILE (1=1)
BEGIN
	SELECT @ids = ''
    
    UPDATE TOP (5000) #temp
    SET @ids = @ids + CASE @ids WHEN '' THEN '' ELSE ',' END + CAST(custid AS VARCHAR(12))
        ,isfinished = 1
    FROM #temp
    WHERE isfinished = 0
 
	SELECT @rowcnt = @@ROWCOUNT    

    EXEC [Acc_ExecRep_09] @ids = @ids
    
    IF @rowcnt < 5000 RETURN

    WAITFOR DELAY '00:00:01'
    
END