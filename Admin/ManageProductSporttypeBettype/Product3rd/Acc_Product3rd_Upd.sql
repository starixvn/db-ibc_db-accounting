/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_Product3rd_Upd      
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
  Revisions: 
    - 20200413@Evan: Create new SP [Redmine: #153521]
Param's Explanation:        
 - @Fie:          
  <ROOT><File ProductId = "Test" ProductName = "Test" Description = "Test" ProductPrefix = "Test" OfferSingle = "Test" 
  ApplyDCS = "Test" Enabled = "Test" EndOfSupportDate = "Test" />      
</ROOT>  

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
	
	-- Check Simple Data       
	UPDATE #inputTmp        
	SET     ProductName = CASE WHEN LEN(ProductName) = 0 THEN NULL ELSE ProductName END,
			Description = CASE WHEN LEN(Description) = 0 THEN NULL ELSE Description END,
			ProductPrefix = CASE WHEN LEN(ProductPrefix) = 0 THEN NULL ELSE ProductPrefix END,
			OfferSingle = CASE WHEN LEN(OfferSingle) = 0 THEN NULL ELSE OfferSingle END,
			ApplyDCS = CASE WHEN LEN(ApplyDCS) = 0 THEN NULL ELSE ApplyDCS END,
			Enabled = CASE WHEN LEN(Enabled) = 0 THEN NULL ELSE Enabled END,
			EndOfSupportDate = CASE WHEN LEN(EndOfSupportDate) = 0 THEN NULL ELSE EndOfSupportDate END    
	WHERE LEN(ProductName) = 0
		OR LEN(Description) = 0
		OR LEN(ProductPrefix) = 0
		OR LEN(OfferSingle) = 0
		OR LEN(ApplyDCS) = 0
		OR LEN(Enabled) = 0
		OR LEN(EndOfSupportDate) = 0 ;   

		SELECT TOP(1)  @ValueError = CASE WHEN LEN(ProductName) > 50 THEN ProductName 
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
								ELSE 1008 END      
			FROM #inputTmp  WITH(NOLOCK)       
			WHERE  LEN(ProductName) > 50  OR LEN(Description) > 100  OR LEN(ProductPrefix) > 10
			OR ProductName IS NULL 
			ORDER BY ID;  
	IF @ErrCode <> 0      
	BEGIN      
		IF @ErrCode = 1007      
		SELECT @ErrMsg      
		= 'The value "' + ISNULL(@ValueError, '')      
		+ '" is exceeded max length ' + CONVERT(VARCHAR(8), @LimitValue) + '.';      
		IF @ErrCode = 1008      
		SELECT @ErrMsg = 'Invalid "ProductName" - The values must be not null'
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
    
    WHILE @CurrentRow <> @RowTotal      
    BEGIN      
        SELECT @CurrentRow = @CurrentRow + 1,      
               @startRun = GETDATE();      
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
        BEGIN TRY  
			--UPDATE p3    
			--SET p3.ProductName = i.ProductName,
			--p3.Description = i.Description,
			--p3.ProductPrefix = i.ProductPrefix,
			--p3.OfferSingle = i.OfferSingle,
			--p3.ApplyDCS = i.ApplyDCS,
			--p3.Enabled = i.Enabled,
			--p3.EndOfSupportDate = i.EndOfSupportDate  
			--FROM  DBCUST.bodb_Licensee.dbo.Product3rd p3 WITH(ROWLOCK)    
			--INNER JOIN #input i ON i.Productid  = vgs.Productid  
			--WHERE i.ID = @CurrentRow    
            SELECT i.*
			FROM  DBCUST.bodb_Licensee.dbo.Product3rd p3 WITH(ROWLOCK)    
			INNER JOIN #input i ON i.Productid  = vgs.Productid  
			WHERE i.ID = @CurrentRow       
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
             
		--EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper     
		--	@UserID = @UserID,    
		--	@ActionID = 6061,    
		--	@TrackingValue = @LogSPData,    
		--	@TrackingValue2 = @logSpData_Old,    
		--	@duration = @Duration     
    END;      
 DROP TABLE #input, #inputTmp;      
END   
GO