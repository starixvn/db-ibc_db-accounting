Create table  #temp1 (custid int, roleid tinyint)
Create table  #temp2 (custid int)

insert into #temp1
select distinct u.custid, roleid from userlog_runSP u (nolock)
inner join custinfo c (nolock) on u.custid = c.custid
where spname like 'Acc_CustomerUpdEditCustomer_%'
and logdate > '2008-11-21 06:15:13.770'
order by roleid desc


 

insert into #temp2
select custid from  custinfo (nolock)
where srecommend in 
			(select custid from #temp1 where roleid = 4)

insert into #temp2
select custid from  custinfo (nolock)
where mrecommend in 
			(select custid from #temp1 where roleid = 3)

insert into #temp2
select custid from  custinfo (nolock)
where recommend in 
			(select custid from #temp1 where roleid = 2)

insert into #temp2
select custid from  custinfo (nolock)
where custid in 
			(select custid from #temp1 where roleid = 1)

select distinct custid from #temp2 order by custid

drop table #temp1
drop table #temp2




-----------------------

Create table  #temp1 (custid int)

insert into #temp1
select distinct u.custid, roleid from userlog_runSP u (nolock)
inner join custinfo c (nolock) on u.custid = c.custid
where spname like 'Acc_CustOverrideUpd_1%'
and logdate > '2008-11-21 06:15:13.770'
order by roleid desc

select distinct custid from #temp1 order by custid

drop table #temp1
--------------

ALTER PROCEDURE [dbo].[ExecRep_07]	
AS

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

UPDATE cs1
SET apositiontaking = cs2.apositiontaking, mpositiontaking = cs2.mpositiontaking, spositiontaking = cs2.spositiontaking,
                       autopositiontaking = cs2.autopositiontaking, isautopositiontaking = cs2.isautopositiontaking,                       
                       minbet = cs2.minbet, maxbet = cs2.maxbet
from Custsetting cs1
	inner join custsetting cs2 (nolock) on cs1.custid = cs2.custid and cs2.sporttype = 2 and cs2.bettype = 1
where cs1.sporttype = 201 and cs1.bettype = 3
	and cs1.custid in (
11823, 16631, ..
)



UPDATE cs1
SET minpositiontaking = cs2.minpositiontaking, maxpositiontaking = cs2.maxpositiontaking
from custoverride cs1
	inner join custoverride cs2 (nolock) on cs1.custid = cs2.custid and cs2.sporttype = 2 and cs2.bettype = 1
where cs1.sporttype = 201 and cs1.bettype = 3
	and cs1.custid in (
...
)
                 

