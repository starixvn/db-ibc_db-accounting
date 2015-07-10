 
--- only 1 member with srecommend > 100
UPDATE custsetting WITH(ROWLOCK,UPDLOCK)
SET sdiscount = 0.01,
	adiscount = 0.01
WHERE custid = 5421207 AND bettype = 4 AND sporttype = 1


--- correct comm for 1 direct master
UPDATE custsetting WITH(ROWLOCK,UPDLOCK)
SET adiscount = 0.01
WHERE custid = 1035071 AND bettype = 4 AND sporttype = 1


--- correct comm for member under direct master
UPDATE cp WITH(ROWLOCK,UPDLOCK)
SET cp.sdiscount = cs.sdiscount,
	cp.adiscount = cm.adiscount,
	cp.discount  = ca.discount	
FROM custsetting cp
	INNER JOIN custinfo c WITH(NOLOCK) ON cp.custid = c.custid
	INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid AND cp.bettype = cs.bettype
	INNER JOIN custsetting cm WITH(NOLOCK) ON c.mrecommend = cm.custid AND cp.bettype = cm.bettype
	INNER JOIN custsetting ca WITH(NOLOCK) ON c.recommend =  ca.custid AND cp.bettype = ca.bettype
WHERE cp.bettype = 4 AND cp.sporttype = 1 AND c.custid IN 
(1027739,
1027742	,
1027745	,
1027750	,
1027751	,
1027758	,
1032709	,
1032813	,
1033999	,
1343	,
1385	,
1404	,
1411	,
1418	,
1447	,
1635	,
1637	,
1646	,
1680	,
1725	,
1743	,
1799	,
1803	,
2360	,
2361	,
2942	,
3507	,
6317	,
6750	,
7906	,
11557	,
15083	,
15966	,
24713	,
29447	,
34686	,
88291	,
106514	,
193690	,
317672	,
321555	,
545882	,
674065	,
567123)
