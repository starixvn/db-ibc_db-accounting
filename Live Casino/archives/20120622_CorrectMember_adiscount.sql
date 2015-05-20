

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	update Live casino adiscount on member
	
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custsettinggame','custinfo') AND type = 'U') <> 2
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

	UPDATE mg WITH(ROWLOCK,UPDLOCK)	
	SET adiscount = mtg.adiscount
	FROM custsettingGame mg 
		INNER JOIN custinfo c WITH(NOLOCK) ON mg.custid = c.custid
		INNER JOIN custsettingGame mtg WITH(NOLOCK) ON mtg.custid = c.mrecommend
	WHERE c.custid IN (select * from @res)
		AND mg.sporttype = 162 AND mg.bettype = 1101
		AND mtg.sporttype = 162 AND mtg.bettype = 1101
	
END

GO
	

	DECLARE @superlist TABLE (custid INT)

	INSERT INTO @superlist
	SELECT c.custid 
	FROM custinfo c WITH (nolock)
		INNER join exchange e WITH (nolock) ON c.currency=e.exchangeid
		INNER join custSuper cs WITH (nolock) ON c.custid=cs.custid
	WHERE roleid=4
		and srecommend not in (SELECT custid FROM f_DepSuper_1('All'))
		and cs.isinternal=0 and c.enabled=1 and c.currency<>20
		and username not like '%ACCSuper%' and username not like '3rdSuper%'


create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT co.custid, 0
FROM custinfo co WITH (nolock)
	INNER join custsettinggame cm WITH (nolock) ON co.custid=cm.custid
	INNER join custsettinggame cma WITH (nolock) ON co.mrecommend=cma.custid
WHERE co.roleid=1
	and srecommend in (SELECT custid FROM @superlist)
	and cma.adiscount<> cm.adiscount
	and co.CustID NOT IN (6662355,7352044,7352051,7352122,7352145,7352193,7174980,7174981,7351921,7352006,7352022)
	AND co.syncLiveCasino = 1
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

	WAITFOR DELAY '00:00:03'
end
