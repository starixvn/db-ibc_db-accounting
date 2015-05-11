


-- check
SELECT huk.custid, huk.sporttype, huk.bettype, huk.spositiontaking, huk.mpositiontaking, huk.apositiontaking,
		huk.isautopositiontaking, huk.autopositiontaking, huk.isautompositiontaking, huk.autompositiontaking,
		gau.custid, gau.sporttype, gau.bettype, gau.spositiontaking, gau.mpositiontaking, gau.apositiontaking,
		gau.isautopositiontaking, gau.autopositiontaking, gau.isautompositiontaking, gau.autompositiontaking
FROM custsetting3rd huk WITH(NOLOCK)
	INNER JOIN custsetting3rd gau WITH(NOLOCK) ON huk.custid = gau.custid
		AND huk.sporttype = gau.sporttype - 1 AND huk.bettype = gau.bettype - 10
WHERE huk.sporttype = 151 AND huk.bettype BETWEEN 41 AND 42
	AND gau.sporttype = 152 AND gau.bettype BETWEEN 51 AND 52
AND (huk.spositiontaking <> gau.spositiontaking
	OR huk.mpositiontaking <> gau.mpositiontaking
	OR huk.apositiontaking <> gau.apositiontaking
	OR huk.autopositiontaking <> gau.autopositiontaking
	OR huk.isautopositiontaking<> gau.isautopositiontaking
	OR huk.autompositiontaking <> gau.autompositiontaking
	OR huk.isautompositiontaking <> gau.isautompositiontaking)
	


---- update 

WHILE 1 = 1 
BEGIN 
	UPDATE TOP(20000) gau WITH(ROWLOCK,UPDLOCK)
	SET spositiontaking = huk.spositiontaking,
		mpositiontaking = huk.mpositiontaking,
		apositiontaking = huk.apositiontaking,
		isautopositiontaking	= huk.isautopositiontaking,
		autopositiontaking		= huk.autopositiontaking,
		isautompositiontaking	= huk.isautompositiontaking,
		autompositiontaking		= huk.autompositiontaking
	FROM custsetting3rd gau
		INNER JOIN custsetting3rd huk WITH(NOLOCK) ON huk.custid = gau.custid
			AND huk.sporttype = gau.sporttype - 1 AND huk.bettype = gau.bettype - 10
	WHERE gau.sporttype = 152 AND gau.bettype BETWEEN 51 AND 52
		AND huk.sporttype = 151 AND huk.bettype BETWEEN 41 AND 42
		AND (huk.spositiontaking <> gau.spositiontaking
			OR huk.mpositiontaking <> gau.mpositiontaking
			OR huk.apositiontaking <> gau.apositiontaking
			OR huk.autopositiontaking <> gau.autopositiontaking
			OR huk.isautopositiontaking<> gau.isautopositiontaking
			OR huk.autompositiontaking <> gau.autompositiontaking
			OR huk.isautompositiontaking <> gau.isautompositiontaking)
	IF @@ROWCOUNT <> 20000
		BREAK
	WAITFOR DELAY '00:00:01'
END




 