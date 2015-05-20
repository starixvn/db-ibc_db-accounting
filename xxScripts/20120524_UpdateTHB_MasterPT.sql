
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS

/*	
	topic: http://ccs.nexcel.vn/viewtopic.php?p=31198#p31198
*/
BEGIN
		
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
		
	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'custsettingGame' AND type = 'U')
	BEGIN
		UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
		SET mpositiontaking = 0.75			
		WHERE custid IN (select custid from @res)  --- master
			AND sporttype = 162 AND bettype = 1101	
	END

	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'custsetting3rd' AND type = 'U')
	BEGIN
		-- update PT Number Game non live 
		UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
		SET mpositiontaking = 0.75	
		WHERE custid IN (select custid from @res)
		AND sporttype = 161 AND bettype IN (81,83,86,88)

		-- update PT Number Game live 
		UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
		SET mlivepositiontaking = 0.75	
		WHERE custid IN (select custid from @res)
		AND sporttype = 161 AND bettype IN (85,86,87,89,90)

	END

	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'custsetting' AND type = 'U')
	BEGIN
		-- update PT soccer & other sport non live
		UPDATE custsetting WITH(ROWLOCK,UPDLOCK)
		SET mpositiontaking = 0.75			
		WHERE custid IN (select custid from @res)

		-- update PT soccer live
		UPDATE custsetting WITH(ROWLOCK,UPDLOCK)
		SET mlivepositiontaking = 0.75			
		WHERE custid IN (select custid from @res)
		AND sporttype = 1 AND bettype IN (1,3,7,8)
	END
END



DECLARE @THBsupers TABLE (custid INT)
INSERT INTO @THBsupers
		  SELECT 	1528421	----	B10T
UNION ALL SELECT 	1528422	----	B11T
UNION ALL SELECT 	1536432	----	B12T
UNION ALL SELECT 	1538057	----	B13T
UNION ALL SELECT 	1538175	----	B14T
UNION ALL SELECT 	1538183	----	B15T
UNION ALL SELECT 	1538997	----	B16T
UNION ALL SELECT 	1539009	----	B17T
UNION ALL SELECT 	1539693	----	B18T
UNION ALL SELECT 	1539698	----	B19T
UNION ALL SELECT 	1523261	----	B1T
UNION ALL SELECT 	1588140	----	B24T
UNION ALL SELECT 	1588145	----	B25T
UNION ALL SELECT 	2508822	----	B26T
UNION ALL SELECT 	2541779	----	B27T
UNION ALL SELECT 	1528410	----	B2T
UNION ALL SELECT 	1528413	----	B4T
UNION ALL SELECT 	1517951	----	B5T
UNION ALL SELECT 	1528414	----	B6T
UNION ALL SELECT 	1528418	----	B7T
UNION ALL SELECT 	1528419	----	B8T
UNION ALL SELECT 	1528420	----	B9T
UNION ALL SELECT 	1517030	----	BT
UNION ALL SELECT 	1537683	----	KHT
UNION ALL SELECT 	3642574	----	KJT
UNION ALL SELECT 	1539908	----	MKTB
UNION ALL SELECT 	2421122	----	SABT
UNION ALL SELECT 	1558372	----	SBBT
UNION ALL SELECT 	1584515	----	SHHT
UNION ALL SELECT 	1113450	----	SM
UNION ALL SELECT 	2388779	----	STEB
UNION ALL SELECT 	1563929	----	STESTTHB


--create table #temp (custid int primary key, isfinished bit)

INSERT INTO #temp(custid,isfinished )
SELECT custid ,0
FROM customer WITH(NOLOCK)
WHERE srecommend IN (SELECT custid FROM @THBsupers)
AND roleid = 3




declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (1000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount
	
	EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 1000 RETURN
	WAITFOR DELAY '00:00:03'
end
