/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_Product3rd_Upd
    @File NVARCHAR(MAX),
    @LoginIP VARCHAR(20) = '',
    @UserID INT,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*          
Created: 20210513@Evan        
Task :  NAP -  Manage Product3rd     [Redmine: #153521]   
DB:   DBCUST-bodb_Licensee        

Revisions: 
    - 20210513@Evan: Create new SP [Redmine: #153521]
Param's Explanation:        
 - @Fie:          
  <ROOT><File ProductId = "1" ProductName = "Test" Description = "Test" ProductPrefix = "1" OfferSingle = "1" 
  ApplyDCS = "1" Enabled = "1" EndOfSupportDate = "20210513" OfferSite = "1" /></ROOT> 

*/
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@File, '') = ''
        RETURN;
    DECLARE @iDoc INT,
            @ValueError NVARCHAR(MAX) = N'',
            @LimitValue BIGINT;
    DECLARE @startRun DATETIME,
            @endRun DATETIME,
            @duration INT,
            @LogSPData NVARCHAR(MAX),
            @LogSPData_Old NVARCHAR(MAX),
            @RowTotal INT = 0,
            @CurrentRow INT = 0;
    CREATE TABLE #input
    (
        ID INT IDENTITY(1, 1),
        Productid INT,
        ProductName VARCHAR(50),
        Description VARCHAR(100),
        ProductPrefix VARCHAR(10),
        OfferSingle BIT,
        ApplyDCS BIT,
        Enabled BIT,
        EndOfSupportDate DATE,
        OfferSite TINYINT
    );
    CREATE TABLE #inputTmp
    (
        Productid NVARCHAR(MAX),
        ProductName NVARCHAR(MAX),
        Description NVARCHAR(MAX),
        ProductPrefix NVARCHAR(MAX),
        OfferSingle NVARCHAR(MAX),
        ApplyDCS NVARCHAR(MAX),
        Enabled NVARCHAR(MAX),
        EndOfSupportDate NVARCHAR(MAX),
        OfferSite NVARCHAR(MAX)
    );
    BEGIN TRY
        EXEC sp_xml_preparedocument @iDoc OUTPUT, @File;
        INSERT INTO #inputTmp
        (
            Productid,
            ProductName,
            Description,
            ProductPrefix,
            OfferSingle,
            ApplyDCS,
            Enabled,
            EndOfSupportDate,
            OfferSite
        )
        SELECT ProductId,
               ProductName,
               Description,
               ProductPrefix,
               OfferSingle,
               ApplyDCS,
               Enabled,
               EndOfSupportDate,
               OfferSite
        FROM
            OPENXML(@iDoc, '/ROOT/File', 1)
            WITH
            (
                ProductId NVARCHAR(MAX),
                ProductName NVARCHAR(MAX),
                Description NVARCHAR(MAX),
                ProductPrefix NVARCHAR(MAX),
                OfferSingle NVARCHAR(MAX),
                ApplyDCS NVARCHAR(MAX),
                Enabled NVARCHAR(MAX),
                EndOfSupportDate NVARCHAR(MAX),
                OfferSite NVARCHAR(MAX)
            );
        EXEC sp_xml_removedocument @iDoc;
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = ERROR_NUMBER(),
               @ErrMsg = ERROR_MESSAGE();
        RETURN;
    END CATCH;

    -- Check Simple Data       
    UPDATE #inputTmp
    SET ProductName = CASE
                          WHEN LEN(ProductName) = 0 THEN
                              NULL
                          ELSE
                              ProductName
                      END,
        Description = CASE
                          WHEN LEN(Description) = 0 THEN
                              NULL
                          ELSE
                              Description
                      END,
        ProductPrefix = CASE
                            WHEN LEN(ProductPrefix) = 0 THEN
                                NULL
                            ELSE
                                ProductPrefix
                        END,
        OfferSingle = CASE
                          WHEN LEN(OfferSingle) = 0 THEN
                              NULL
                          ELSE
                              OfferSingle
                      END,
        ApplyDCS = CASE
                       WHEN LEN(ApplyDCS) = 0 THEN
                           NULL
                       ELSE
                           ApplyDCS
                   END,
        Enabled = CASE
                      WHEN LEN(Enabled) = 0 THEN
                          NULL
                      ELSE
                          Enabled
                  END,
        EndOfSupportDate = CASE
                               WHEN LEN(EndOfSupportDate) = 0 THEN
                                   NULL
                               ELSE
                                   EndOfSupportDate END,
        OfferSite = CASE
            WHEN LEN(OfferSite) = 0 THEN
              NULL
            ELSE
              OfferSite
                           END
    WHERE LEN(ProductName) = 0
          OR LEN(Description) = 0
          OR LEN(ProductPrefix) = 0
          OR LEN(OfferSingle) = 0
          OR LEN(ApplyDCS) = 0
          OR LEN(Enabled) = 0
          OR LEN(EndOfSupportDate) = 0
          OR LEN(OfferSite) = 0;

    SELECT TOP (1)
           @ValueError = CASE
                             WHEN LEN(i.ProductName) > 50  THEN
                                 i.ProductName
                             WHEN LEN(i.Description) > 100 THEN
                                 i.Description
                             WHEN LEN(i.ProductPrefix) > 10 THEN
                                 i.ProductPrefix
                             ELSE
                                 NULL
                         END,
           @LimitValue = CASE
                             WHEN LEN (i.ProductName) > 50 THEN
                                 50
                             WHEN LEN(i.Description) > 100 THEN
                                 100
                             WHEN LEN(i.ProductPrefix) > 10 THEN
                                 50
                             ELSE
                                 1
                         END,
           @ErrCode = CASE
                          WHEN LEN(i.ProductName) > 50 THEN
                              1007
                          WHEN LEN(i.Description) > 100 THEN
                              1007
                          WHEN LEN(i.ProductPrefix) > 10 THEN
                              1007
                          WHEN i.ProductName IS NULL THEN
                            1008
                          ELSE
                              1009
                      END
    FROM #inputTmp i
    LEFT JOIN dbo.Product3rd p3 WITH (NOLOCK)  
            ON  p3.ProductName = i.ProductName
    WHERE LEN(i.ProductName) > 50
          OR LEN(i.Description) > 100
          OR LEN(i.ProductPrefix) > 10
          OR i.ProductName IS NULL
          OR (p3.ProductName IS NOT NULL AND p3.Productid <> i.Productid);

    IF @ErrCode <> 0
    BEGIN
        IF @ErrCode = 1007
            SELECT @ErrMsg
                = 'The value "' + ISNULL(@ValueError, '') + '" is exceeded max length '
                  + CONVERT(VARCHAR(8), @LimitValue) + '.';
        IF @ErrCode = 1008
            SELECT @ErrMsg = 'Invalid "ProductName" - The values must be not null';
        IF @ErrCode = 1009
               SELECT @ErrMsg  ='ProductName already exists.'; 
            RETURN;
    END;

    BEGIN TRY
        INSERT INTO #input
        (
            Productid,
            ProductName,
            Description,
            ProductPrefix,
            OfferSingle,
            ApplyDCS,
            Enabled,
            EndOfSupportDate,
            OfferSite
        )
        SELECT Productid,
               ProductName,
               Description,
               ProductPrefix,
               OfferSingle,
               ApplyDCS,
               Enabled,
               EndOfSupportDate,
               OfferSite
        FROM #inputTmp;
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = ERROR_NUMBER(),
               @ErrMsg = ERROR_MESSAGE();
        RETURN;
    END CATCH;
  SELECT  @RowTotal = COUNT(*) FROM #input
    WHILE @CurrentRow <> @RowTotal
    BEGIN
        SELECT @CurrentRow = @CurrentRow + 1,
               @startRun = GETDATE();
        SELECT @LogSPData
            = N'<R ProductId="' + COALESCE(CAST(Productid AS VARCHAR(10)), SPACE(1)) + N'" ' + N'ProductName="'
              + COALESCE(CAST(ProductName AS VARCHAR(50)), SPACE(1)) + N'" ' + N'Description="'
              + COALESCE(CAST(Description AS VARCHAR(100)), SPACE(1)) + N'" ' + N'ProductPrefix="'
              + COALESCE(CAST(ProductPrefix AS VARCHAR(10)), SPACE(1)) + N'" ' + N'OfferSingle="'
              + COALESCE(CAST(OfferSingle AS VARCHAR(1)), SPACE(1)) + N'" ' + N'ApplyDCS="'
              + COALESCE(CAST(ApplyDCS AS VARCHAR(1)), SPACE(1)) + N'" ' + N'Enabled="'
              + COALESCE(CAST(Enabled AS VARCHAR(1)), SPACE(1)) + N'" ' + N'EndOfSupportDate="'
              + COALESCE(CAST(EndOfSupportDate AS VARCHAR(50)), SPACE(1)) + N'" ' + N'OfferSite="'
              + COALESCE(CAST(OfferSite AS VARCHAR(1)), SPACE(1)) + N'" ' + N'LoginIP="'
              + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + N'" />'
        FROM #input
        WHERE ID = @CurrentRow;
    
        BEGIN TRY
            UPDATE p3
            SET p3.ProductName = i.ProductName,
                p3.Description = i.Description,
                p3.ProductPrefix = i.ProductPrefix,
                p3.OfferSingle = i.OfferSingle,
                p3.ApplyDCS = i.ApplyDCS,
                p3.Enabled = i.Enabled,
                p3.EndOfSupportDate = i.EndOfSupportDate,
                p3.OfferSite = i.OfferSite
            FROM dbo.Product3rd p3 WITH (ROWLOCK)
                INNER JOIN #input i
                    ON i.Productid = p3.Productid
            WHERE i.ID = @CurrentRow;
        END TRY
        BEGIN CATCH
            SELECT @ErrCode = ERROR_NUMBER(),
                   @ErrMsg = ERROR_MESSAGE();
            RETURN;
        END CATCH;
        SELECT @LogSPData
            = N'<R ProductId="' + COALESCE(CAST(Productid AS VARCHAR(10)), SPACE(1)) + N'" ' + N'ProductName="'
              + COALESCE(CAST(ProductName AS VARCHAR(50)), SPACE(1)) + N'" ' + N'Description="'
              + COALESCE(CAST(Description AS VARCHAR(100)), SPACE(1)) + N'" ' + N'ProductPrefix="'
              + COALESCE(CAST(ProductPrefix AS VARCHAR(10)), SPACE(1)) + N'" ' + N'OfferSingle="'
              + COALESCE(CAST(OfferSingle AS VARCHAR(1)), SPACE(1)) + N'" ' + N'ApplyDCS="'
              + COALESCE(CAST(ApplyDCS AS VARCHAR(1)), SPACE(1)) + N'" ' + N'Enabled="'
              + COALESCE(CAST(Enabled AS VARCHAR(1)), SPACE(1)) + N'" ' + N'EndOfSupportDate="'
              + COALESCE(CAST(EndOfSupportDate AS VARCHAR(50)), SPACE(1))  + N'" ' + N'OfferSite="'
              + COALESCE(CAST(OfferSite AS VARCHAR(1)), SPACE(1)) + N'" ' + N'LoginIP="'
              + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + N'" />'
        FROM #input
        WHERE ID = @CurrentRow;
        SET @endRun = GETDATE();
        SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun);

        EXEC Lrf_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID,
                                                    @ActionID = 95048,
                                                    @TrackingValue = @LogSPData,
                                                    @TrackingValue2 = @LogSPData_Old,
                                                    @Duration = @duration;
    END;

    DROP TABLE #input;
    DROP TABLE #inputTmp;
END;
