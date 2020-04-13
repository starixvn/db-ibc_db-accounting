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
						ProductID = "1" ProductName= "a" Description="" ProductPrefix= "" Enabled="" ProductNameCh="" ProductNameCs="" ProductNameJp="" ProductNameIt=""
						ProductNameTh="" ProductNameKo="" ProductNameES="" ProductNameVN="" ProductNameEL="" ProductNameRU="" ProductNameID="" BalanceType="" 
						SubProductBalanceType="" GroupType="" CasinoType="4" IsOfferPlayForFun="" EndOfSupportDate="" VendorID="5"				
				/>
		</ROOT>	
		
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN


	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @ProductError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)

	CREATE TABLE #input 
	(    
		ID              		INT IDENTITY (1,1),
		ProductID 				TINYINT,
		ProductName 			VARCHAR(50),
		Description 			VARCHAR(100),
		ProductPrefix 			VARCHAR(10),
		Enabled 				BIT,
		ProductNameCh 			NVARCHAR(50),
		ProductNameCs 			NVARCHAR(50),
		ProductNameJp 			NVARCHAR(50),
		ProductNameIt 			NVARCHAR(50),
		ProductNameTh 			NVARCHAR(50),
		ProductNameKo 			NVARCHAR(50),
		ProductNameES 			NVARCHAR(50),
		ProductNameVN 			NVARCHAR(50),
		ProductNameEL 			NVARCHAR(50),
		ProductNameRU 			NVARCHAR(50),
		ProductNameID 			NVARCHAR(50),
		BalanceType 			TINYINT,
		SubProductBalanceType 	VARCHAR(512),
		GroupType 				TINYINT,
		CasinoType 				TINYINT,
		IsOfferPlayForFun 		BIT,
		EndOfSupportDate 		DATE,
		VendorID 				SMALLINT 
	)

	CREATE TABLE #inputTmp
	(    
		ProductID 				NVARCHAR(MAX),
		ProductName 			NVARCHAR(MAX),
		Description 			NVARCHAR(MAX),
		ProductPrefix 			NVARCHAR(MAX),
		Enabled 				NVARCHAR(MAX),
		ProductNameCh 			NVARCHAR(MAX),
		ProductNameCs 			NVARCHAR(MAX),
		ProductNameJp 			NVARCHAR(MAX),
		ProductNameIt 			NVARCHAR(MAX),
		ProductNameTh 			NVARCHAR(MAX),
		ProductNameKo 			NVARCHAR(MAX),
		ProductNameES 			NVARCHAR(MAX),
		ProductNameVN 			NVARCHAR(MAX),
		ProductNameEL 			NVARCHAR(MAX),
		ProductNameRU 			NVARCHAR(MAX),
		ProductNameID 			NVARCHAR(MAX),
		BalanceType 			NVARCHAR(MAX),
		SubProductBalanceType 	NVARCHAR(MAX),
		GroupType 				NVARCHAR(MAX),
		CasinoType 				NVARCHAR(MAX),
		IsOfferPlayForFun 		NVARCHAR(MAX),
		EndOfSupportDate 		NVARCHAR(MAX),
		VendorID 				NVARCHAR(MAX)
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
							ProductNameCh,
							ProductNameCs,
							ProductNameJp,
							ProductNameIt,
							ProductNameTh,
							ProductNameKo,
							ProductNameES,
							ProductNameVN,
							ProductNameEL,
							ProductNameRU,
							ProductNameID,
							BalanceType,
							SubProductBalanceType,
							GroupType,
							CasinoType,
							IsOfferPlayForFun,
							EndOfSupportDate,
							VendorID
			)

			SELECT          ProductID,
							ProductName,
							Description,
							ProductPrefix,
							Enabled,
							ProductNameCh,
							ProductNameCs,
							ProductNameJp,
							ProductNameIt,
							ProductNameTh,
							ProductNameKo,
							ProductNameES,
							ProductNameVN,
							ProductNameEL,
							ProductNameRU,
							ProductNameID,
							BalanceType,
							SubProductBalanceType,
							GroupType,
							CasinoType,
							IsOfferPlayForFun,
							EndOfSupportDate,
							VendorID

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (ProductID 				NVARCHAR(MAX),
														ProductName 			NVARCHAR(MAX),
														Description 			NVARCHAR(MAX),
														ProductPrefix 			NVARCHAR(MAX),
														Enabled 				NVARCHAR(MAX),
														ProductNameCh 			NVARCHAR(MAX),
														ProductNameCs 			NVARCHAR(MAX),
														ProductNameJp 			NVARCHAR(MAX),
														ProductNameIt 			NVARCHAR(MAX),
														ProductNameTh 			NVARCHAR(MAX),
														ProductNameKo 			NVARCHAR(MAX),
														ProductNameES 			NVARCHAR(MAX),
														ProductNameVN 			NVARCHAR(MAX),
														ProductNameEL 			NVARCHAR(MAX),
														ProductNameRU 			NVARCHAR(MAX),
														ProductNameID 			NVARCHAR(MAX),
														BalanceType 			NVARCHAR(MAX),
														SubProductBalanceType 	NVARCHAR(MAX),
														GroupType 				NVARCHAR(MAX),
														CasinoType 				NVARCHAR(MAX),
														IsOfferPlayForFun 		NVARCHAR(MAX),
														EndOfSupportDate 		NVARCHAR(MAX),
														VendorID 				NVARCHAR(MAX))
		    
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
			AND LEN(ProductNameCh) 			= 0
			AND LEN(ProductNameCs) 			= 0
			AND LEN(ProductNameJp) 			= 0
			AND LEN(ProductNameIt) 			= 0
			AND LEN(ProductNameTh) 			= 0
			AND LEN(ProductNameKo) 			= 0
			AND LEN(ProductNameES) 			= 0
			AND LEN(ProductNameVN) 			= 0
			AND LEN(ProductNameEL) 			= 0
			AND LEN(ProductNameRU) 			= 0
			AND LEN(ProductNameID) 			= 0
			AND LEN(BalanceType) 			= 0
			AND LEN(SubProductBalanceType) 	= 0
			AND LEN(GroupType) 				= 0
			AND LEN(CasinoType) 			= 0
			AND LEN(IsOfferPlayForFun) 		= 0
			AND LEN(EndOfSupportDate) 		= 0
			AND LEN(VendorID) 				= 0
   
    UPDATE #inputTmp
	SET ProductID			= CASE WHEN LEN(ProductID)			= 0 THEN  NULL ELSE ProductID 			END,
		Enabled     		= CASE WHEN LEN(Enabled)			= 0 THEN  NULL ELSE Enabled				END,
		BalanceType  		= CASE WHEN LEN(BalanceType)		= 0 THEN  NULL ELSE BalanceType 		END,
		GroupType  			= CASE WHEN LEN(GroupType)			= 0 THEN  NULL ELSE GroupType 			END,
		CasinoType  		= CASE WHEN LEN(CasinoType)			= 0 THEN  NULL ELSE CasinoType 			END,
		IsOfferPlayForFun  	= CASE WHEN LEN(IsOfferPlayForFun)	= 0 THEN  NULL ELSE IsOfferPlayForFun 	END,
		EndOfSupportDate  	= CASE WHEN LEN(EndOfSupportDate)	= 0 THEN  NULL ELSE EndOfSupportDate 	END,
		VendorID  			= CASE WHEN LEN(VendorID)			= 0 THEN  NULL ELSE VendorID 			END

	WHERE LEN(ProductID)			= 0 
	      OR LEN(Enabled)			= 0
		  OR LEN(BalanceType)		= 0
		  OR LEN(GroupType)			= 0
		  OR LEN(CasinoType)		= 0
		  OR LEN(IsOfferPlayForFun)	= 0
		  OR LEN(EndOfSupportDate)	= 0
		  OR LEN(VendorID)			= 0

	SELECT TOP(1) @ProductError = ProductID, 
	
	              @ValueError   = CASE WHEN LEN(Description)			> 100 THEN Description
									   WHEN LEN(SubProductBalanceType) 	> 512 THEN SubProductBalanceType
									   WHEN LEN(ProductPrefix)			> 10  THEN ProductPrefix
									   WHEN LEN(ProductName)			> 50  THEN ProductName
							           WHEN LEN(ProductNameCh)			> 50  THEN ProductNameCh
							           WHEN LEN(ProductNameCs)			> 50  THEN ProductNameCs
							           WHEN LEN(ProductNameJp)			> 50  THEN ProductNameJp
									   WHEN LEN(ProductNameIt)			> 50  THEN ProductNameIt
									   WHEN LEN(ProductNameTh)			> 50  THEN ProductNameTh
							           WHEN LEN(ProductNameKo)			> 50  THEN ProductNameKo
							           WHEN LEN(ProductNameES)			> 50  THEN ProductNameES
							           WHEN LEN(ProductNameVN)			> 50  THEN ProductNameVN
							           WHEN LEN(ProductNameEL)			> 50  THEN ProductNameEL
									   WHEN LEN(ProductNameRU)			> 50  THEN ProductNameRU
							           ELSE ProductNameID END,
									   
				  @LimitValue   = CASE WHEN LEN(Description)        	> 100 THEN 100
                              	       WHEN LEN(SubProductBalanceType)  > 512 THEN 512
									   WHEN LEN(ProductPrefix)			> 10  THEN 10	
									   ELSE 50 END
									
	FROM #inputTmp
	WHERE LEN(Description)		  		> 100 
		  OR LEN(SubProductBalanceType)	> 512
		  OR LEN(ProductPrefix)		  	> 10
		  OR LEN(ProductName)   		> 50
		  OR LEN(ProductNameCh)		 	> 50
		  OR LEN(ProductNameCs)		  	> 50
		  OR LEN(ProductNameJp)	  		> 50
		  OR LEN(ProductNameIt)	  		> 50
	      OR LEN(ProductNameTh)	  		> 50
		  OR LEN(ProductNameKo)	  		> 50
		  OR LEN(ProductNameES)	  		> 50
		  OR LEN(ProductNameVN)	  		> 50
		  OR LEN(ProductNameEL)	  		> 50
		  OR LEN(ProductNameRU)	  		> 50
		  OR LEN(ProductNameID)	  		> 50
							

	IF @ValueError <> ''
	   BEGIN
		 SELECT @ErrCode = 1007, 
		        @ErrMsg = 'At ProductId = "' + @ProductError + 
				           '" . The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(4),@LimitValue) + '.'

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
									ProductNameCh,
									ProductNameCs,
									ProductNameJp,
									ProductNameIt,
									ProductNameTh,
									ProductNameKo,
									ProductNameES,
									ProductNameVN,
									ProductNameEL,
									ProductNameRU,
									ProductNameID,
									BalanceType,
									SubProductBalanceType,
									GroupType,
									CasinoType,
									IsOfferPlayForFun,
									EndOfSupportDate,
									VendorID
			)

			SELECT					ProductID,
									ProductName,
									Description,
									ProductPrefix,
									Enabled,
									ProductNameCh,
									ProductNameCs,
									ProductNameJp,
									ProductNameIt,
									ProductNameTh,
									ProductNameKo,
									ProductNameES,
									ProductNameVN,
									ProductNameEL,
									ProductNameRU,
									ProductNameID,
									BalanceType,
									SubProductBalanceType,
									GroupType,
									CasinoType,
									IsOfferPlayForFun,
									EndOfSupportDate,
									VendorID
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
								'ProductNameCh="' + COALESCE(CAST(ProductNameCh  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameCs="' + COALESCE(CAST(ProductNameCs  AS NVARCHAR(50)), SPACE(1)) + '" ' +								
								'ProductNameJp="' + COALESCE(CAST(ProductNameJp  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameIt="' + COALESCE(CAST(ProductNameIt  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameTh="' + COALESCE(CAST(ProductNameTh  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameKo="' + COALESCE(CAST(ProductNameKo  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameES="' + COALESCE(CAST(ProductNameES  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameVN="' + COALESCE(CAST(ProductNameVN  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameEL="' + COALESCE(CAST(ProductNameEL  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameRU="' + COALESCE(CAST(ProductNameRU  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'ProductNameID="' + COALESCE(CAST(ProductNameID  AS NVARCHAR(50)), SPACE(1)) + '" ' +
								'SubProductBalanceType="' + COALESCE(CAST(SubProductBalanceType  AS VARCHAR(512)), SPACE(1)) + '" ' +
								'Enabled="' + COALESCE(CAST(Enabled  AS NVARCHAR(2)), SPACE(1)) + '" ' +
								'BalanceType="' + COALESCE(CAST(BalanceType  AS NVARCHAR(4)), SPACE(1)) + '" ' +
								'GroupType="' + COALESCE(CAST(GroupType  AS NVARCHAR(4)), SPACE(1)) + '" ' +
								'CasinoType="' + COALESCE(CAST(CasinoType  AS NVARCHAR(4)), SPACE(1)) + '" ' +
								'IsOfferPlayForFun="' + COALESCE(CAST(IsOfferPlayForFun  AS NVARCHAR(2)), SPACE(1)) + '" ' +							
								'EndOfSupportDate="' + COALESCE(CAST(EndOfSupportDate  AS NVARCHAR(30)), SPACE(1)) + '" ' +
								'VendorID="' + COALESCE(CAST(VendorID  AS NVARCHAR(8)), SPACE(1)) + '" ' +							
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