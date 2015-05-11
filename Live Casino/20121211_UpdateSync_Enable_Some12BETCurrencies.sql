



ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
/*
	- update syncLiveCasino & DisableLivecasino for some 12BET customers ( under 5 currency:RM, RMB, TB, IN, INH)
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
		DisableLiveCasino = 0
	WHERE custid IN (select * from @res)
	
END

GO

DECLARE @maxCustID INT
SET @maxCustID = 9418248  ---- from TW team 

create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT c.custid, 0
FROM custinfo c WITH(NOLOCK)
WHERE c.srecommend IN (SELECT custid FROM f_depsuper_1('12BET'))
	AND currency IN (
						2	, ----RM
						4	, ----TB
						13	, ----RMB
						15	, ----IN
						51	 ----INH	
					)
	AND (SyncLiveCasino = 0 OR DisableLiveCasino = 1)
	AND c.custid <= @maxCustID
	

--
GO

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
