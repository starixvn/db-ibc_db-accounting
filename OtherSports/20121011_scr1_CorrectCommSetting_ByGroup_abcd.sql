UPDATE cp WITH(ROWLOCK,UPDLOCK)
SET cp.sdiscount = case when right(c.ugroup,1) = 'a' then cs.groupa
						when right(c.ugroup,1) = 'b' then cs.groupb
						when right(c.ugroup,1) = 'c' then cs.groupc
						when right(c.ugroup,1) = 'd' then cs.groupd
						else cp.sdiscount end,
	cp.adiscount = case when right(c.ugroup,1) = 'a' then cm.groupa
						when right(c.ugroup,1) = 'b' then cm.groupb
						when right(c.ugroup,1) = 'c' then cm.groupc
						when right(c.ugroup,1) = 'd' then cm.groupd
						else cp.adiscount end,
	cp.discount =  case when right(c.ugroup,1) = 'a' then ca.groupa
						when right(c.ugroup,1) = 'b' then ca.groupb
						when right(c.ugroup,1) = 'c' then ca.groupc
						when right(c.ugroup,1) = 'd' then ca.groupd
						else cp.discount end,
	cp.playerdiscount = ----- IF playerdiscount > discount THEN discount ELSE playerdiscount END
						CASE WHEN  (case when right(c.ugroup,1) = 'a' then ca.groupa
										when right(c.ugroup,1) = 'b' then ca.groupb
										when right(c.ugroup,1) = 'c' then ca.groupc
										when right(c.ugroup,1) = 'd' then ca.groupd
										else cp.playerdiscount end
									) > 
									(case when right(c.ugroup,1) = 'a' then ca.groupa
										when right(c.ugroup,1) = 'b' then ca.groupb
										when right(c.ugroup,1) = 'c' then ca.groupc
										when right(c.ugroup,1) = 'd' then ca.groupd
										else cp.discount end
									)
									THEN (case when right(c.ugroup,1) = 'a' then ca.groupa
											when right(c.ugroup,1) = 'b' then ca.groupb
											when right(c.ugroup,1) = 'c' then ca.groupc
											when right(c.ugroup,1) = 'd' then ca.groupd
											else cp.discount end
										)
									ELSE (case when right(c.ugroup,1) = 'a' then ca.groupa
											when right(c.ugroup,1) = 'b' then ca.groupb
											when right(c.ugroup,1) = 'c' then ca.groupc
											when right(c.ugroup,1) = 'd' then ca.groupd
											else cp.playerdiscount end
										) END
FROM customer c WITH(NOLOCK)
	INNER JOIN custsetting cp ON c.custid = cp.custid
	INNER JOIN custsetting cs WITH(NOLOCK) ON c.srecommend = cs.custid AND cp.sporttype = cs.sporttype and cp.bettype = cs.bettype
	INNER JOIN custsetting cm WITH(NOLOCK) ON c.mrecommend = cm.custid AND cp.sporttype = cm.sporttype and cp.bettype = cm.bettype
	INNER JOIN custsetting ca WITH(NOLOCK) ON c.recommend  = ca.custid AND cp.sporttype = ca.sporttype and cp.bettype = ca.bettype
WHERE cp.bettype IN (1,2,3,7,8)
	AND cs.bettype IN (1,2,3,7,8)
	AND cm.bettype IN (1,2,3,7,8)
	AND ca.bettype IN (1,2,3,7,8)
	AND ( 
		   cp.sdiscount <> case when right(c.ugroup,1) = 'a' then cs.groupa
								when right(c.ugroup,1) = 'b' then cs.groupb
								when right(c.ugroup,1) = 'c' then cs.groupc
								when right(c.ugroup,1) = 'd' then cs.groupd
								else cp.sdiscount end
		OR cp.adiscount <> case when right(c.ugroup,1) = 'a' then cm.groupa
								when right(c.ugroup,1) = 'b' then cm.groupb
								when right(c.ugroup,1) = 'c' then cm.groupc
								when right(c.ugroup,1) = 'd' then cm.groupd
								else cp.adiscount end
		OR cp.discount  <> case when right(c.ugroup,1) = 'a' then ca.groupa
								when right(c.ugroup,1) = 'b' then ca.groupb
								when right(c.ugroup,1) = 'c' then ca.groupc
								when right(c.ugroup,1) = 'd' then ca.groupd
								else cp.discount end
		OR cp.playerdiscount > case when right(c.ugroup,1) = 'a' then ca.groupa
									when right(c.ugroup,1) = 'b' then ca.groupb
									when right(c.ugroup,1) = 'c' then ca.groupc
									when right(c.ugroup,1) = 'd' then ca.groupd
									else cp.playerdiscount end
		)	
	AND c.custid IN (166836,  -- MIDRP68115
					 79469,	  -- MIDRP68116
					 7748324  -- supertestp2p010201001
					)