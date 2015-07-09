

UPDATE cm WITH(ROWLOCK,UPDLOCK)
SET cm.groupa = cs.groupa,
	cm.groupb = cs.groupb,
	cm.groupc = cs.groupc,
	cm.groupd = cs.groupd
FROM customer c WITH(NOLOCK)
	INNER JOIN custsetting cm ON c.custid = cm.custid
	INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid AND cm.sporttype = cs.sporttype AND cm.bettype = cs.bettype
WHERE cm.bettype IN (1,2,3,7,8)
	AND  (	cm.groupa <> cs.groupa
			OR cm.groupb <> cs.groupb
			OR cm.groupc <> cs.groupc
			OR cm.groupd <> cs.groupd
		 )
	AND c.custid IN (	4778	,
						15515	,
						17742	,
						31971	,
						68287	,
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
--select c.custid,c.srecommend,c.username,cs.groupa, cm.groupa,cs.groupb, cm.groupb,cs.groupc,cm.groupc, cs.groupd,cm.groupd
select distinct c.custid ,','
from Customer c with(nolock)
	inner join CustSetting cm with(nolock) on c.custid = cm.custid
	inner join custsetting cs with(nolock) on c.srecommend = cs.custid and cm.sporttype = cs.sporttype and cm.bettype = cs.bettype
	inner join CustSuper cp witH(nolock) on c.srecommend = cp.custid
where cp.IsInternal = 0 and c.roleid = 3
	and c.srecommend <= 100
	and (cm.groupa <> cs.groupa
		or cm.groupb <> cs.groupb
		or cm.groupc <> cs.groupc
		or cm.groupd <> cs.groupd
		)
and cm.bettype in (1,2,3,7,8)
*/