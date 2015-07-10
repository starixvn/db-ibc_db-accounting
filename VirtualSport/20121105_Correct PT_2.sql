-- correct member PT
-- Rule S4 < S1 + M1 + A1
-- Rule N4 > S1 + M1 + A1
create table #tmp(custid int)

insert into #tmp   ------ 2545 affected members
-- S4 < S1 + M1 + A1
SELECT distinct ci.custid --, ci.username, ci.closed, ci.enabled
FROM custinfo ci WITH (NOLOCK)
    JOIN dbo.CustSetting3rd cs WITH (NOLOCK) ON cs.custid=ci.custid
    JOIN dbo.CustSetting3rd scs WITH (NOLOCK) ON scs.custid=ci.srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype    
WHERE roleid=1 and cs.bettype = 1201 and cs.sporttype= 180
    and scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking

UNION ALL

--N4 > S1 + M1 + A1   
SELECT distinct ci.custid  --ci.custid, ci.username, ci.closed, ci.enabled
FROM custinfo ci WITH (NOLOCK)
    JOIN dbo.CustSetting3rd cs WITH (NOLOCK) ON cs.custid=ci.custid
    JOIN dbo.custOverride3rd sco WITH (NOLOCK) ON sco.custid=ci.srecommend and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype    
WHERE roleid=1 and cs.bettype = 1201 and cs.sporttype= 180
and sco.minpositiontaking>0
and sco.minpositiontaking > cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking    

go

--===========================
declare 
	@sporttype		INT, 
	@bettype		INT,
	@updautomaster bit,
	@updautosuper bit
	
select	@sporttype=180,
		@bettype=1201,
		@updautomaster = 1,
		@updautosuper = 1
		
DECLARE @spos SMALLMONEY, @mpos SMALLMONEY, @apos SMALLMONEY, @mapos1 SMALLMONEY, @mapos2 SMALLMONEY, @mapos SMALLMONEY, @maxmapos smallmoney

