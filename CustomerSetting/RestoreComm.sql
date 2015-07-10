Update custsetting set 
playerdiscount = c2.playerdiscount, discount=c2.discount, adiscount=c2.adiscount, 
sdiscount=c2.sdiscount, groupa=c2.groupa, groupb=c2.groupb, groupc=c2.groupc, groupd=c2.groupd, groupe=c2.groupe, groupf=c2.groupf
from custsetting c1
inner join db06.bodb02.dbo.custsetting1 c2 on c1.custid = c2.custid and c1.bettype = c2.bettype and c1.sporttype = c2.sporttype
where c1.custid in (select custid from customer where mrecommend = 643884 and roleid in(1,2))

---DB06

insert into custsetting1 (custid, bettype, sporttype, playerdiscount, discount, adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf)
select custid, bt,spt,pdis,adis,mdis, sdis, grpA,grpB, grpC,grpD,grpE, grpF
from custsetting_history
where custid in (select custid from customer where mrecommend = 643884 and roleid in(1))
and updatetime between '2007-12-18 10:00:24.430' and '2007-12-18 10:02:24.430' 
and mdis>0

