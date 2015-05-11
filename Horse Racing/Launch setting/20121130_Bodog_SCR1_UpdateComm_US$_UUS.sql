CREATE TABLE #tmpCust (CustID INT PRIMARY KEY)

INSERT INTO #tmpCust(custid)
SELECT custID  --, ', --', username
FROM Custinfo WITH (NOLOCK)
WHERE SRECOMMEND IN (SELECT custid FROM f_depsuper_1('bodog'))
and CURRENCY IN (3,20) 
AND custid NOT IN (
	4603309	, --	BODOGACCUUS
	4603323	, --	BODOGACCUUS01
	4603354	, --	BODOGTransferUUS
	4687035	, --	BODOGACCUS$
	4688632	, --	BODOGACCUS$01
	4688639	, --	BODOGTransferUS$
	7596562	  --	BODOGACCUS$88
)

---- 1027 rows affected
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
	AND cs3.custid IN ( SELECT CustID FROM #tmpCust WITH (NOLOCK))
	
	
DROP TABLE #tmpCust
					