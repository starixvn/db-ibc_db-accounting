


/*
	check Aust racing comm setting before do copy to Aust Harness
	super comm = 0.01
	direct master comm = 0.01 ( master who has srecommend <= 100)
*/

CREATE TABLE #tmp (custid int)

insert into #tmp 
select custid
from customer with(nolock)
where (username like '%ACCSuper%' or username like '3rdSuper%')
and roleid = 4

insert into #tmp
select * from dbo.f_depsuper_1('all')

GO

CREATE TABLE #incorrectSuper (custid int)
CREATE TABLE #incorrectMaster (custid int)

--- get incorrect super comm setting
insert into #incorrectSuper
select distinct c.custid
from custsetting3rd r with(nolock)
	inner join custinfo c with(nolock) on c.custid = r.custid
where r.sporttype = 151 and r.bettype between 51 and 52
and c.srecommend not in (select custid from #tmp)
and roleid = 4 and r.sdiscount <> 0.01
and c.currency <> 20 --and disable151_au = 0

--- get incorrect master comm setting
insert into #incorrectMaster
select distinct c.custid
from custsetting3rd r with(nolock)
	inner join custinfo c with(nolock) on c.custid = r.custid
where r.sporttype = 151 and r.bettype between 51 and 52
and c.srecommend <= 100
and roleid = 3 and r.adiscount <> 0.01
and c.currency <> 20 --and disable151_au = 0

GO

---- correct commission on super (48 rows affected)
update r with(rowlock,updlock)
set sdiscount = 0.01
from custsetting3rd r	
where r.sporttype = 151 and r.bettype between 51 and 52
	and r.custid in (select custid from #incorrectSuper)
	

---- correct commission on master  (9 rows affected)
update r with(rowlock,updlock)
set adiscount = 0.01
from custsetting3rd r	
where r.sporttype = 151 and r.bettype between 51 and 52
	and r.custid in (select custid from #incorrectMaster)
	
/*
-- check affected members
select count(1)
 from custsetting3rd cs3 with(nolock)
	inner join customer c with(nolock) on cs3.custid = c.custid
where sporttype = 151 and bettype in (51,52)
		and srecommend in (select * from #incorrectSuper)
		and roleid = 1
	and sdiscount<> 0.01
*/

---- correct sdiscount on member (25638 rows affected)
WHILE 1 = 1
BEGIN
	update TOP(10000) r WITH(ROWLOCK,UPDLOCK)
	set sdiscount = 0.01
	from custsetting3rd r 
		inner join customer c with(nolock) on r.custid = c.custid
	where r.sporttype = 151 and r.bettype in (51,52)
		and srecommend in (select * from #incorrectSuper)
		and roleid = 1 AND sdiscount <> 0.01
		
	IF @@ROWCOUNT <> 10000
		BREAK
			
	WAITFOR DELAY '00:00:02'
END

GO
/*
-- check affected members
select count(1)
 from custsetting3rd cs3 with(nolock)
	inner join customer c with(nolock) on cs3.custid = c.custid
where sporttype = 151 and bettype in (51,52)
		and mrecommend in (select * from #incorrectMaster)
		and roleid = 1
	and adiscount <> 0.01
*/
-- correct adiscount on member   (436 affected)

update TOP(10000) r WITH(ROWLOCK,UPDLOCK)
set adiscount = 0.01
from custsetting3rd r 
	inner join customer c with(nolock) on r.custid = c.custid
where r.sporttype = 151 and r.bettype in (51,52)
	and mrecommend in (select * from #incorrectMaster)
	and roleid = 1
	