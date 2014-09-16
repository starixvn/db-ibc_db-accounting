
DECLARE @MINPT MONEY, @MAXPT MONEY
SELECT @MINPT = 0.86, @MAXPT = 0.9 
--SELECT @MINPT = 0.71, @MAXPT = 0.85
--SELECT @MINPT = 0.7, @MAXPT = 0.7


------ I. 3rd - Virtual Sports - Deadball-----------------
SELECT DISTINCT ci.username
			, ci.custid
			, 'Super' 'Level'
			, e.currency
			, c.site
			, hl.username 'Headline'
			, CASE
				WHEN ci.reject = 1
					THEN 'Suspended'
				ELSE 'Open'
				END AS Status
			,spositiontaking AS PT
FROM	dbo.CustSetting3rd cs WITH (NOLOCK)
	INNER JOIN dbo.CustInfo ci WITH (NOLOCK)
		ON	cs.CustId = ci.CustId
	INNER JOIN dbo.customer c WITH (NOLOCK) 
		ON c.CustId = ci.CustId
	INNER JOIN dbo.Exchange e WITH (NOLOCK)
		ON  e.exchangeid = c.currency 
	INNER JOIN dbo.site s WITH (NOLOCK)
		ON c.site = s.site
	LEFT JOIN dbo.custsuper csp WITH (NOLOCK)
		ON ci.custid = csp.custid
	LEFT JOIN dbo.custAccount ca WITH (NOLOCK)
		ON ca.custid = ci.custid
	LEFT JOIN (
				SELECT aa.custid
					, groupid
					, username
				FROM dbo.custaccount aa WITH (NOLOCK)
				INNER JOIN dbo.custinfo bb WITH (NOLOCK)
					ON aa.custid = bb.custid
				WHERE isgroupheadline = 1
				) hl
		ON ca.groupid = hl.groupid
WHERE ci.roleid = 4
    AND ci.custid >= 100
    AND c.Currency NOT IN (20,27,28)
    AND ci.enabled = 1
    AND ci.custid NOT IN (
							SELECT custid
							FROM Dep_CustSuper d WITH (NOLOCK)
						 )
    AND s.islicensee = 0
    AND ci.username NOT LIKE '3rdSuper%'
    AND ci.username NOT LIKE 'STEST%'
    AND csp.isinternal = 0
	AND cs.spositiontaking BETWEEN @MINPT AND @MAXPT
	AND cs.Sporttype BETWEEN 180 AND 186
 ORDER BY  c.site, ci.custID ,Status, PT
	 
 
	 

---------------------------------------------------------------------------------
------------------- II. 3rd - Virtual Sports - do not have Live ball------------------
 