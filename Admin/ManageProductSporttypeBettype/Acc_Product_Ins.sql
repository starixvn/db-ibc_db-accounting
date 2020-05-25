/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Product_Ins
	@File	    NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserID		INT
AS
/*
Created: 20200413@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200413@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
	Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
						ProductID = "1" ProductName= "a"  Description = "ml" ProductPrefix= "" Enabled=""  EndOfSupportDate=""  BalanceType=""
						SubProductBalanceType="" GroupType="" CasinoType="4" IsOfferPlayForFun=""  VendorID="5"	OrderNo = ""
				/>
		</ROOT>	
		
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN


	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @ProductError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX),@ColumnName VARCHAR(100)

	CREATE TABLE #input 
	(    
		ID              		INT IDENTITY (1,1),
		ProductID 				TINYINT,
		ProductName 			VARCHAR(50),
		Description 			VARCHAR(100),
		ProductPrefix 			VARCHAR(10),
		Enabled 				BIT,	
		EndOfSupportDate 		DATE,
		BalanceType 			TINYINT,
		SubProductBalanceType 	VARCHAR(512),
		GroupType 				TINYINT,
		CasinoType 				TINYINT,
		IsOfferPlayForFun 		BIT,		
		VendorID 				SMALLINT,
		OrderNo                 INT
	)

	CREATE TABLE #inputTmp
	(    
		ProductID 				NVARCHAR(MAX),
		ProductName 			NVARCHAR(MAX),
		Description 			NVARCHAR(MAX),
		ProductPrefix 			NVARCHAR(MAX),
		Enabled 				NVARCHAR(MAX),
		EndOfSupportDate 		NVARCHAR(MAX),
		BalanceType 			NVARCHAR(MAX),
		SubProductBalanceType 	NVARCHAR(MAX),
		GroupType 				NVARCHAR(MAX),
		CasinoType 				NVARCHAR(MAX),
		IsOfferPlayForFun 		NVARCHAR(MAX),	
		VendorID 				NVARCHAR(MAX),
		OrderNo					NVARCHAR(MAX)
	)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #inputTmp 
			(              
                 			ProductID,
							ProductName,
							Description,
							ProductPrefix,
							Enabled,	
							EndOfSupportDate,							
							BalanceType,
							SubProductBalanceType,
							GroupType,
							CasinoType,
							IsOfferPlayForFun,							
							VendorID,
							OrderNo
			)

			SELECT          ProductID,
							ProductName,
							Description,
							ProductPrefix,
							Enabled,		
							EndOfSupportDate,							
							BalanceType,
							SubProductBalanceType,
							GroupType,
							CasinoType,
							IsOfferPlayForFun,
							VendorID,
							OrderNo

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (ProductID 				NVARCHAR(MAX),
														ProductName 			NVARCHAR(MAX),
														Description 			NVARCHAR(MAX),
														ProductPrefix 			NVARCHAR(MAX),
														Enabled 				NVARCHAR(MAX),
														EndOfSupportDate 		NVARCHAR(MAX),														
														BalanceType 			NVARCHAR(MAX),
														SubProductBalanceType 	NVARCHAR(MAX),
														GroupType 				NVARCHAR(MAX),
														CasinoType 				NVARCHAR(MAX),
														IsOfferPlayForFun 		NVARCHAR(MAX),												
														VendorID 				NVARCHAR(MAX),
														OrderNo 				NVARCHAR(MAX))
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH
	-- remove row
	DELETE #inputTmp  
	WHERE   LEN(ProductID) 				    = 0
			AND LEN(ProductName) 			= 0
			AND LEN(Description) 			= 0
			AND LEN(ProductPrefix) 			= 0
			AND LEN(Enabled) 				= 0		
			AND LEN(EndOfSupportDate) 		= 0
			AND LEN(BalanceType) 			= 0
			AND LEN(SubProductBalanceType) 	= 0
			AND LEN(GroupType) 				= 0
			AND LEN(CasinoType) 			= 0
			AND LEN(IsOfferPlayForFun) 		= 0			
			AND LEN(VendorID) 				= 0
			AND LEN(OrderNo) 				= 0
   
    UPDATE #inputTmp
	SET ProductID			= CASE WHEN LEN(ProductID)			= 0 THEN  NULL ELSE ProductID 			END,
		ProductName			= CASE WHEN LEN(ProductName)		= 0 THEN  NULL ELSE ProductName 		END,
		Enabled     		= CASE WHEN LEN(Enabled)			= 0 THEN  NULL ELSE Enabled				END,
		EndOfSupportDate  	= CASE WHEN LEN(EndOfSupportDate)	= 0 THEN  NULL ELSE EndOfSupportDate 	END,
		BalanceType  		= CASE WHEN LEN(BalanceType)		= 0 THEN  NULL ELSE BalanceType 		END,
		GroupType  			= CASE WHEN LEN(GroupType)			= 0 THEN  NULL ELSE GroupType 			END,
		CasinoType  		= CASE WHEN LEN(CasinoType)			= 0 THEN  NULL ELSE CasinoType 			END,
		IsOfferPlayForFun  	= CASE WHEN LEN(IsOfferPlayForFun)	= 0 THEN  NULL ELSE IsOfferPlayForFun 	END,	
		VendorID  			= CASE WHEN LEN(VendorID)			= 0 THEN  NULL ELSE VendorID 			END,
		OrderNo  			= CASE WHEN LEN(OrderNo)			= 0 THEN  NULL ELSE OrderNo 			END

	WHERE LEN(ProductID)			= 0 
	      OR LEN(ProductName)       = 0
	      OR LEN(Enabled)			= 0
		  OR LEN(EndOfSupportDate)	= 0
		  OR LEN(BalanceType)		= 0
		  OR LEN(GroupType)			= 0
		  OR LEN(CasinoType)		= 0
		  OR LEN(IsOfferPlayForFun)	= 0  
		  OR LEN(VendorID)			= 0
		  OR LEN(OrderNo)			= 0

	SELECT TOP(1) @ProductError = ProductID, 
	
	              @ValueError   = CASE WHEN LEN(Description)			> 100	THEN Description
									   WHEN LEN(SubProductBalanceType) 	> 512	THEN SubProductBalanceType
									   WHEN LEN(ProductPrefix)			> 10	THEN ProductPrefix	
									   WHEN LEN(ProductName)			> 50	THEN ProductName
									   ELSE NULL END,
									   
				  @LimitValue   = CASE WHEN LEN(Description)        	> 100	THEN 100
                              	       WHEN LEN(SubProductBalanceType)  > 512	THEN 512
									   WHEN LEN(ProductPrefix)			> 10	THEN 10	
									   ELSE 50 END,
				  @ErrCode      = CASE WHEN IsOfferPlayForFun NOT IN (0,1) AND IsOfferPlayForFun IS NOT NULL THEN 1008
				                       WHEN [Enabled] NOT IN (0,1) AND [Enabled] IS NOT NULL THEN 1008
								  ELSE 1007 END,
				  @ColumnName   =  CASE WHEN IsOfferPlayForFun NOT IN (0,1) AND IsOfferPlayForFun IS NOT NULL THEN 'IsOfferPlayForFun'
				                       WHEN [Enabled] NOT IN (0,1) AND [Enabled] IS NOT NULL THEN 'Enabled'
								   ELSE NULL END
									
	FROM #inputTmp
	WHERE LEN(Description)		  		> 100 
		  OR LEN(SubProductBalanceType)	> 512
		  OR LEN(ProductPrefix)		  	> 10
		  OR LEN(ProductName)   		> 50	  
		  OR (IsOfferPlayForFun	NOT IN (0,1) AND IsOfferPlayForFun IS NOT NULL)
		  OR ([Enabled]			NOT IN (0,1) AND [Enabled] IS NOT NULL)
							

	IF @ErrCode <> 0
	   BEGIN
	     IF @ErrCode = 1007
		 SELECT @ErrMsg = 'At ProductId = "' + ISNULL(@ProductError,'') + 
				           '" . The value "' + ISNULL(@ValueError,'') + '" is exceeded max length ' + CONVERT(VARCHAR(4),@LimitValue) + '.'
		 IF @ErrCode = 1008
		 SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" On productID  = "' + ISNULL(@ProductError,'') + '". Please check again.'

	     RETURN
	   END
	   
	BEGIN TRY
		INSERT INTO #input
		SELECT *
		FROM #inputTmp
	END TRY

	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	SELECT  @ProductError = ProductID,
			@ColumnName = CASE WHEN BalanceType IS NULL OR BalanceType  NOT BETWEEN 1 AND 4 THEN 'BalanceType'
			                   WHEN GroupType	IS NULL OR GroupType NOT IN (0,1) THEN 'GroupType'
						  ELSE 'CasinoType' END,
			@ErrCode = 1007
	FROM #input
	WHERE BalanceType IS NULL OR BalanceType  NOT BETWEEN 1 AND 4
	    OR GroupType  IS NULL OR GroupType NOT IN (0,1)
		OR CasinoType  IS NULL OR CasinoType NOT BETWEEN 0 AND 2

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" On productID  = "' + ISNULL(@ProductError,'') + '". Please check again.'
		RETURN
	END
		
		 
	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE();

		BEGIN TRY
			INSERT INTO dbo.Products
			(						
									ProductID,
									ProductName,
									Description,
									ProductPrefix,
									Enabled,	
									EndOfSupportDate,									
									BalanceType,
									SubProductBalanceType,
									GroupType,
									CasinoType,
									IsOfferPlayForFun,									
									VendorID,
									OrderNo									
			)

			SELECT					ProductID,
									ProductName,
									Description,
									ProductPrefix,
									Enabled,	
									EndOfSupportDate,									
									BalanceType,
									SubProductBalanceType,
									GroupType,
									CasinoType,
									IsOfferPlayForFun,								
									VendorID,
									OrderNo
			FROM #input
			WHERE ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH 
		

		SELECT @LogSPData =   '<R ProductID="'+ COALESCE(CAST(ProductID AS VARCHAR(4)), SPACE(1)) + '" ' +
								'ProductName="' + COALESCE(CAST(ProductName  AS VARCHAR(50)), SPACE(1)) + '" ' +
								'Description="' + COALESCE(CAST(Description  AS VARCHAR(100)), SPACE(1)) + '" ' +
								'ProductPrefix="' + COALESCE(CAST(ProductPrefix  AS NVARCHAR(10)), SPACE(1)) + '" ' +																
								'Enabled="' + COALESCE(CAST(Enabled  AS NVARCHAR(2)), SPACE(1)) + '" ' +
								'EndOfSupportDate="' + COALESCE(CAST(EndOfSupportDate  AS NVARCHAR(30)), SPACE(1)) + '" ' +
								'BalanceType="' + COALESCE(CAST(BalanceType  AS NVARCHAR(4)), SPACE(1)) + '" ' +
								'SubProductBalanceType="' + COALESCE(CAST(SubProductBalanceType  AS VARCHAR(512)), SPACE(1)) + '" ' +
								'GroupType="' + COALESCE(CAST(GroupType  AS NVARCHAR(4)), SPACE(1)) + '" ' +
								'CasinoType="' + COALESCE(CAST(CasinoType  AS NVARCHAR(4)), SPACE(1)) + '" ' +
								'IsOfferPlayForFun="' + COALESCE(CAST(IsOfferPlayForFun  AS NVARCHAR(2)), SPACE(1)) + '" ' +														
								'VendorID="' + COALESCE(CAST(VendorID  AS NVARCHAR(8)), SPACE(1)) + '" ' +		
								'OrderNo="' + COALESCE(CAST(OrderNo  AS NVARCHAR(12)), SPACE(1)) + '" ' +									
								'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
			FROM #input
			WHERE ID = @CurrentRow

			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@ActionID = 95011,
					@TrackingValue = @LogSPData,
					@duration = @duration
	END
	
	DROP TABLE #input
	DROP TABLE #inputTmp
END