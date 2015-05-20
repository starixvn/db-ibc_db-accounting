

--- 204 rows affected
UPDATE Dep_Custsetting3rd WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0,
	mpositiontaking = 0,
	apositiontaking = 0
WHERE custid IN (SELECT custid FROM f_depsuper_1('12BET'))
AND sporttype IN (151,152,153)
AND (	spositiontaking <> 0
		OR mpositiontaking <> 0
		OR apositiontaking <> 0
	)


--- 528 rows affected
UPDATE Dep_Custsetting3rd WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0,
	mpositiontaking = 0,
	apositiontaking = 0
WHERE custid IN ( SELECT custid 
				  FROM custinfo WITH(NOLOCK)
				  WHERE srecommend IN (SELECT custid FROM f_depsuper_1('12BET'))
						AND roleid = 3
				)
AND sporttype IN (151,152,153)
AND (	spositiontaking <> 0
		OR mpositiontaking <> 0
		OR apositiontaking <> 0
	)

/*
SELECT COUNT(1)
FROM custInfo c WITH(NOLOCK)
	INNER JOIN Dep_CustSetting3rd cs3 WITH(NOLOCK) ON c.custid = cs3.custid
WHERE c.srecommend IN (SELECT custid FROM f_DepSuper_1('12BET'))
	AND roleid IN (3,4)
	AND (	spositiontaking <> 0
			OR mpositiontaking <> 0
			OR apositiontaking <> 0
		)
	AND sporttype IN (151,152,153)

*/