/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Ins
    @File NVARCHAR(MAX),
    @LoginIP VARCHAR(20) = '',
    @UserID INT,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*              
Created: 20210512@Evan            
Task :  NAP -  Manage VendorGlobal Setting    [Redmine: #153521]       
DB:   DBCUST-CustDB            

Revisions:     
    - 20210512@Evan: Create new SP [Redmine: #153521]    
Param's Explanation:            
 - @Fie:              
  <ROOT><File VendorId = "40" VendorName = "3rdCashWLShareRate" NumberValue = "1" SportType = "200" BetType = "200" /></ROOT>          
*/
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@File, '') = ''
        RETURN;
    DECLARE @iDoc INT,
            @VendorError NVARCHAR(MAX) = N'',
            @ValueError NVARCHAR(MAX) = N'',
            @LimitValue BIGINT,
            @ColumnName NVARCHAR(200);
    DECLARE @startRun DATETIME,
            @endRun DATETIME,
            @duration INT,
            @LogSPData NVARCHAR(MAX),
            @RowTotal INT = 0,
            @CurrentRow INT = 0;
    CREATE TABLE #input
    (
        ID INT IDENTITY(1, 1),
        VendorId INT,
        VName VARCHAR(50),
        NumberValue DECIMAL(19, 8),
        sporttype SMALLINT,
        bettype SMALLINT
    );
    CREATE TABLE #inputTmp
    (
        ID INT IDENTITY(1, 1),
        VendorId NVARCHAR(MAX),
        VendorName NVARCHAR(MAX),
        NumberValue NVARCHAR(MAX),
        SportType NVARCHAR(MAX),
        BetType NVARCHAR(MAX)
    );
    BEGIN TRY
        EXEC sp_xml_preparedocument @iDoc OUTPUT, @File;
        INSERT INTO #inputTmp
        (
            VendorId,
            VendorName,
            NumberValue,
            SportType,
            BetType
        )
        SELECT VendorId,
               VendorName,
               NumberValue,
               SportType,
               BetType
        FROM
            OPENXML(@iDoc, '/ROOT/File', 1)
            WITH
            (
                VendorId NVARCHAR(MAX),
                VendorName NVARCHAR(MAX),
                NumberValue NVARCHAR(MAX),
                SportType NVARCHAR(MAX),
                BetType NVARCHAR(MAX)
            );
        EXEC sp_xml_removedocument @iDoc;
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = ERROR_NUMBER(),
               @ErrMsg = ERROR_MESSAGE();
        RETURN;
    END CATCH;

    -- remove empty row          
    DELETE #inputTmp
    WHERE LEN(VendorId) = 0
          AND LEN(VendorName) = 0
          AND LEN(NumberValue) = 0
          AND LEN(SportType) = 0
          AND LEN(BetType) = 0;

    -- Check Simple Data           
    UPDATE #inputTmp
    SET VendorId = CASE
                       WHEN LEN(VendorId) = 0 THEN
                           NULL
                       ELSE
                           VendorId
                   END,
        VendorName = CASE
                         WHEN LEN(VendorName) = 0 THEN
                             NULL
                         ELSE
                             VendorName
                     END,
        NumberValue = CASE
                          WHEN LEN(NumberValue) = 0 THEN
                              NULL
                          ELSE
                              NumberValue
                      END,
        SportType = CASE
                        WHEN LEN(SportType) = 0 THEN
                            NULL
                        ELSE
                            SportType
                    END,
        BetType = CASE
                      WHEN LEN(BetType) = 0 THEN
                          NULL
                      ELSE
                          BetType
                  END
    WHERE LEN(VendorId) = 0
          OR LEN(VendorName) = 0
          OR LEN(NumberValue) = 0
          OR LEN(SportType) = 0
          OR LEN(BetType) = 0;

    SELECT TOP (1)
           @VendorError = CONVERT(VARCHAR(5), ID),
           @ValueError = CASE
                             WHEN LEN(VendorName) > 50 THEN
                                 VendorName
                             ELSE
                                 NULL
                         END,
           @LimitValue = CASE
                             WHEN LEN(VendorName) > 50 THEN
                                 50
                             ELSE
                                 1
                         END,
           @ErrCode = CASE
                          WHEN LEN(VendorName) > 50 THEN
                              1007
                          ELSE
                              1008
                      END,
           @ColumnName = CASE
                             WHEN ISNUMERIC(NumberValue) <> 1 THEN
                                 'NumberValue'
                             WHEN ISNUMERIC(ISNULL(SportType, 0)) <> 1 THEN
                                 'SportType'
                             WHEN ISNUMERIC(ISNULL(BetType, 0)) <> 1 THEN
                                 'BetType'
                             WHEN VendorId IS NULL
                                  OR ISNUMERIC(VendorId) <> 1 THEN
                                 'VendorId'
                             WHEN VendorName IS NULL THEN
                                 'VendorName'
                             ELSE
                                 NULL
                         END
    FROM #inputTmp
    WHERE LEN(VendorName) > 50
          OR VendorName IS NULL
          OR VendorId IS NULL
          OR ISNUMERIC(VendorId) <> 1
          OR ISNUMERIC(ISNULL(SportType, 0)) <> 1
          OR ISNUMERIC(ISNULL(BetType, 0)) <> 1
          OR ISNUMERIC(NumberValue) <> 1;

    IF @ErrCode <> 0
    BEGIN
        IF @ErrCode = 1007
            SELECT @ErrMsg
                = 'Row "' + ISNULL(@VendorError, '') + '" - The value "' + ISNULL(@ValueError, '')
                  + '" is exceeded max length ' + CONVERT(VARCHAR(8), @LimitValue) + '.';
        IF @ErrCode = 1008
            SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @VendorError + '".Please check them again.';
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO #input
        (
            VendorId,
            VName,
            NumberValue,
            sporttype,
            bettype
        )
        SELECT VendorId,
               VendorName,
               NumberValue,
               SportType,
               BetType
        FROM #inputTmp;
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = ERROR_NUMBER(),
               @ErrMsg = ERROR_MESSAGE();
        RETURN;
    END CATCH;

    --Check VendorId ,VendorName, SportType, BetType           
    SELECT TOP (1)
           @VendorError = CONVERT(VARCHAR(5), i.ID),
           @ErrCode = CASE
                          WHEN vgs.VendorId IS NOT NULL THEN
                              1010
                          ELSE
                              1009
                      END,
           @ValueError = CASE
                             WHEN vgs.VendorId IS NOT NULL THEN
                                 CAST(vgs.VendorId AS NVARCHAR(MAX)) + ' - ' + vgs.VName
                             WHEN bt.typeid IS NULL
                                  AND i.bettype IS NOT NULL THEN
                                 CAST(i.bettype AS NVARCHAR(MAX))
                             ELSE
                                 CAST(i.sporttype AS NVARCHAR(MAX))
                         END,
           @ColumnName = CASE
                             WHEN vgs.VendorId IS NOT NULL THEN
                                 'VendorId and VendorName'
                             WHEN bt.typeid IS NULL
                                  AND i.bettype IS NOT NULL THEN
                                 'Bettype'
                             ELSE
                                 'Sporttype'
                         END
    FROM #input i
        LEFT JOIN dbo.VendorGlobalSetting vgs WITH (NOLOCK)
            ON vgs.VendorId = i.VendorId
               AND vgs.VName = i.VName
        LEFT JOIN DBPRO.bodb02.dbo.bettype bt WITH (NOLOCK)
            ON bt.typeid = i.bettype
        LEFT JOIN DBPRO.bodb02.dbo.Sports s WITH (NOLOCK)
            ON s.SportType = i.sporttype
               AND i.sporttype IS NOT NULL
    WHERE vgs.VendorId IS NOT NULL
          OR
          (
              bt.typeid IS NULL
              AND i.bettype IS NOT NULL
          )
          OR
          (
              s.SportType IS NULL
              AND i.sporttype IS NOT NULL
          );

    IF @ErrCode <> 0
    BEGIN
        IF @ErrCode = 1009
            SELECT @ErrMsg
                = 'Row "' + ISNULL(@VendorError, '') + '" - ' + @ColumnName + ' = "' + ISNULL(@ValueError, '')
                  + '" does not exist.';
        IF @ErrCode = 1010
            SELECT @ErrMsg
                = 'Row "' + ISNULL(@VendorError, '') + '" - ' + @ColumnName + ' = "' + ISNULL(@ValueError, '')
                  + '" already exist.';
        RETURN;
    END;

    SELECT @VendorError = STUFF(
                          (
                              SELECT ',' + CAST(KQ.ID AS NVARCHAR(5)) + ''
                              FROM
                              (
                                  SELECT DISTINCT
                                         i.ID
                                  FROM #input i
                                      LEFT JOIN #input i2
                                          ON i.VendorId = i2.VendorId
                                             AND i.VName = i2.VName
                                  WHERE i2.VendorId IS NOT NULL
                                        AND i.ID <> i2.ID
                              ) KQ
                              ORDER BY KQ.ID
                              FOR XML PATH('')
                          ),
                          1,
                          1,
                          ''
                               );

    IF ISNULL(@VendorError, '') <> ''
        SET @ErrCode = 1011;
    SET @VendorError = REPLACE(@VendorError, ',', '>,<');

    IF @ErrCode <> 0
    BEGIN
        SELECT @ErrMsg = 'Row <' + @VendorError + '> : VendorId - VendorName of rows cannot be same.';
        RETURN;
    END;

    SELECT @RowTotal = COUNT(*)
    FROM #input;

    WHILE @CurrentRow <> @RowTotal
    BEGIN
        SELECT @CurrentRow = @CurrentRow + 1,
               @startRun = GETDATE();
        BEGIN TRY
            INSERT INTO VendorGlobalSetting
            (
                VendorId,
                VName,
                NumberValue,
                sporttype,
                bettype
            )
            SELECT VendorId,
                   VName,
                   NumberValue,
                   sporttype,
                   bettype
            FROM #input
            WHERE ID = @CurrentRow;
        END TRY
        BEGIN CATCH
            SELECT @ErrCode = ERROR_NUMBER(),
                   @ErrMsg = ERROR_MESSAGE();
            RETURN;
        END CATCH;

        SELECT @LogSPData
            = N'<R VendorId="' + COALESCE(CAST(VendorId AS VARCHAR(10)), SPACE(1)) + N'" ' + N'VName="'
              + COALESCE(CAST(VName AS VARCHAR(50)), SPACE(1)) + N'" ' + N'NumberValue="'
              + COALESCE(CAST(NumberValue AS VARCHAR(50)), SPACE(1)) + N'" ' + N'SportType="'
              + COALESCE(CAST(sporttype AS VARCHAR(10)), SPACE(1)) + N'" ' + N'BetType="'
              + COALESCE(CAST(bettype AS VARCHAR(10)), SPACE(1)) + N'" ' + N'LoginIP="'
              + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + N'" />'
        FROM #input
        WHERE ID = @CurrentRow;

        SET @endRun = GETDATE();
        SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun);

        EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID,
                                                @ActionID = 95044,
                                                @TrackingValue = @LogSPData,
                                                @Duration = @duration;

    END;
    DROP TABLE #input;
    DROP TABLE #inputTmp;
END;