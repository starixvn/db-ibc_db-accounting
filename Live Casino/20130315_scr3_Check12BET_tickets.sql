
/*
	check PT setting on bet ticket for bets that did not get 93% PT
	&
	This script use for correct PT setting in bettrans & do resettle (using web function)
	Step:
		1. Get matchid affected
		2. Get transid affected
		3. Correct PT on these tickets from step 2
		4. Get match info to do resettle (matchid from step 1)
*/


--- check if there are tickets on 2013-03-14 have PT = 0.93
--SELECT DISTINCT matchid
--FROM bettrans WITH(NOLOCK)
--WHERE winlostdate = '2013-03-14'
--AND bettype IN (1101,1102)
--AND srecommend IN (SELECT custid FROM f_depsuper_1('12BET'))
--AND apositiontaking = 0.93

 

--- check if there are tickets on 2013-03-15 have PT <> 0.93
--- get affected matches
SELECT DISTINCT matchid
INTO #match
FROM bettrans WITH(NOLOCK)
WHERE winlostdate = '2013-03-15'
AND bettype IN (1101,1102)
AND srecommend IN (SELECT custid FROM f_depsuper_1('12BET'))
AND (apositiontaking <> 0.93
	OR 
	tpositiontaking <> 0.93
	)

-- if there are no any affected tickets then return

return


---correct PT in bettrans
SELECT transid
INTO #trans
FROM bettrans WITH(NOLOCK)
WHERE winlostdate = '2013-03-15'
AND bettype IN (1101,1102)
AND srecommend IN (SELECT custid FROM f_depsuper_1('12BET'))
AND (apositiontaking <> 0.93
	OR 
	tpositiontaking <> 0.93
	)
AND matchid IN (SELECT matchid FROM #match)

--- depend on number of affected ticktes, modify for each batch
DECLARE @n INT
SET @n = 2000

WHILE 1 = 1
BEGIN 
	UPDATE TOP(@n) bettrans WITH(ROWLOCK,UPDLOCK)
	SET apositiontaking = 0.93,
		tpositiontaking = 0.93
	WHERE transid IN (SELECT transid FROM #trans)
	AND (apositiontaking <> 0.93
		OR 
		tpositiontaking <> 0.93
		)
	IF @@ROWCOUNT <> @n
		BREAK
END


--Update BettransG 
--141 rows affected

UPDATE	BettransG with (UPDLOCK,ROWLOCK)
SET		 apositiontaking=0.93
		,tpositiontaking=0.93
WHERE	MatchID IN (SELECT matchid FROM #Match WITH (NOLOCK) )
		AND refno IN (
			SELECT	refno 
			FROM	bettrans WITH (nolock) 
			WHERE	transid IN (SELECT transid FROM #trans WITH (NOLOCK) )
		)
		AND bettype IN (1101,1102)



--- check match info for resettle

SELECT matchid, matchcode, eventdate, betstatus
FROM match WITH(NOLOCK)
WHERE matchid IN (SELECT matchid FROM #match)
