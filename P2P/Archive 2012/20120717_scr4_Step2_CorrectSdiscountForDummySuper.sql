


ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	Step 2	correct sdiscount on super and on member
	
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
	SET sdiscount = 0.55
	WHERE custid IN (SELECT * FROM @res)
		
END

GO

create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select custid, 0
FROM custinfo with(nolock)
where srecommend < 100 AND roleid IN (1,4)
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
