 

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
AS
BEGIN

    SET NOCOUNT ON

	IF (SELECT COUNT('') FROM sys.objects WITH(NOLOCK) WHERE name IN ('custoverride3rd','custinfo') AND type = 'u') <> 2
	BEGIN
		PRINT 'custoverride3rd or custinfo objects does not exist.'
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

        ---- update PT on super
        UPDATE co3 WITH(ROWLOCK,UPDLOCK)
        SET minpositiontaking = 0.00,
			maxpositiontaking = 0.5,
			minlivepositiontaking = 0.00,
			maxlivepositiontaking = 0.5
        FROM custoverride3rd co3 
            INNER JOIN @tmp t ON co3.custid = t.custid
        WHERE co3.sporttype = 151 AND co3.bettype IN (31,32,41,42,51,52)

        ---- update PT on master
        UPDATE co3 WITH(ROWLOCK,UPDLOCK)
        SET minpositiontaking = 0.00,
			maxpositiontaking = 0.5,
			minlivepositiontaking = 0.00,
			maxlivepositiontaking = 0.5
        FROM custoverride3rd co3
            INNER JOIN custinfo c WITH(NOLOCK) ON co3.custid = c.custid
            INNER JOIN @tmp t ON c.srecommend = t.custid AND c.roleid = 3
        WHERE co3.sporttype = 151 AND co3.bettype IN (31,32,41,42,51,52)

        ---- update PT on agent
        UPDATE co3 WITH(ROWLOCK,UPDLOCK)
        SET minpositiontaking = 0.00,
			maxpositiontaking = 0.5,
			minlivepositiontaking = 0.00,
			maxlivepositiontaking = 0.5
        FROM custoverride3rd co3
            INNER JOIN custinfo c WITH(NOLOCK) ON co3.custid = c.custid
            INNER JOIN @tmp t ON c.srecommend = t.custid AND c.roleid = 2
        WHERE co3.sporttype = 151 AND co3.bettype IN (31,32,41,42,51,52)

END

