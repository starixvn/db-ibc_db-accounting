ALTER PROCEDURE [dbo].[Acc_ExecRep_09] 	
AS
BEGIN

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

        ---- update PT on super
        UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
        SET spositiontaking = 0.5,
			mpositiontaking = 0.5,
			apositiontaking = 0.5
        FROM custsetting3rd cs3 
            INNER JOIN @tmp t ON cs3.custid = t.custid
        WHERE cs3.sporttype = 151 AND cs3.bettype IN (31,32,41,42,51,52)
  
END


