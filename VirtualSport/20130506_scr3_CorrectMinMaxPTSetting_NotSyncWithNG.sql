
SELECT custid 
INTO #789Customer
FROM customer 
WITH(NOLOCK) WHERE site = '789y' AND roleid = 4

-- Correct min/max PT setting for super
-- 18 rows affected
UPDATE vs WITH(ROWLOCK,UPDLOCK)
SET vs.minpositiontaking = ng.minpositiontaking,
	vs.maxpositiontaking = ng.maxpositiontaking
FROM custoverride3rd vs
	INNER JOIN custoverride3rd ng WITH(NOLOCK) ON vs.custid = ng.custid
WHERE vs.custid IN (SELECT custid FROM #789Customer)
	AND vs.sporttype = 180 AND vs.bettype = 1201
	AND ng.sporttype = 161 AND ng.bettype = 81
	AND (vs.minpositiontaking <> ng.minpositiontaking
		OR vs.maxpositiontaking <> ng.maxpositiontaking
		)
		
		
-- Correct min/max PT setting for master,agent
-- 18 rows affected
UPDATE vs WITH(ROWLOCK,UPDLOCK)
SET vs.minpositiontaking = ng.minpositiontaking,
	vs.maxpositiontaking = 0.9
FROM custoverride3rd vs
	INNER JOIN custoverride3rd ng WITH(NOLOCK) ON vs.custid = ng.custid
	INNER JOIN custinfo c WITH(NOLOCK) ON c.custid = vs.custid
WHERE c.srecommend IN (SELECT custid FROM #789Customer)
	AND roleid BETWEEN 2 AND 3
	AND vs.sporttype = 180 AND vs.bettype = 1201
	AND ng.sporttype = 161 AND ng.bettype = 81
	AND (vs.minpositiontaking <> ng.minpositiontaking
		OR vs.maxpositiontaking <> 0.9
		)