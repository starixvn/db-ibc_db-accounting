-- reduce 12bet's fee to 15% instead of 17%

IF

/***** STEP 1: Update for agents ***/
create table #agList (custid int, roleid tinyint)

INSERT INTO #agList (custid, roleid)
select custid, roleid
from customer with(nolock)
where roleid in (2,3,4)
	and srecommend in (select custid from dep_custsuper with(nolock) where site='12bet')
	and username not like '12betaff%'

select * from #aglist	
	
-- super	
update dep_custsetting3rd with(rowlock, updlock)
set spositiontaking = 0.85
	,mpositiontaking = 0.85
	,apositiontaking = 0.85
where sporttype = 161 
	and custid in (select custid from #aglist where roleid=4)
	
-- master	
update dep_custsetting3rd with(rowlock, updlock)
set mpositiontaking = 0.85	
where sporttype = 161 
	and custid in (select custid from #aglist where roleid=3)
	
-- agent	
update dep_custsetting3rd with(rowlock, updlock)
set apositiontaking = 0.85
where sporttype = 161 
	and custid in (select custid from #aglist where roleid=2)	

drop table #agList 	
/***** END STEP 1 ****/

-------------------------------------------------------------------
-------------------------------------------------------------------
-------------------------------------------------------------------

/***** STEP 2 - update for member ****/
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max), 
	@whatAreYouDoing varchar(100) =''
AS
SET NOCOUNT ON
BEGIN
	if @whatAreYouDoing <> 'change_12BET_NG_setting' RETURN --:D
	
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('dep_custsetting3rd') AND type = 'U') <> 1
		RETURN

	---------------------------------------------	
	declare @string varchar(max), @splitter char(1), @xml XML
	select @splitter = ',' ,@string = @ids
	
	SET @XML = N'<root><r>' + REPLACE(@string, @splitter, '</r><r>') + '</r></root>'
	declare @res AS TABLE(custid INT)
	INSERT INTO @res(custid)
	SELECT r.value('.','VARCHAR(12)')
	FROM @xml.nodes('//root/r') AS RECORDS(r)
	---------------------------------------------
	
	update dep_custsetting3rd with(rowlock, updlock)
	set apositiontaking = 0.85
	where custid in (select custid from @res)
		and sporttype = 161			
END
GO
--------------------------------------------------

create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT custid, 0
FROM customer with(nolock)
WHERE srecommend IN (select custid from dep_custsuper with(nolock) where site='12bet')
	AND roleID = 1

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (2000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount	

	EXEC dbo.Acc_ExecRep_09 
		@ids = @ids,
		@whatAreYouDoing = 'change_12BET_NG_setting'
	
	if @rowcnt < 2000 RETURN

	WAITFOR DELAY '00:00:01'
end	
/***** END STEP 2 ****/