
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON
/*	
	 1 - Insert PT Setting (CustSettingGame)
	 2 - Insert Min PT Setting (CustOverrideGame)	 
*/
BEGIN	
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custinfo','CustSetting3rd','CustOverride3rd') AND type = 'U') <> 3
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
	

	-- INSERT CustSetting3rd			
	INSERT INTO CustSetting3rd([custId], [bettype], [sporttype], [apositiontaking], [mpositiontaking], [spositiontaking],  [playerdiscount], [discount], [adiscount], [sdiscount], [Minbet], [Maxbet], autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
	SELECT cs.custid, 1201, 180, [apositiontaking], [mpositiontaking], [spositiontaking],  0 as [playerdiscount], 0 as [discount], 0 as [adiscount], 0 as [sdiscount], [Minbet], [Maxbet], autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, 0 as alivepositiontaking,0 as mlivepositiontaking,0 as  slivepositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking, 0 as autolivempositiontaking, 0 as isautolivempositiontaking
	FROM CustSetting3rd cs WITH(NOLOCK)			
	WHERE cs.custid IN (SELECT * FROM @res)
		AND cs.bettype = 81 AND cs.sporttype = 161			

	-- INSERT CustOverride3rd			
	INSERT INTO CustOverride3rd([custId], [bettype], [sporttype], minpositiontaking, maxpositiontaking,minlivepositiontaking,maxlivepositiontaking)		
	SELECT co.CustID, 1201, 180, minpositiontaking, 
		case when roleid = 4 then maxpositiontaking
			else 0.9 end as maxpositiontaking, 
		0 as minlivepositiontaking,0 as maxlivepositiontaking
	FROM custinfo ci WITH (NOLOCK) JOIN 
		custOverride3rd co WITH(NOLOCK)	ON ci.custid=co.custid 		
	WHERE co.custid IN (SELECT * FROM @res)
		AND co.bettype = 81 AND co.sporttype = 161						

	
	UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
	SET maxpermatch180 = maxpermatch161
	WHERE custid IN (SELECT * FROM @res)
END
 

DECLARE @customers TABLE (custid INT, roleid INT)

INSERT INTO @customers
          SELECT 1338545	, 4	-- GI
--UNION ALL SELECT 901858	, 4	-- ST5T
--UNION ALL SELECT 2490335, 4


-- remember to set maxcustid
-- select min(custid),max(custid) from custinfo with(nolock) 

DECLARE @maxCustID INT
SET @maxCustID = 8459948 

--DROP TABLE #temp
create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
select custid, 0
FROM custinfo c with(nolock)	
WHERE srecommend IN (SELECT custid FROM @customers WHERE roleid = 4)
	AND c.custid <= @maxCustID

insert into #temp (custid, isfinished)
select c.custid, 0
FROM custinfo c with(nolock)	
WHERE mrecommend IN (SELECT custid FROM @customers WHERE roleid = 3)
AND c.custid <= @maxCustID

insert into #temp (custid, isfinished)
select DISTINCT c.srecommend, 0
FROM custinfo c with(nolock)	
WHERE mrecommend IN (SELECT custid FROM @customers WHERE roleid = 3)
AND roleid = 3
AND srecommend NOT IN (SELECT custid FROM #temp)


insert into #temp (custid, isfinished)
select c.custid, 0
FROM custinfo c with(nolock)	
WHERE recommend IN (SELECT custid FROM @customers WHERE roleid = 2)
AND c.custid <= @maxCustID

insert into #temp (custid, isfinished)
select DISTINCT c.srecommend, 0
FROM custinfo c with(nolock)	
WHERE recommend IN (SELECT custid FROM @customers WHERE roleid = 2)
AND roleid = 2
AND srecommend NOT IN (SELECT custid FROM #temp)

insert into #temp (custid, isfinished)
select DISTINCT c.mrecommend, 0
FROM custinfo c with(nolock)	
WHERE recommend IN (SELECT custid FROM @customers WHERE roleid = 2)
AND roleid = 2
AND mrecommend NOT IN (SELECT custid FROM #temp)

--SELECT * FROM #temp

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
