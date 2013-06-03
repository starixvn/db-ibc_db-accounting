


ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	Step 3	correct discount on agent and on member
	
	Expected result
	- direct master (update super) 0.55
	- direct agent (update super, master) 0.4
	- normal super 0.67
	- normal master 0.55
	- normal agent, member 0.00
	
	Step 1: Insert all customer with:
					sdiscount	adiscount	discount	playerdiscount
			Super:  0.67		0			0			0
			Master: 0.00		0.55		0			0
			Agent:	0			0			0			0
			Member: 0.67		0.55		0			0
	Step 2: In direct masters case: correct sdiscount on super and on member
	Step 3: In direct agents case: correct discount on agent and on member	
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('P2PGroupComm') AND type = 'U') <> 1
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
	
	
	UPDATE P2PGroupComm WITH(ROWLOCK,UPDLOCK) 
	SET discount = 0.4
	WHERE custid IN (SELECT * FROM @res)
		
END

GO
declare @customer table (custid int)
insert into @customer
		  SELECT 2967   -- 7663RM
UNION ALL SELECT 3134   -- 2300RM
UNION ALL SELECT 3290   -- 6599RM
UNION ALL SELECT 3556   -- PHRM
UNION ALL SELECT 4295   -- TKRM
UNION ALL SELECT 4304   -- 9999SD
UNION ALL SELECT 4487   -- 113SD
UNION ALL SELECT 5261   -- JMRM
UNION ALL SELECT 5966   -- 1188RM
UNION ALL SELECT 10793   -- ywrm
UNION ALL SELECT 11237   -- 1158RM
UNION ALL SELECT 11461   -- SB257
UNION ALL SELECT 31722   -- 6666SD
UNION ALL SELECT 46846   -- 2588RM
UNION ALL SELECT 95304   -- 69SD
---UNION ALL SELECT 374772   -- 0008SD
UNION ALL SELECT 374774   -- 330SD
UNION ALL SELECT 1038805   -- TBS
UNION ALL SELECT 1052570   -- 2588SD
UNION ALL SELECT 1175260   -- PESD
UNION ALL SELECT 1486674   -- DDS
UNION ALL SELECT 3264904   -- ADM
UNION ALL SELECT 4184712   -- A31M
UNION ALL SELECT 4383384   -- SSSDRM
UNION ALL SELECT 7350024   -- SS31SD
UNION ALL SELECT 7380795   -- S116SD


create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select custid, 0
FROM custinfo with(nolock)
where recommend IN (SELECT custid FROM @customer )
AND roleid IN (1,2)
and custid <= @maxcustid 

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
 