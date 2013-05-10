ALTER PROCEDURE [dbo].[Acc_ExecRep_09] 
	@licensee NVARCHAR(50), 
    @mode    INT = 1
AS
BEGIN

    -- 1 Agency commission
    -- 2 Member commission

    SET NOCOUNT ON

	IF (SELECT COUNT('') FROM sys.objects WITH(NOLOCK) WHERE (name = 'custsetting3rd' AND type = 'u')
													OR (name = 'f_Depsuper_1' AND type = 'TF')) <> 2
	BEGIN
		PRINT 'custsetting3rd or f_Depsuper_1 objects does not exist.'
		RETURN
	END
	
    IF @mode = 1
    BEGIN
        ---- update sdiscount
        UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
        SET sdiscount = 0.03
        FROM custsetting3rd cs3 
            INNER JOIN dbo.f_Depsuper_1(@licensee) t ON cs3.custid = t.custid
        WHERE ( cs3.sporttype BETWEEN 151 AND 153 AND cs3.bettype BETWEEN 51 AND 52 )

        ---- update adiscount
        UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
        SET sdiscount = 0.03,
            adiscount = 0.03
        FROM custsetting3rd cs3
            INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
            INNER JOIN dbo.f_Depsuper_1(@licensee) t ON c.srecommend = t.custid AND c.roleid = 3
        WHERE ( cs3.sporttype BETWEEN 151 AND 153 AND cs3.bettype BETWEEN 51 AND 52 )


        ---- update discount
        UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
        SET sdiscount = 0.03,
            adiscount = 0.03,
            discount  = 0.03
        FROM custsetting3rd cs3
            INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
            INNER JOIN dbo.f_Depsuper_1(@licensee) t ON c.srecommend = t.custid AND c.roleid = 2
        WHERE ( cs3.sporttype BETWEEN 151 AND 153 AND cs3.bettype BETWEEN 51 AND 52 )
       
        WAITFOR DELAY '00:00:02'
    END
    IF @mode = 2
    BEGIN
       
        DECLARE @MinCustID INT,
                @MaxCustID INT,
                @count INT,
                @step INT

        SELECT  @MinCustID = MIN(c.custid),
                @MaxCustID = MAX(c.custid),
                @count = 0,
                @step = 10000

        FROM dbo.f_Depsuper_1(@licensee) t 
			INNER JOIN custinfo c WITH(NOLOCK) ON t.custid = c.srecommend
		WHERE c.roleid = 1

        WHILE 1 + @MinCustID + @step*@count < @MaxCustID
        BEGIN
            ---- update player discount
            UPDATE cs3 WITH(ROWLOCK,UPDLOCK)
            SET sdiscount = 0.03,
                adiscount = 0.03,
                discount  = 0.03
            FROM custsetting3rd cs3
                INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
                INNER JOIN dbo.f_Depsuper_1(@licensee) t ON c.srecommend = t.custid AND c.roleid = 1
            WHERE (
					(cs3.sporttype between 151 AND 153 AND cs3.bettype BETWEEN 51 AND 52)
				  )
                    AND cs3.custid BETWEEN 1 + @MinCustID + @step*@COUNT AND @MinCustID + @step*(@COUNT + 1)

            SELECT @count = @count + 1

            WAITFOR DELAY '00:00:01'
        END
    END
END



/*

DECLARE @licensee NVARCHAR(50), @i INT
DECLARE @tbl TABLE (ID INT, licensee NVARCHAR(50))

INSERT INTO @tbl
		  SELECT 1, '12Bet'
UNION ALL SELECT 2, 'asiabet88'
UNION ALL SELECT 3, 'mansion88'
UNION ALL SELECT 4, 'ALog'
UNION ALL SELECT 5, 'TLC'
UNION ALL SELECT 6, 'DELA'
UNION ALL SELECT 7, 'Spondemo'
UNION ALL SELECT 8, 'Zzun88'
UNION ALL SELECT 9, 'SunCity'
UNION ALL SELECT 10,'MayFair'
UNION ALL SELECT 11,'Bezbet'

SELECT @i = 1

WHILE @i <= 11
BEGIN

	SELECT @licensee = licensee
	FROM @tbl
	WHERE ID = @i

    EXEC dbo.Acc_ExecRep_09  @licensee = @licensee, @Mode = 2
     
    SELECT @i = @i + 1
 
    WAITFOR DELAY '000:00:01'
END


*/