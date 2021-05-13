/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_Product3rd_Ins      
    @File NVARCHAR(MAX),      
    @LoginIP VARCHAR(20) = '',      
    @UserID INT,      
	@ErrCode INT = 0 OUTPUT,      
    @ErrMsg NVARCHAR(4000) = '' OUTPUT      
AS      
/*          
Created: 20210513@Evan        
Task :  NAP -  Manage VendorGlobal Setting and Product3rd     [Redmine: #153521]   
DB:   DBCUST-CustDB        
Original:          
Param's Explanation:        
 - @Fie:          
  <ROOT><File ProductId = "0" ProductName = "ProductName" Description = "Test" ProductPrefix = "Test" OfferSingle = "1" 
  ApplyDCS = "1" Enabled = "" EndOfSupportDate = "20210513" />      
</ROOT>  

*/        
BEGIN      
 SET NOCOUNT ON;      
 IF ISNULL(@File, '') = ''      
        RETURN;      
DECLARE @iDoc INT,    
        @Product3rdError NVARCHAR(MAX) = N'',    
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
    Productid int,
	ProductName varchar(50),
	Description varchar(100),
	ProductPrefix varchar(10),
	OfferSingle bit,
	ApplyDCS bit,
	Enabled bit,
	EndOfSupportDate date
);        
CREATE TABLE #inputTmp      
(      
    ID INT IDENTITY(1, 1),      
    Productid NVARCHAR(MAX),
	ProductName NVARCHAR(MAX),
	Description NVARCHAR(MAX),
	ProductPrefix NVARCHAR(MAX),
	OfferSingle NVARCHAR(MAX),
	ApplyDCS NVARCHAR(MAX),
	Enabled NVARCHAR(MAX),
	EndOfSupportDate NVARCHAR(MAX)   
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
			EndOfSupportDate
		)    
		SELECT Productid,
			ProductName,
			Description,
			ProductPrefix,
			OfferSingle,
			ApplyDCS,
			Enabled,
			EndOfSupportDate  
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
			EndOfSupportDate NVARCHAR(MAX)       
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
	WHERE   LEN(ProductId) = 0
	AND LEN(ProductName) = 0
	AND LEN(Description) = 0
	AND LEN(ProductPrefix) = 0
	AND LEN(OfferSingle) = 0
	AND LEN(ApplyDCS) = 0
	AND LEN(Enabled) = 0
	AND LEN(EndOfSupportDate) = 0 ;

	-- Check Simple Data       
	UPDATE #inputTmp        
	SET     ProductId = CASE WHEN LEN(ProductId) = 0 THEN NULL ELSE ProductId END,
			ProductName = CASE WHEN LEN(ProductName) = 0 THEN NULL ELSE ProductName END,
			Description = CASE WHEN LEN(Description) = 0 THEN NULL ELSE Description END,
			ProductPrefix = CASE WHEN LEN(ProductPrefix) = 0 THEN NULL ELSE ProductPrefix END,
			OfferSingle = CASE WHEN LEN(OfferSingle) = 0 THEN NULL ELSE OfferSingle END,
			ApplyDCS = CASE WHEN LEN(ApplyDCS) = 0 THEN NULL ELSE ApplyDCS END,
			Enabled = CASE WHEN LEN(Enabled) = 0 THEN NULL ELSE Enabled END,
			EndOfSupportDate = CASE WHEN LEN(EndOfSupportDate) = 0 THEN NULL ELSE EndOfSupportDate END    
	WHERE LEN(ProductId) = 0
		OR LEN(ProductName) = 0
		OR LEN(Description) = 0
		OR LEN(ProductPrefix) = 0
		OR LEN(OfferSingle) = 0
		OR LEN(ApplyDCS) = 0
		OR LEN(Enabled) = 0
		OR LEN(EndOfSupportDate) = 0 ;   

		SELECT TOP(1)  @Product3rdError = CONVERT(VARCHAR(5),ID),      
						@ValueError = CASE WHEN LEN(ProductName) > 50 THEN ProductName 
						WHEN LEN(Description) > 100 THEN Description 
						WHEN LEN(ProductPrefix) > 10 THEN ProductPrefix 
						ELSE NULL END,       
					@LimitValue = CASE      
										WHEN LEN(ProductName) > 50 THEN 50      
										WHEN LEN(Description) > 100 THEN 100      
										WHEN LEN(ProductPrefix) > 10 THEN 50      
									ELSE 1 END,      
					@ErrCode = CASE 
									WHEN LEN(ProductName) > 50 THEN 1007      
									WHEN LEN(Description) > 100 THEN 1007      
									WHEN LEN(ProductPrefix) > 10 THEN 1007      
								ELSE 1008 END,      
					@ColumnName = CASE WHEN  Productid IS NULL OR ISNUMERIC(Productid) <> 1  THEN 'Productid'      
					WHEN  ProductName IS NULL  THEN 'ProductName'       
					WHEN  OfferSingle IS NULL OR OfferSingle NOT IN ('0','1') OR ISNUMERIC(OfferSingle) <> 1 THEN 'OfferSingle'       
					WHEN  ApplyDCS IS NULL OR ApplyDCS NOT IN ('0','1') OR ISNUMERIC(ApplyDCS) <> 1 THEN 'ApplyDCS'       
					WHEN  ISNULL(Enabled,0) NOT IN (0,1) OR ISNUMERIC(ISNULL(Enabled,0)) <> 1 THEN 'Enabled'       
				ELSE NULL END        
			FROM #inputTmp  WITH(NOLOCK)       
			WHERE  LEN(ProductName) > 50  OR LEN(Description) > 100  OR LEN(ProductPrefix) > 10
			OR Productid IS NULL  OR ProductName IS NULL OR ApplyDCS IS NULL OR OfferSingle IS NULL 
			OR ApplyDCS NOT IN ('0','1') OR OfferSingle NOT IN ('0','1')
			OR ISNUMERIC(OfferSingle) <> 1 OR ISNUMERIC(Productid) <> 1 OR ISNUMERIC(ApplyDCS) <> 1 OR ISNUMERIC(ISNULL(Enabled,0)) <> 1
			OR ISNULL(Enabled,0) NOT IN (0,1)
			ORDER BY ID;  
	IF @ErrCode <> 0      
	BEGIN      
		IF @ErrCode = 1007      
		SELECT @ErrMsg      
		= 'Row "' + ISNULL(@Product3rdError, '') + '" - The value "' + ISNULL(@ValueError, '')      
		+ '" is exceeded max length ' + CONVERT(VARCHAR(8), @LimitValue) + '.';      
		IF @ErrCode = 1008      
		SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @Product3rdError +
		CASE  
		WHEN @ColumnName = 'ProductName' THEN '"- The values must be not null' 
		WHEN @ColumnName = 'OfferSingle' THEN '"- The values must be IN (0,1)' 
		WHEN @ColumnName = 'ApplyDCS' THEN '"- The values must be IN (0,1)' 
		WHEN @ColumnName = 'Enabled' THEN '"- The values must be IN (0,1)' 
		ELSE '' END  + '. Please check them again.'     
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
			EndOfSupportDate
		)
		SELECT Productid,
			ProductName,
			Description,
			ProductPrefix,
			OfferSingle,
			ApplyDCS,
			Enabled,
			EndOfSupportDate    
		FROM #inputTmp WITH(NOLOCK) ;      
	END TRY      
	BEGIN CATCH      
		SELECT @ErrCode = ERROR_NUMBER(),      
		@ErrMsg = ERROR_MESSAGE();      
		RETURN;      
	END CATCH;      
