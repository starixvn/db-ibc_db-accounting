

create table #tmp(custid int)

insert into #tmp   ------ 2545 affected members
select distinct c.custid
from custinfo c witH(nolock)
	inner join custsetting3rd cp with(nolock) on c.custid = cp.custid
	inner join custsetting3rd cm with(nolock) on c.mrecommend = cm.custid and cp.bettype = cm.bettype
where c.srecommend not in (select custid from f_depsuper_1('all'))
and c.roleid = 1 and cp.sporttype = 161 and cp.bettype in (85,86,87,88,89,90)
and cm.mlivepositiontaking < cp.mlivepositiontaking + cp.alivepositiontaking

go

--===========================
declare 
	@updautomaster bit,
	@updautosuper bit
	
select	@updautomaster = 1,
		@updautosuper = 1

declare @mpos smallmoney, @apos smallmoney, @spos smallmoney, @mapos1 smallmoney, @mapos2 smallmoney, @mapos smallmoney, @maxmapos smallmoney

--check agent min/max
--update a1=n2 when a1<n2

Update custsetting3rd with (ROWLOCK, UPDLOCK) set 
	alivepositiontaking = aco.minlivepositiontaking,
	custsetting3rd.mlivepositiontaking = case when custsetting3rd.mlivepositiontaking + aco.minlivepositiontaking > mcs.mlivepositiontaking then mcs.mlivepositiontaking-aco.minlivepositiontaking else custsetting3rd.mlivepositiontaking end
from 
	custsetting3rd inner join custinfo as mb with (NOLOCK) on custsetting3rd.custid = mb.custid
	inner join custsetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=custsetting3rd.sporttype and mcs.bettype=custsetting3rd.bettype
	inner join custoverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting3rd.sporttype and aco.bettype=custsetting3rd.bettype
