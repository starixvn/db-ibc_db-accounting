

/*
	This script use for correct PT setting in bettrans & do resettle (using web function)
	Step:
		1. Get matchid affected
		2. Get transid affected
		3. Correct PT on these tickets from step 2
		4. Get match info to do resettle (matchid from step 1)
*/


--1. get affected matches
SELECT DISTINCT matchid
INTO #match
FROM bettrans WITH(NOLOCK)
WHERE winlostdate = '2013-03-15'
AND bettype IN (1101,1102)
AND srecommend IN (SELECT custid FROM f_depsuper_1('12BET'))
AND apositiontaking <> 0.93


--2. get transid affected
SELECT transid
INTO #trans
FROM bettrans WITH(NOLOCK)
WHERE winlostdate = '2013-03-07'
AND bettype IN (1101,1102)
AND srecommend IN (SELECT custid FROM f_depsuper_1('12BET'))
AND apositiontaking <> 0.93
AND matchid IN (SELECT matchid FROM #match)

--3. correct PT 
--- depend on number of affected ticktes, modify for each batch
DECLARE @n INT
SET @n = 2000

WHILE 1 = 1
BEGIN 
	UPDATE TOP(@n) bettrans WITH(ROWLOCK,UPDLOCK)
	SET apositiontaking = 0.93
	WHERE transid IN (SELECT transid FROM #trans)
	AND apositiontaking <> 0.93
	
	IF @@ROWCOUNT <> @n
		BREAK
END




--4. get match info for resettle
SELECT matchid, matchcode, eventdate, betstatus
FROM match WITH(NOLOCK)
WHERE matchid IN (SELECT matchid FROM #match)