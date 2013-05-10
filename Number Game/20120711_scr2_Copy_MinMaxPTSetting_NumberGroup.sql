 

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON

/*
	copy minmax PT setting from next combo 89
	
*/
	
BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custoverride3rd') AND type = 'U') <> 1
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

	UPDATE gr WITH(ROWLOCK,UPDLOCK)
	SET minlivepositiontaking = cb.minlivepositiontaking,
		maxlivepositiontaking = cb.maxlivepositiontaking
	FROM custoverride3rd gr 
		INNER JOIN custoverride3rd cb WITH(NOLOCK) ON gr.custid = cb.custid AND gr.sporttype = cb.sporttype
	WHERE gr.custid IN (SELECT * FROM @res)
		AND gr.sporttype = 161 AND gr.bettype = 90
		AND cb.sporttype = 161 AND cb.bettype = 89
	
END

GO
	

	DECLARE @superlist TABLE (custid INT)

	INSERT INTO @superlist
	SELECT c.custid 
	FROM custinfo c WITH (nolock)		
		INNER join custSuper cs WITH (nolock) ON c.custid=cs.custid
	WHERE roleid=4
		AND username NOT LIKE '3rdSuper%'
		AND isinternal <> 1
			
declare @maxCustID INT

SET @maxCustID = xxx

create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT co.custid, 0
FROM custinfo co WITH (nolock)
WHERE srecommend IN (SELECT custid FROM @superlist)
	AND roleID BETWEEN 2 AND 4
	AND custid <= @maxCustID
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

	WAITFOR DELAY '00:00:03'
end
