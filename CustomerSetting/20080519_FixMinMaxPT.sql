select cs.custid, cs.apositiontaking, cs.mpositiontaking,cs.alivepositiontaking, cs.mlivepositiontaking,
	co.maxpositiontaking, co.maxlivepositiontaking,
	cs.mpositiontaking - (cs.apositiontaking+ cs.mpositiontaking - co.maxpositiontaking) as new_mpositiontaking,
cs.mlivepositiontaking - (cs.alivepositiontaking+ cs.mlivepositiontaking - co.maxlivepositiontaking) as new_mlivepositiontaking
from custsetting cs
inner join customer c on cs.custid = c.custid
inner join custoverride co on c.mrecommend = co.custid and cs.bettype = co.bettype and cs.sporttype = co.sporttype
where 
mrecommend in (select custid from customer with(nolock) where
username in ('SKU01', 'SKU03','SKU02' , 'SKU05', 'SKU08', 'SKU09','SKU31','SKU32', 'SKU35', 'SKU36'))
and roleid = 2
and cs.bettype = 1 and cs.sporttype = 1

Update custsetting set mpositiontaking = cs.mpositiontaking - (cs.apositiontaking+ cs.mpositiontaking - co.maxpositiontaking),
mlivepositiontaking = cs.mlivepositiontaking - (cs.alivepositiontaking+ cs.mlivepositiontaking - co.maxlivepositiontaking)
from custsetting cs
inner join customer c on cs.custid = c.custid
inner join custoverride co on c.mrecommend = co.custid and cs.bettype = co.bettype and cs.sporttype = co.sporttype
where 
mrecommend in (select custid from customer with(nolock) where
username in ('SKU01', 'SKU03','SKU02' , 'SKU05', 'SKU08', 'SKU09','SKU31','SKU32', 'SKU35', 'SKU36'))
and roleid = 2
--and cs.bettype = 1 and cs.sporttype = 1


================

select cs.custid, cs.apositiontaking, cs.mpositiontaking,cs.alivepositiontaking, cs.mlivepositiontaking,
	co.maxpositiontaking, co.maxlivepositiontaking
	
from custsetting cs
inner join customer c on cs.custid = c.custid
inner join custoverride co on c.custid = co.custid and cs.bettype = co.bettype and cs.sporttype = co.sporttype
where 
cs.custid in (select custid from customer with(nolock) where
username in ('SKU01', 'SKU03','SKU02' , 'SKU05', 'SKU08', 'SKU09','SKU31','SKU32', 'SKU35', 'SKU36'))
and roleid = 3
and cs.bettype = 1 and cs.sporttype = 1

Update custsetting set mpositiontaking = maxpositiontaking,
mlivepositiontaking = maxlivepositiontaking
from custsetting cs
inner join customer c on cs.custid = c.custid
inner join custoverride co on c.custid = co.custid and cs.bettype = co.bettype and cs.sporttype = co.sporttype
where 
cs.custid in (select custid from customer with(nolock) where
username in ('SKU01', 'SKU03','SKU02' , 'SKU05', 'SKU08', 'SKU09','SKU31','SKU32', 'SKU35', 'SKU36'))
and roleid = 3
--and cs.bettype = 1 and cs.sporttype = 1


