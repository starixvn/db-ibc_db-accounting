

ALTER PROCEDURE [dbo].[Acc_ExecRep_09] 	
    @mode		INT = 1	
AS
BEGIN

    -- 1 Agency PT
    -- 2 Member PT
/*

*/
    SET NOCOUNT ON

	IF (SELECT COUNT('') FROM sys.objects WITH(NOLOCK) WHERE name IN ('custsetting3rd','custinfo') AND type = 'u') <> 2
	BEGIN
		PRINT 'custsetting3rd or custinfo objects does not exist.'
		RETURN
	END
	
	DECLARE @tmp TABLE (custid INT)
	
	INSERT INTO @tmp
				  SELECT 1015419
		UNION ALL SELECT 1015427
		UNION ALL SELECT 791081
		UNION ALL SELECT 836212
		UNION ALL SELECT 1813575
		UNION ALL SELECT 836218
		UNION ALL SELECT 836226
		UNION ALL SELECT 1752415
		UNION ALL SELECT 836203
		UNION ALL SELECT 791080
		UNION ALL SELECT 916498
		UNION ALL SELECT 179457
		UNION ALL SELECT 3167631

    IF @mode = 1
    BEGIN
        ---- update PT on super
        UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
        SET spositiontaking = 0.5,
			mpositiontaking = 0.5,
			apositiontaking = 0.5,
			sdiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			adiscount = 0,
			discount = 0
        FROM custsetting3rd cs3 
            INNER JOIN @tmp t ON cs3.custid = t.custid
        WHERE cs3.sporttype BETWEEN 152 AND 153 AND cs3.bettype IN (41,42,51,52)

        ---- update PT on master
        UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
        SET mpositiontaking = 0.5,
			sdiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			adiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			discount = 0
        FROM custsetting3rd cs3
            INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
            INNER JOIN @tmp t ON c.srecommend = t.custid AND c.roleid = 3
        WHERE cs3.sporttype BETWEEN 152 AND 153 AND cs3.bettype IN (41,42,51,52)
			AND c.mrecommend NOT IN (927780,857227)

        ---- update PT on agent
        UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
        SET apositiontaking = 0.5,
			sdiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			adiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
			discount  = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
        FROM custsetting3rd cs3
            INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
            INNER JOIN @tmp t ON c.srecommend = t.custid AND c.roleid = 2
        WHERE cs3.sporttype BETWEEN 152 AND 153 AND cs3.bettype IN (41,42,51,52)
			AND c.mrecommend NOT IN (927780,857227)
        RETURN

    END
    IF @mode = 2
    BEGIN
        
        ---- update PT on member
		WHILE 1 = 1 
		BEGIN
			UPDATE TOP(10000) cs3 WITH(ROWLOCK,UPDLOCK)
			SET apositiontaking = 0.5,
				sdiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
				adiscount = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END,
				discount  = CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
			FROM custsetting3rd cs3
				INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
				INNER JOIN @tmp t ON c.srecommend = t.custid AND c.roleid = 1
			WHERE cs3.sporttype BETWEEN 152 AND 153 AND cs3.bettype IN (41,42,51,52)
				  AND ( apositiontaking <> 0.5
						OR 
						sdiscount <> CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
						OR 
						adiscount <> CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
						OR 
						discount <> CASE WHEN bettype IN (51,52) THEN 0.03 ELSE 0.04 END
					)
				AND c.mrecommend NOT IN (927780,857227)
			IF @@ROWCOUNT < 10000
			BEGIN
				RETURN
			END
			
			WAITFOR DELAY '00:00:01'   
		END
    END
	IF @mode = 3
	BEGIN
		 ---- update PT on master
        UPDATE co3 WITH(ROWLOCK,UPDLOCK)
        SET minpositiontaking = 0,
			maxpositiontaking = 0.5
--			minlivepositiontaking = 0,
--			maxlivepositiontaking = 0
        FROM custoverride3rd co3
            INNER JOIN custinfo c WITH(NOLOCK) ON co3.custid = c.custid
            INNER JOIN @tmp t ON c.srecommend = t.custid
        WHERE co3.sporttype BETWEEN 152 AND 153 AND co3.bettype IN (41,42,51,52)
			AND c.mrecommend NOT IN (927780,857227)
	END
END

/*
-- @Mode
-- 1 Agency PT
-- 2 Member PT

EXEC dbo.Acc_ExecRep_09  @Mode = 1

*/
