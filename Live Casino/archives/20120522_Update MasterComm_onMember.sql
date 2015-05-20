

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*	
	topic: http://ccs.nexcel.vn/viewtopic.php?p=31198#p31198
*/
BEGIN

	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsettingGame') AND type = 'U') <> 1
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
		

	UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
	SET sdiscount = 0.007,		
	adiscount = 0.007		
	WHERE custid IN (select custid from @res)  --- master
		AND sporttype = 162 AND bettype = 1101	
END



DECLARE @Super TABLE(custid INT)
INSERT INTO @Super		
			SELECT    4501066	----SYSHK
UNION ALL SELECT    2345677	----JS3
UNION ALL SELECT    4213345	----JSD
UNION ALL SELECT    4500902	----SYSM
UNION ALL SELECT    2586897	----JS6
UNION ALL SELECT    5551253	----JSF
UNION ALL SELECT    1437413	----JS1
UNION ALL SELECT    2732315	----JS7
UNION ALL SELECT    1262078	----JS
UNION ALL SELECT    4622126	----JMA
UNION ALL SELECT    4564941	----JSR
UNION ALL SELECT    2491562	----JU
UNION ALL SELECT    3992866	----JSC
UNION ALL SELECT    5875257	----JST
UNION ALL SELECT    5871274	----JSG
UNION ALL SELECT    2279626	----SFH
UNION ALL SELECT    2487351	----JS5
UNION ALL SELECT    4663992	----JSE
UNION ALL SELECT    4166679	----JSB
UNION ALL SELECT    2802555	----JS8
UNION ALL SELECT    1797678	----JM
UNION ALL SELECT    2829199	----SJS
UNION ALL SELECT    2967002	----SFHA
UNION ALL SELECT    3581309	----JSA

DECLARE @MasterList TABLE(custid INT)
INSERT INTO @MasterList
SELECT custid FROM Custinfo WITH (nolock)
WHERE srecommend IN (SELECT custid FROM @Super)
AND roleid=3


create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select c.custid, 0
from custinfo c with(nolock)
where mrecommend IN (select custid from @MasterList) and custid <= 7130362
	and roleid = 1


-- run

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
	WAITFOR DELAY '00:00:03'
end

