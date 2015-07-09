 
/*12bet SUPER */

DECLARE @tmpSupers TABLE (ID INT IDENTITY, CustID INT)

INSERT INTO @tmpSupers(CustID)
		  SELECT 	1015419
UNION ALL SELECT 	1015427
UNION ALL SELECT 	791081
UNION ALL SELECT 	836212
UNION ALL SELECT 	1813575
UNION ALL SELECT 	836218
UNION ALL SELECT 	836226
UNION ALL SELECT 	1752415
UNION ALL SELECT 	836203
UNION ALL SELECT 	791080
UNION ALL SELECT 	916498
UNION ALL SELECT 	179457
UNION ALL SELECT 	3167631




DECLARE @SRecommend INT,
		@i INT,
		@MaxCount INT 

----SELECT  count(1) FROM 	@tmpSupers


SELECT @i = 1

SELECT	@SRecommend = custid
FROM	@tmpSupers
WHERE	ID = @i

WHILE @i <= 13 -- SELECT  count(1) FROM 	@tmpSupers
BEGIN
	EXEC [Acc_ExecRep_09] @SRecommend = @SRecommend
	
	SET @i = @i + 1

	SELECT @SRecommend = custid 
	FROM @tmpSupers
	WHERE id = @i
	
	WAITFOR DELAY '00:00:01'
END

--------------=============

--1. STEP 1 --12BET PT & COmmission : 50% pt; commission: 3% aust, 4% others 

ALTER PROCEDURE [dbo].[Acc_ExecRep_09] 	
    @srecommend		INT = 0
AS
BEGIN

    SET NOCOUNT ON

	IF (SELECT COUNT('') FROM sys.objects WITH(NOLOCK) WHERE name IN ('custsetting3rd','custinfo','custoverride3rd') AND type = 'u') <> 3
	BEGIN
		PRINT 'custsetting3rd or custinfo or custoverride3rd objects does not exist.'
		RETURN
	END

    ---- update PT on super
    UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
    SET spositiontaking = 0.5,
		mpositiontaking = 0.5,
		apositiontaking = 0.5,
		sdiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
		adiscount = 0,
		discount = 0,
		playerdiscount = 0 
    FROM	custsetting3rd cs3 
    WHERE	cs3.sporttype BETWEEN 151 AND 153 AND cs3.bettype IN (31,32,41,42,51,52)
			AND cs3.custID = @srecommend 
			AND (cs3.spositiontaking <> 0.5 OR cs3.mpositiontaking <> 0.5 OR cs3.apositiontaking <>0.5
				  OR ( sporttype between 151 and 152 AND bettype IN (31,32,41,42) and sdiscount <>0.04 )
				  OR (sporttype between 151 and 153  AND bettype IN (51,52) AND sdiscount <> 0.03 )
			)

    ---- update PT on master
    UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
    SET spositiontaking = 0,
		mpositiontaking = 0.5,
		apositiontaking = 0,
		sdiscount = 0,
		adiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
		discount = 0,
		playerdiscount = 0 
    FROM	custsetting3rd cs3
			INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
    WHERE	cs3.sporttype BETWEEN 151 AND 153 AND cs3.bettype IN (31,32,41,42,51,52)
			AND c.mrecommend NOT IN (927780,857227)
			AND c.srecommend = @srecommend 
			AND c.roleid = 3 
			AND (cs3.spositiontaking <> 0 OR cs3.mpositiontaking <> 0.5 OR cs3.apositiontaking <>0
				  OR ( sporttype between 151 and 152 AND bettype IN (31,32,41,42) and adiscount <>0.04 )
				  OR (sporttype between 151 and 153  AND bettype IN (51,52) AND adiscount <> 0.03 )
			)

    ---- update PT on agent
    UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
    SET spositiontaking = 0,
		mpositiontaking = 0,
		apositiontaking = 0.5,
		sdiscount = 0,
		adiscount = 0,
		discount  = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
		playerdiscount = 0 
    FROM custsetting3rd cs3
        INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
    WHERE	cs3.sporttype BETWEEN 151 AND 153 AND cs3.bettype IN (31,32,41,42,51,52)
			AND c.mrecommend NOT IN (927780,857227)
			AND c.srecommend = @srecommend 
			AND c.roleid =2 
			AND (cs3.spositiontaking <> 0 OR cs3.mpositiontaking <> 0 OR cs3.apositiontaking <>0.5
				  OR ( sporttype between 151 and 152 AND bettype IN (31,32,41,42) and discount <>0.04 )
				  OR (sporttype between 151 and 153  AND bettype IN (51,52) AND discount <> 0.03 )
			)


	---- update PT on master
    UPDATE co3 WITH(ROWLOCK,UPDLOCK)
    SET minpositiontaking = 0,
		maxpositiontaking = 0.5
    FROM custoverride3rd co3
        INNER JOIN custinfo c WITH(NOLOCK) ON co3.custid = c.custid
    WHERE co3.sporttype BETWEEN 151 AND 153 AND co3.bettype IN (31,32,41,42,51,52)
		AND c.mrecommend NOT IN (927780,857227)
		AND c.srecommend = @srecommend 
		AND co3.maxpositiontaking <>0.5		


    ---- update PT on member
	WHILE 1 = 1 
	BEGIN
		UPDATE TOP(20000) cs3 WITH(ROWLOCK,UPDLOCK)
		SET spositiontaking = 0,
			mpositiontaking = 0,
			apositiontaking = 0.5,
			sdiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			adiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			discount  = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			playerdiscount = 0 

		FROM custsetting3rd cs3
			INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
		WHERE cs3.sporttype BETWEEN 151 AND 153 AND cs3.bettype IN (31,32,41,42,51,52)
			  AND c.srecommend = @srecommend 
			  AND c.roleid = 1 
			  AND ( apositiontaking <> 0.5 OR mpositiontaking <> 0 OR spositiontaking <> 0 
					OR 
					sdiscount <> CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
					OR 
					adiscount <> CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
					OR 
					discount <> CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
				)
			AND c.mrecommend NOT IN (927780,857227)
		IF @@ROWCOUNT < 20000
		BEGIN
			RETURN
		END
	END

END