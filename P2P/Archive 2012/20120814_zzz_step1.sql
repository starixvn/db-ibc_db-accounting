
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	1. Daily auto reset = 1 for all levels
	2. Max transfer credit
		- Super and Master were set [max transfer credit] in P2P Default Setting table
		- Agent and Member were set 30% of [max transfer credit] in P2P Default Setting table
*/
	
BEGIN
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
	
	DECLARE @P2PSetting TABLE (currency INT, maxCredit MONEY, maxCredit_30P MONEY)
	INSERT INTO @P2PSetting
			  SELECT 3, 100000.00, 30000.00000
	UNION ALL SELECT 4, 3000000.00, 900000.00000
	UNION ALL SELECT 5, 600000.00, 180000.00000
	UNION ALL SELECT 6, 100000.00, 30000.00000
	UNION ALL SELECT 9, 100000.00, 30000.00000
	UNION ALL SELECT 12, 50000.00, 15000.00000
	UNION ALL SELECT 13, 600000.00, 180000.00000
	UNION ALL SELECT 15, 900000.00, 270000.00000
	UNION ALL SELECT 16, 100000.00, 30000.00000
	UNION ALL SELECT 17, 100000.00, 30000.00000
	UNION ALL SELECT 22, 900000.00, 270000.00000
	UNION ALL SELECT 30, 3000000.00, 900000.00000
	UNION ALL SELECT 31, 7500000.00, 2250000.00000
	UNION ALL SELECT 32, 7500000.00, 2250000.00000
	UNION ALL SELECT 33, 900000.00, 270000.00000
	UNION ALL SELECT 34, 900000.00, 270000.00000
	UNION ALL SELECT 35, 100000.00, 30000.00000
	UNION ALL SELECT 37, 100000.00, 30000.00000
	UNION ALL SELECT 40, 100000.00, 30000.00000
	UNION ALL SELECT 43, 3000000.00, 900000.00000
	UNION ALL SELECT 44, 1000000.00, 300000.00000
	UNION ALL SELECT 45, 90000000.00, 27000000.00000
	UNION ALL SELECT 47, 900000.00, 270000.00000
	UNION ALL SELECT 62, 100000.00, 30000.00000

	UPDATE c WITH(ROWLOCK,UPDLOCK)
	SET IsAutoResetP2P = 1,
		MaxTransferP2P = CASE WHEN c.roleid IN (3,4) THEN ISNULL(t.maxCredit,0)
							  WHEN c.roleid IN (1,2) THEN ISNULL(t.maxCredit_30P,0)
							  ELSE 0 
						 END,
		DisableFunP2P = 0,
		DisableP2P = 1
	FROM custinfo c 
		LEFT JOIN @P2PSetting t ON c.currency = t.currency
	WHERE custid IN (SELECT * FROM @res)
		
END

GO
	DECLARE @maxCustID INT

SET @maxCustID = 7880186

create table #temp (custid int primary key, isfinished bit)

INSERT INTO #temp (custid, isfinished)
SELECT custid, 0
FROM custinfo WITH(NOLOCK)
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
AND roleid <= 4
AND custid > @maxCustID

go

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