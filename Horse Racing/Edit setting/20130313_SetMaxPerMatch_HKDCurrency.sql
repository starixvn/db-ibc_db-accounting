


/*
	set maxpermatch for HKD supers 400.000
*/

--- update maxpermatch for direct master 
-- 175 rows affected
UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
SET maxpermatch151_OT = 400000,
	maxpermatch151_AU = 400000
WHERE srecommend = 5 AND roleid IN (3,4)


/* normal customers */

-- get all normal supers
SELECT c.custid INTO #super
FROM custInfo c WITH(NOLOCK)
	INNER JOIN CustSuper sp WITH(NOLOCK) ON c.custid = sp.custid
WHERE roleid = 4
AND currency = 5
AND sp.IsInternal = 0
AND c.custid > 100
AND c.custid NOT IN (SELECT custid FROM f_DepSuper_1('ALL'))

-- update maxpermatch 
-- 739 rows affected
UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
SET maxpermatch151_OT = 400000,
	maxpermatch151_AU = 400000
WHERE custid IN (SELECT custid FROM #super)