--check agent min/max
--update a1=n2 when a1<n2
Update cs 
set cs.apositiontaking = aco.minpositiontaking,
	cs.mpositiontaking = case when cs.mpositiontaking + aco.minpositiontaking > mcs.mpositiontaking then mcs.mpositiontaking-aco.minpositiontaking else cs.mpositiontaking end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.custid in (select custid from #tmp)
	and cs.apositiontaking<aco.minpositiontaking
	and cs.sporttype = @sporttype
	and cs.bettype = @bettype		

--update a1=l2 when a1>l2
Update custsetting3rd with (ROWLOCK, UPDLOCK) set 
	apositiontaking = aco.maxpositiontaking
	from 
		custsetting3rd inner join custinfo as mb with (NOLOCK) on custsetting3rd.custid = mb.custid  and mb.roleid=1
		inner join custoverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting3rd.sporttype and aco.bettype=custsetting3rd.bettype
	where custsetting3rd.custid in (select custid from #tmp)
		and custsetting3rd.sporttype = @sporttype and custsetting3rd.apositiontaking>aco.maxpositiontaking
		
	
--Recal AUTO MPT 
--Update m1=min(m4-a1,m3-a1,(im1?um1,um2))
-------------------------------------------------------------------------------------
if @updautomaster = 1
begin		
	Update cs
		set mpositiontaking = 
			case when scs.mpositiontaking > mcs.mpositiontaking then 
				case when mcs.mpositiontaking-cs.apositiontaking > (case when cs.isautompositiontaking = 1 then cs.autompositiontaking else acs.autompositiontaking end)
				then (case when cs.isautompositiontaking = 1 then cs.autompositiontaking else acs.autompositiontaking end)
				else  mcs.mpositiontaking-cs.apositiontaking end
			else
				case when scs.mpositiontaking-cs.apositiontaking > (case when cs.isautompositiontaking = 1 then cs.autompositiontaking else acs.autompositiontaking end)
				then (case when cs.isautompositiontaking = 1 then cs.autompositiontaking else acs.autompositiontaking end)
				else  scs.mpositiontaking-cs.apositiontaking end
			end
	from
		CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
		inner join custsetting3rd as scs with (NOLOCK) on scs.custid = c.srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
		inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = c.recommend and acs.sporttype=cs.sporttype and acs.bettype=cs.bettype
	where		
		c.custid in (select custid from #tmp)
		and c.roleid = 1
		and (acs.isautompositiontaking = 1 or cs.isautompositiontaking = 1)
		and cs.sporttype = @sporttype and cs.bettype = @bettype	
end
-------------------------------------------------------------------------------------

--check master min/max
--update m1=n3-a1 if a1+m1<n3
Update cs
	set mpositiontaking = mco.minpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.roleid=1
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
where 
	cs.custid in (select custid from #tmp)
	and cs.apositiontaking+cs.mpositiontaking<mco.minpositiontaking
	and cs.sporttype = @sporttype and cs.bettype = @bettype
-----------------------------------------------------------------------------------------------------------------------------------
--update m1,a1 when a1+m1>l3
--update m1=if(min(m3,l3)-a1<0,0,min(m3,l3)-a1)
--update a1=if(a1+m1>min(m3,l3),min(m3,l3)-m1,a1)
Update cs
set @maxmapos = case when mcs.mpositiontaking>mco.maxpositiontaking then mco.maxpositiontaking else mcs.mpositiontaking end,
		@mpos = case when @maxmapos-cs.apositiontaking<0 then 0 else @maxmapos-cs.apositiontaking end,
		mpositiontaking = @mpos,
		@apos = case when cs.apositiontaking + @mpos>@maxmapos then @maxmapos-@mpos else cs.apositiontaking end,
		apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid  and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where 
	cs.custid in (select custid from #tmp)
	and cs.apositiontaking+cs.mpositiontaking>mco.maxpositiontaking
	and cs.sporttype = @sporttype and cs.bettype = @bettype	
-----------------------------------------------------------------------------------------------------------------------------------

waitfor delay '00:00:03'

--recal autopos
	Update cs
		set spositiontaking = case when scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking >
								(case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) then (case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) else scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking end 
	from
		CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid and c.roleid = 1
		inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
		inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = c.srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
	where (cs.isautopositiontaking=1 or mcs.isautopositiontaking=1)
		and cs.sporttype = @sporttype and cs.bettype = @bettype
		AND c.custid in (select custid from #tmp)		

--check super min/max
--update s1 when s1+m1+a1<n4 or s1+m1+a1>l4
Update cs
	set spositiontaking = sco.minpositiontaking-cs.mpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.roleid=1
	inner join CustOverride3rd as sco with (NOLOCK) on sco.custid = mb.srecommend  and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking+cs.spositiontaking<sco.minpositiontaking
	and cs.sporttype = @sporttype and cs.bettype = @bettype
	and cs.custid in (select custid from #tmp)
	
--update s1,m1,a1 in case s1+m1+a1>s4
--s1=max(0,s4-m1-a1)
--@mapos1=iif(s1_new+m1+a1>s4,s4-s1_new,m1+a1)	
--@mapos2=min(@mapos1,m3)
--@mapos=max(@mapos2,n3)
--m1=max(0,@mapos-a1)
--a1=iif(m1_new+a1>@mapos,@mapos-m1_new,a1)
Update cs
	set @spos = case when scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking<0 then 0 else scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking end,
		spositiontaking = @spos,
		@mapos1 = case when @spos+cs.mpositiontaking+cs.apositiontaking>scs.spositiontaking then scs.spositiontaking-@spos else cs.mpositiontaking+cs.apositiontaking end,			
		@mapos2 = case when @mapos1 > mcs.mpositiontaking then mcs.mpositiontaking else @mapos1 end,
		@mapos = case when @mapos2<mco.minpositiontaking then mco.minpositiontaking else @mapos2 end,
		@mpos = case when @mapos-cs.apositiontaking<0 then 0 else @mapos-cs.apositiontaking end,
		mpositiontaking = @mpos,
		@apos = case when cs.apositiontaking + @mpos>@mapos then @mapos-@mpos else cs.apositiontaking end,
		apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.roleid=1
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = mb.srecommend  and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where 
	cs.custid in (select custid from #tmp)
	and cs.spositiontaking+cs.apositiontaking+cs.mpositiontaking>scs.spositiontaking
	and cs.sporttype = @sporttype and cs.bettype = @bettype

--drop table #tmp