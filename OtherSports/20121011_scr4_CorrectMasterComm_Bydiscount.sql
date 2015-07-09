
UPDATE cm WITH(ROWLOCK,UPDLOCK)
SET cm.adiscount = cs.sdiscount	
FROM customer c WITH(NOLOCK)
	INNER JOIN custsetting cm ON c.custid = cm.custid
	INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid AND cm.sporttype = cs.sporttype AND cm.bettype = cs.bettype
WHERE cm.bettype IN (4,5,6,9,10,20,21,22)
	AND  cm.adiscount <> cs.sdiscount
	AND c.custid IN (	4778	,
						15515	,
						17742	,
						31971	,
						79582	,
						79618	,
						79619	,
						79620	,
						79621	,
						79622	,
						79632	,
						79634	,
						120978	,
						220790	,
						669346	,
						684533	,
						1035021	,
						1035071	,
						1044110	,
						1051508	,
						1075622	,
						1118925	,
						1142022	,
						1255625	,
						1683519	,
						1683711	,
						3645792	,
						4430377	,
						6201631	
					)
					
					
/*
select c.custid,c.srecommend,c.username,cm.sporttype, cm.bettype,cm.sdiscount ,cs.sdiscount
--select distinct c.custid ,','
from Customer c with(nolock)
	inner join CustSetting cm with(nolock) on c.custid = cm.custid
	inner join custsetting cs with(nolock) on c.srecommend = cs.custid and cm.sporttype = cs.sporttype and cm.bettype = cs.bettype
	inner join CustSuper cp witH(nolock) on c.srecommend = cp.custid
where cp.IsInternal = 0 and c.roleid = 3
	and c.srecommend <= 100
	and cm.adiscount <> cs.sdiscount
	and cm.bettype IN (4,5,6,9,10,20,21,22)

*/