
UPDATE cp WITH(ROWLOCK,UPDLOCK)
SET cp.sdiscount = cs.sdiscount,
	cp.adiscount = cm.adiscount,
	cp.discount  =  ca.discount,
	cp.playerdiscount = CASE WHEN cp.playerdiscount > ca.discount THEN ca.discount ELSE cp.playerdiscount END
FROM customer c WITH(NOLOCK)
	INNER JOIN custsetting cp ON c.custid = cp.custid
	INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid AND cp.sporttype = cs.sporttype and cp.bettype = cs.bettype
	INNER JOIN custsetting cm WITH(NOLOCK) ON c.mrecommend = cm.custid AND cp.sporttype = cm.sporttype and cp.bettype = cm.bettype
	INNER JOIN custsetting ca WITH(NOLOCK) ON c.recommend  = ca.custid AND cp.sporttype = ca.sporttype and cp.bettype = ca.bettype
WHERE cp.bettype IN (4,5,6,9,10,20,21,22)	
	AND cs.bettype IN (4,5,6,9,10,20,21,22)	
	AND cm.bettype IN (4,5,6,9,10,20,21,22)	
	AND ca.bettype IN (4,5,6,9,10,20,21,22)	
	AND (
			cp.sdiscount <> cs.sdiscount
			OR cp.adiscount <> cm.adiscount
			OR cp.discount <> ca.discount
			OR cp.playerdiscount > ca.discount
		)
	AND c.custid IN (
				426877	,	-- SMM0889001
				431878	,	-- SMM0889002
				431882	,	-- SMM0889008
				431889	,	-- SMM0889009
				431927	,	-- SMM0889021
				431963	,	-- SMM0889063
				431970	,	-- SMM0889068
				644725	,	-- BI8803380
				791821	,	-- MPHRM53818
				820437	,	-- MPHRM53717
				939720	,	-- MPHRM53008
				983431	,	-- MPHRM53001
				1202975	,	-- BI4545019
				1204274	,	-- BI4545012
				1204353	,	-- BI4545014
				1204358	,	-- BI4545015
				1210605	,	-- D3H3333002
				1322449	,	-- BI4545027
				1438330	,	-- MPHRM53006
				1438345	,	-- MPHRM53004
				1438355	,	-- MPHRM53005
				1635812	,	-- CI9965002
				1635813	,	-- CI9965003
				1635815	,	-- CI9965004
				1635880	,	-- CI9999066
				1635881	,	-- CI9999068
				1645223	,	-- BI4551231
				1646123	,	-- BI4551015
				1668129	,	-- S11S0601921
				1668195	,	-- S11S0601588
				1668210	,	-- S11S0601589
				1668222	,	-- S11S0601587
				1668254	,	-- S11S0601993
				1668269	,	-- S11S0601855
				1668288	,	-- S11S0601290
				1668323	,	-- S11S0601631
				1668342	,	-- S11S0601199
				1668360	,	-- S11S0601177
				1668369	,	-- S11S0601300
				1668413	,	-- S11S0601301
				1668430	,	-- S11S0601302
				1668451	,	-- S11S0601304
				1668475	,	-- S11S0601303
				1668521	,	-- S11S0601793
				1668526	,	-- S11S0601994
				1668559	,	-- S11S0601217
				1668573	,	-- S11S0601009
				1668582	,	-- S11S0601838
				1668586	,	-- S11S0601110
				1668596	,	-- S11S0601700
				1668606	,	-- S11S0601222
				1668620	,	-- S11S0601553
				1672823	,	-- S11S0601000
				1680552	,	-- S11S0601701
				1682683	,	-- S11S0601221
				1682756	,	-- S11S0601712
				1684999	,	-- M6EU01139
				1740192	,	-- BI4551002
				1743229	,	-- MPHRM53997
				1743231	,	-- MPHRM53996
				1774743	,	-- donkey120
				4538321	,	-- SUPERTEST240601001
				4921136	,	-- SKAT50L8X11
				5421207		-- JC77EE1801
			)
