




---- 864 rows affected
UPDATE cs3 WITH(ROWLOCK,UPDLOCK)	
	SET sdiscount = CASE WHEN roleid IN (1,4) THEN CASE WHEN bettype IN (41,42,31,32) THEN 0.04 
														WHEN bettype IN (51,52) THEN 0.03
														ELSE 0
												   END
						 ELSE 0 
					END,
		adiscount = CASE WHEN roleid IN (1,3) THEN CASE WHEN bettype IN (41,42,31,32) THEN 0.04 
														WHEN bettype IN (51,52) THEN 0.03
														ELSE 0
												   END
						 ELSE 0 
					END,
		discount  = CASE WHEN roleid IN (1,2) THEN CASE WHEN bettype IN (41,42,31,32) THEN 0.04 
														WHEN bettype IN (51,52) THEN 0.03
														ELSE 0
												   END
						 ELSE 0 
					END,
		playerdiscount = 0
	FROM custinfo c WITH(NOLOCK)
		INNER JOIN dep_custsetting3rd cs3 ON c.custid = cs3.custid
	WHERE sporttype IN (151,152,153)
		AND cs3.custid IN (	7652044	,	--BODOGNZD
							7652050	,	--BODOGNZD01
							7651893	,	--BODOGAUD
							7651900	,	--BODOGAUD01
						)
						
						
/*
SELECT DISTINCT C.CUSTID, ',','--' + username
FROM custinfo c WITH(NOLOCK)
	INNER JOIN dep_custsetting3rd cs3 ON c.custid = cs3.custid
WHERE sporttype IN (151,152,153) AND srecommend IN (SELECT custid FROM f_DepSuper_1('BODOG'))
	AND ( sdiscount <> CASE WHEN roleid IN (1,4) THEN CASE WHEN bettype IN (41,42,31,32) THEN 0.04 
														WHEN bettype IN (51,52) THEN 0.03
														ELSE 0
												   END
						 ELSE 0 
					END OR
		adiscount <> CASE WHEN roleid IN (1,3) THEN CASE WHEN bettype IN (41,42,31,32) THEN 0.04 
														WHEN bettype IN (51,52) THEN 0.03
														ELSE 0
												   END
						 ELSE 0 
					END OR 
		discount  <> CASE WHEN roleid IN (1,2) THEN CASE WHEN bettype IN (41,42,31,32) THEN 0.04 
														WHEN bettype IN (51,52) THEN 0.03
														ELSE 0
												   END
						 ELSE 0 
					END OR
		playerdiscount <> 0
		)	
	and mrecommend not in (
		select custid
		from custinfo with(nolock)
		where srecommend in (select custid from f_depsuper_1('bodog'))
		and roleid = 3 and username like '%ACC%'
	)
		
		
----- check PT setting 
SELECT DISTINCT C.CUSTID, ',','--' + username
FROM custinfo c WITH(NOLOCK)
	INNER JOIN dep_custsetting3rd cs3 ON c.custid = cs3.custid
WHERE sporttype IN (151,152,153) AND srecommend IN (SELECT custid FROM f_DepSuper_1('BODOG'))
	and (spositiontaking <> 0 or mpositiontaking<>0 or apositiontaking<>0 )
	
*/