--Check Productid 
	SELECT TOP (1)
		   @Product3rdError = CONVERT(VARCHAR(5), i.ID),
		   @ErrCode = 1009,
		   @ValueError = CAST(p3.Productid AS NVARCHAR(MAX)),
		   @ColumnName = N'Productid'
	FROM #input i WITH (NOLOCK)
		LEFT JOIN DBCUST.bodb_Licensee.dbo.Product3rd p3 WITH (NOLOCK)
			ON p3.Productid = i.Productid
	WHERE p3.Productid IS NOT NULL
	ORDER BY i.ID;   
	IF @ErrCode  <> 0      
	BEGIN      
		SELECT @ErrMsg = 'Row "' + ISNULL(@Product3rdError,'') + '" - ' + @ColumnName + ' = "' + ISNULL(@ValueError,'') + '" already exist.'      
		RETURN      
	END      
       
	SELECT @Product3rdError = STUFF((      
	SELECT ',' + CAST(KQ.ID AS NVARCHAR(5)) + ''      
	FROM (      
	SELECT DISTINCT I.ID      
	FROM #input i WITH(NOLOCK)      
	LEFT JOIN #input i2 WITH(NOLOCK) ON i.Productid = i2.Productid   
	WHERE i2.Productid IS NOT NULL AND i.ID <> i2.ID      
	) KQ      
	ORDER BY KQ.ID      
			FOR XML PATH('')      
			), 1, 1, '')      
               
	IF ISNULL(@Product3rdError,'') <> ''      
	SET  @ErrCode     = 1010     
	SET @Product3rdError =  REPLACE(@Product3rdError, ',', '>,<');      
       
	IF @ErrCode <> 0      
		BEGIN       
		  SELECT @ErrMsg = 'Row <' + @Product3rdError +'> : ProductId of rows cannot be same.'       
		  RETURN      
		END        
	SELECT @RowTotal = COUNT(*)      
    FROM #input;      
    
    WHILE @CurrentRow <> @RowTotal      
    BEGIN      
        SELECT @CurrentRow = @CurrentRow + 1,      
               @startRun = GETDATE();      
        BEGIN TRY       
            --INSERT INTO  DBCUST.bodb_Licensee.dbo.Product3rd
            --(
            --    Productid,
            --    ProductName,
            --    Description,
            --    ProductPrefix,
            --    OfferSingle,
            --    ApplyDCS,
            --    Enabled,
            --    EndOfSupportDate
            --)
            SELECT  Productid,
                ProductName,
                Description,
                ProductPrefix,
                OfferSingle,
                ApplyDCS,
                Enabled,
                EndOfSupportDate      
            FROM #input      
            WHERE ID = @CurrentRow;      
        END TRY      
        BEGIN CATCH      
            SELECT @ErrCode = ERROR_NUMBER(),      
                   @ErrMsg = ERROR_MESSAGE();      
            RETURN;      
        END CATCH;      
        SELECT @LogSPData = '<R ProductId="'+ COALESCE(CAST(ProductId AS VARCHAR(10)), SPACE(1)) + '" ' +      
						'ProductName="' + COALESCE(CAST(ProductName  AS VARCHAR(50)), SPACE(1)) + '" ' +
						'Description="' + COALESCE(CAST(Description  AS VARCHAR(100)), SPACE(1)) + '" ' +
						'ProductPrefix="' + COALESCE(CAST(ProductPrefix  AS VARCHAR(10)), SPACE(1)) + '" ' +
						'OfferSingle="' + COALESCE(CAST(OfferSingle  AS VARCHAR(1)), SPACE(1)) + '" ' +
						'ApplyDCS="' + COALESCE(CAST(ApplyDCS  AS VARCHAR(1)), SPACE(1)) + '" ' +
						'Enabled="' + COALESCE(CAST(Enabled  AS VARCHAR(1)), SPACE(1)) + '" ' +
						'EndOfSupportDate="' + COALESCE(CAST(EndOfSupportDate  AS VARCHAR(50)), SPACE(1)) + '" ' +  
					   'IP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'      
        FROM #input      
        WHERE ID = @CurrentRow;      
        SET @endRun = GETDATE();      
        SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun);      
             
   --EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID,    
   --                                         @ActionID = 6062,    
   --                                         @TrackingValue = @LogSPData,    
   --                                         @Duration = @duration;    
    END;      
 DROP TABLE #input, #inputTmp;      
END   