where custsetting3rd.sporttype=161 and custsetting3rd.bettype in (85,86,87,89,90) 
	and custsetting3rd.alivepositiontaking<aco.minlivepositiontaking
	AND custsetting3rd.custid in (select custid from #tmp)



--update a1=l2 when a1>l2

Update custsetting3rd with (ROWLOCK, UPDLOCK) set 
	alivepositiontaking = aco.maxlivepositiontaking
from 
	custsetting3rd inner join custinfo as mb with (NOLOCK) on custsetting3rd.custid = mb.custid
	inner join custoverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting3rd.sporttype and aco.bettype=custsetting3rd.bettype
where custsetting3rd.sporttype=161 and custsetting3rd.bettype in (85,86,87,89,90) 
	and custsetting3rd.alivepositiontaking>aco.maxlivepositiontaking
	AND custsetting3rd.custid in (select custid from #tmp)
	
--Recal AUTO MPT 
--Update m1=min(m4-a1,m3-a1,(im1?um1,um2))
-------------------------------------------------------------------------------------
if @updautomaster = 1
begin	
	Update custsetting3rd with (ROWLOCK, UPDLOCK) 
		set mlivepositiontaking =
			case when scs.mlivepositiontaking > mcs.mlivepositiontaking then
				case when mcs.mlivepositiontaking-custsetting3rd.alivepositiontaking > (case when custsetting3rd.isautolivempositiontaking = 1 then custsetting3rd.autolivempositiontaking else acs.autolivempositiontaking end)
					then (case when custsetting3rd.isautolivempositiontaking = 1 then custsetting3rd.autolivempositiontaking else acs.autolivempositiontaking end)
				else  mcs.mlivepositiontaking-custsetting3rd.alivepositiontaking end
			else
				case when scs.mlivepositiontaking-custsetting3rd.alivepositiontaking > (case when custsetting3rd.isautolivempositiontaking = 1 then custsetting3rd.autolivempositiontaking else acs.autolivempositiontaking end)
					then (case when custsetting3rd.isautolivempositiontaking = 1 then custsetting3rd.autolivempositiontaking else acs.autolivempositiontaking end)
				else  scs.mlivepositiontaking-custsetting3rd.alivepositiontaking end
			end
	from
		custsetting3rd
		inner join custinfo as c with (NOLOCK) on custsetting3rd.custid = c.custid
		inner join custsetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting3rd.sporttype and mcs.bettype=custsetting3rd.bettype
		inner join custsetting3rd as scs with (NOLOCK) on scs.custid = c.srecommend and scs.sporttype=custsetting3rd.sporttype and scs.bettype=custsetting3rd.bettype
		inner join custsetting3rd as acs with (NOLOCK) on acs.custid = c.recommend and acs.sporttype=custsetting3rd.sporttype and acs.bettype=custsetting3rd.bettype
	where
		c.custid in (select custid from #tmp)
		and custsetting3rd.sporttype = 161
		and custsetting3rd.bettype in (85, 86, 87,89,90)
		and (acs.isautolivempositiontaking = 1 or custsetting3rd.isautolivempositiontaking = 1)	
end
-------------------------------------------------------------------------------------

--check master min/max
--update m1=n3-a1 if a1+m1<n3
Update custsetting3rd with (ROWLOCK, UPDLOCK) set 
	mlivepositiontaking = mco.minlivepositiontaking-custsetting3rd.alivepositiontaking
from 
	custsetting3rd inner join custinfo as mb with (NOLOCK) on custsetting3rd.custid = mb.custid
	inner join custoverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=custsetting3rd.sporttype and mco.bettype=custsetting3rd.bettype
where custsetting3rd.sporttype=161 and custsetting3rd.bettype in (85,86,87,89,90) 
	and custsetting3rd.alivepositiontaking+custsetting3rd.mlivepositiontaking<mco.minlivepositiontaking
	and custsetting3rd.custid in (select custid from #tmp)

-----------------------------------------------------------------------------------------------------------------------------------


--update m1,a1 when a1+m1>l3
--update m1=if(min(m3,l3)-a1<0,0,min(m3,l3)-a1)
--update a1=if(a1+m1>min(m3,l3),min(m3,l3)-m1,a1)
Update custsetting3rd with (ROWLOCK, UPDLOCK) set 
	@maxmapos = case when mcs.mlivepositiontaking>mco.maxlivepositiontaking then mco.maxlivepositiontaking else mcs.mlivepositiontaking end,
	@mpos = case when @maxmapos-custsetting3rd.alivepositiontaking<0 then 0 else @maxmapos-custsetting3rd.alivepositiontaking end,
	mlivepositiontaking = @mpos,
	@apos = case when custsetting3rd.alivepositiontaking + @mpos>@maxmapos then @maxmapos-@mpos else custsetting3rd.alivepositiontaking end,
	alivepositiontaking = case when @apos<aco.minlivepositiontaking then aco.minlivepositiontaking else @apos end
from 
	custsetting3rd inner join custinfo as mb with (NOLOCK) on custsetting3rd.custid = mb.custid
	inner join custsetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=custsetting3rd.sporttype and mcs.bettype=custsetting3rd.bettype
	inner join custoverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=custsetting3rd.sporttype and mco.bettype=custsetting3rd.bettype
	inner join custoverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting3rd.sporttype and aco.bettype=custsetting3rd.bettype
where custsetting3rd.sporttype=161 and custsetting3rd.bettype in (85,86,87,89,90) 
	and custsetting3rd.alivepositiontaking+custsetting3rd.mlivepositiontaking>mco.maxlivepositiontaking
	and custsetting3rd.custid in (select custid from #tmp)
-----------------------------------------------------------------------------------------------------------------------------------

waitfor delay '00:00:03'

--recal autopos
if @updautosuper = 1 
begin	
	Update custsetting3rd with (ROWLOCK, UPDLOCK) 
		set slivepositiontaking = case when scs.slivepositiontaking-custsetting3rd.mlivepositiontaking-custsetting3rd.alivepositiontaking >
								(case when custsetting3rd.isautolivepositiontaking=1 then custsetting3rd.autolivepositiontaking else mcs.autolivepositiontaking end) then (case when custsetting3rd.isautolivepositiontaking=1 then custsetting3rd.autolivepositiontaking else mcs.autolivepositiontaking end) else scs.slivepositiontaking-custsetting3rd.mlivepositiontaking-custsetting3rd.alivepositiontaking end 
	from
		custsetting3rd
		inner join custinfo as c with (NOLOCK) on custsetting3rd.custid = c.custid
		inner join custsetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting3rd.sporttype and mcs.bettype=custsetting3rd.bettype
		inner join custsetting3rd as scs with (NOLOCK) on scs.custid = c.srecommend and scs.sporttype=custsetting3rd.sporttype and scs.bettype=custsetting3rd.bettype
	where
		c.custid in (select custid from #tmp)		
		and custsetting3rd.sporttype = 161
		and custsetting3rd.bettype in (85,86,87,89,90)
		and (custsetting3rd.isautolivepositiontaking=1 or mcs.isautolivepositiontaking=1)	
end

--check super min/max
--update s1 when s1+m1+a1<n4 or s1+m1+a1>l4
Update custsetting3rd with (ROWLOCK, UPDLOCK) set 
	slivepositiontaking = sco.minlivepositiontaking-custsetting3rd.mlivepositiontaking-custsetting3rd.alivepositiontaking
from 
	custsetting3rd inner join custinfo as mb with (NOLOCK) on custsetting3rd.custid = mb.custid
	inner join custoverride3rd as sco with (NOLOCK) on sco.custid = mb.srecommend  and sco.sporttype=custsetting3rd.sporttype and sco.bettype=custsetting3rd.bettype
where custsetting3rd.sporttype=161 and custsetting3rd.bettype in (85,86,87,89,90) 
	and custsetting3rd.alivepositiontaking+custsetting3rd.mlivepositiontaking+custsetting3rd.slivepositiontaking<sco.minlivepositiontaking
	and custsetting3rd.custid in (select custid from #tmp)

--update s1,m1,a1 in case s1+m1+a1>s4
--s1=max(0,s4-m1-a1)
--@mapos1=iif(s1_new+m1+a1>s4,s4-s1_new,m1+a1)
--@maxmapos=min(m3,l3)
--@mapos2=min(@mapos1,@maxmapos)
--@mapos=max(@mapos2,n3)
--m1=max(0,@mapos-a1)
--a1=iif(m1_new+a1>@mapos,@mapos-m1_new,a1)
Update custsetting3rd with (ROWLOCK, UPDLOCK) set 
	@spos = case when scs.slivepositiontaking-custsetting3rd.mlivepositiontaking-custsetting3rd.alivepositiontaking<0 then 0 else scs.slivepositiontaking-custsetting3rd.mlivepositiontaking-custsetting3rd.alivepositiontaking end,
	slivepositiontaking = @spos,
	@mapos1 = case when @spos+custsetting3rd.mlivepositiontaking+custsetting3rd.alivepositiontaking>scs.slivepositiontaking then scs.slivepositiontaking-@spos else custsetting3rd.mlivepositiontaking+custsetting3rd.alivepositiontaking end,
	@maxmapos = case when mcs.mlivepositiontaking>mco.maxlivepositiontaking then mco.maxlivepositiontaking else mcs.mlivepositiontaking end,
	@mapos2 = case when @mapos1>@maxmapos then @maxmapos else @mapos1 end,
	@mapos = case when @mapos2<mco.minlivepositiontaking then mco.minlivepositiontaking else @mapos2 end,
	@mpos = case when @mapos-custsetting3rd.alivepositiontaking<0 then 0 else @mapos-custsetting3rd.alivepositiontaking end,
	mlivepositiontaking = @mpos,
	@apos = case when custsetting3rd.alivepositiontaking + @mpos>@mapos then @mapos-@mpos else custsetting3rd.alivepositiontaking end,
	alivepositiontaking = case when @apos<aco.minlivepositiontaking then aco.minlivepositiontaking else @apos end
from 
	custsetting3rd inner join custinfo as mb with (NOLOCK) on custsetting3rd.custid = mb.custid
	inner join custsetting3rd as scs with (NOLOCK) on scs.custid = mb.srecommend  and scs.sporttype=custsetting3rd.sporttype and scs.bettype=custsetting3rd.bettype
	inner join custsetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=custsetting3rd.sporttype and mcs.bettype=custsetting3rd.bettype
	inner join custoverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=custsetting3rd.sporttype and mco.bettype=custsetting3rd.bettype
	inner join custoverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting3rd.sporttype and aco.bettype=custsetting3rd.bettype
where custsetting3rd.sporttype=161 and custsetting3rd.bettype in (85,86,87,89,90) 
	and custsetting3rd.slivepositiontaking+custsetting3rd.alivepositiontaking+custsetting3rd.mlivepositiontaking>scs.slivepositiontaking
	and custsetting3rd.custid in (select custid from #tmp)



