 --DB06.bodb_Archive
 
 --Get bet ticket of Casino/P2P/Bingo under 3rdSuper
select * into bettrans_bk_3rdSuper from bettrans_bk with (nolock) 
where winlostdate between '2010-1-1' and '2010-6-30'
	and bettype IN(71,73,1000)							
	AND matchid = 0 
	and srecommend IN
	(
		select custid from bodb02.dbo.custinfo with (nolock) 
		where username like '3rdSuper%' and roleid = 4
	)


--Get all transfers under 3rdSuper
select * into transfer_bk_3rdSuper from transfer_bk with (nolock) 
where winlostdate between '2010-2-1' and '2010-4-30'
	and srecommend IN
	(
		select custid from bodb02.dbo.custinfo with (nolock) 
		where username like '3rdSuper%' and roleid = 4
	)
 
insert into transfer_bk_3rdSuper
select * from transfer_bk with (nolock) 
where winlostdate between '2012-7-1' and '2012-7-30'
	and srecommend IN
	(
		select custid from bodb02.dbo.custinfo with (nolock) 
		where username like '3rdSuper%' and roleid = 4
	)

 
--Get outside transfers related to 3rdSuper
select * into transfer_bk_3rdSuper_Out
from transfer_bk with (nolock) 
where winlostdate between '2010-7-1' and '2010-12-31'
	and srecommend NOT IN
	(
		select custid from bodb02.dbo.custinfo with (nolock) 
		where username like '3rdSuper%' and roleid = 4
	)
	and refno IN(select distinct refno from bodb_archive.dbo.transfer_bk_3rdSuper group by refno)


--Get all statement under 3rdSuper
select * into statement_3rdSuper 
from bodb_report.dbo.statement with (nolock) 
where accdate between '2010-1-1' and '2010-1-31 11:59:59 PM'
	and custid IN
	(	
		
		select custid from bodb02.dbo.custinfo with (nolock) 
		where srecommend IN(select custid from bodb02.dbo.custinfo with (nolock) where username like '3rdSuper%' and roleid = 4)
	)

insert into statement_3rdSuper
select * from bodb_report.dbo.statement with (nolock) 
where accdate between '2012-1-1' and '2012-07-31 11:59:59 PM'
	and custid IN
	(		
		select custid from bodb02.dbo.custinfo with (nolock) 
		where srecommend IN(select custid from bodb02.dbo.custinfo with (nolock) where username like '3rdSuper%' and roleid = 4)
	)