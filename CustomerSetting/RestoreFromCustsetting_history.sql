 Update cs set mpositiontaking = mpos, mlivepositiontaking = mlive
from custsetting cs
inner join DB06.bodb02.dbo.custsetting_history csh  on cs.custid =  csh.custid and
cs.bettype =  csh.bt AND cs.sporttype =  csh.spt
where cs.custid in (select custid from customer (nolock) where mrecommend = 888665 and roleid = 1)
and csh.updatetime between '2008-06-07 04:31:00.000' and '2008-06-07 04:31:50.000'