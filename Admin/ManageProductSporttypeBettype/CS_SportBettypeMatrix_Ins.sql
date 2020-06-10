/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.CS_SportBettypeMatrix_Ins
	@File		NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserId		INT
AS

/*
Created: 20200416@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200416@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
					SportType = "" BetType = "" IsLive = "" ProductID = "" Enabled = "" IsTest = "" EventType = "" 
					SubProduct = "" RefTable	= "" SportTypeGroup = "" BetTypeGroup = ""
				/>
		</ROOT>	
		
*/
BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN

	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	
	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @MatrixError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', 
			@LimitValue BIGINT,@ColumnName NVARCHAR(200)

	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		SportType		SMALLINT,
		BetType			SMALLINT,
		IsLive			BIT,
		ProductID		TINYINT,
		Enabled			BIT,
		IsTest			BIT,
		EventType		TINYINT,
		SubProduct		VARCHAR(500),
		RefTable		TINYINT,
		SportTypeGroup  SMALLINT,
		BetTypeGroup    SMALLINT
	)

	CREATE TABLE #inputTmp
	(   
	    ID				INT IDENTITY (1,1),
		SportType		NVARCHAR(MAX),
		BetType			NVARCHAR(MAX),
		IsLive			NVARCHAR(MAX),
		ProductID		NVARCHAR(MAX),
		Enabled			NVARCHAR(MAX),
		IsTest			NVARCHAR(MAX),
		EventType		NVARCHAR(MAX),
		SubProduct		NVARCHAR(MAX),
		RefTable		NVARCHAR(MAX),
		SportTypeGroup  NVARCHAR(MAX),
		BetTypeGroup    NVARCHAR(MAX)
	)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
		  INSERT #inputTmp (SportType,
							BetType,
							IsLive,
							ProductID,
							Enabled,
							IsTest,
							EventType,
							SubProduct,
							RefTable,
							SportTypeGroup,
							BetTypeGroup)

			SELECT          SportType,
							BetType,
							IsLive,
							ProductID,
							Enabled,
							IsTest,
							EventType,
							SubProduct,
							RefTable,
							SportTypeGroup,
							BetTypeGroup

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (SportType		NVARCHAR(MAX),
														BetType			NVARCHAR(MAX),
														IsLive			NVARCHAR(MAX),
														ProductID		NVARCHAR(MAX),
														Enabled			NVARCHAR(MAX),
														IsTest			NVARCHAR(MAX),
														EventType		NVARCHAR(MAX),
														SubProduct		NVARCHAR(MAX),
														RefTable		NVARCHAR(MAX),
														SportTypeGroup  NVARCHAR(MAX),
														BetTypeGroup	NVARCHAR(MAX))
														
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	DELETE #inputTmp
	WHERE  LEN(SportType)			= 0
		   AND LEN(BetType)			= 0
		   AND LEN(IsLive)			= 0
		   AND LEN(ProductID)		= 0
		   AND LEN(Enabled)			= 0
		   AND LEN(IsTest)			= 0
		   AND LEN(EventType)		= 0
		   AND LEN(SubProduct)		= 0
		   AND LEN(RefTable)		= 0
		   AND LEN(SportTypeGroup)	= 0
		   AND LEN(BetTypeGroup)	= 0

	UPDATE #inputTmp
	SET	    SportType		= CASE WHEN LEN(SportType)		= 0 THEN NULL ELSE SportType		END,
			BetType     	= CASE WHEN LEN(BetType)    	= 0 THEN NULL ELSE BetType      	END,
			IsLive      	= CASE WHEN LEN(IsLive)     	= 0 THEN NULL ELSE IsLive       	END,
			ProductID   	= CASE WHEN LEN(ProductID)  	= 0 THEN NULL ELSE ProductID    	END,
			Enabled     	= CASE WHEN LEN(Enabled)    	= 0 THEN NULL ELSE Enabled      	END,
			IsTest      	= CASE WHEN LEN(IsTest)     	= 0 THEN NULL ELSE IsTest       	END,
			EventType   	= CASE WHEN LEN(EventType)  	= 0 THEN NULL ELSE EventType    	END,
			RefTable    	= CASE WHEN LEN(RefTable)   	= 0 THEN NULL ELSE RefTable     	END,
			SportTypeGroup  = CASE WHEN LEN(SportTypeGroup) = 0 THEN NULL ELSE SportTypeGroup   END,
			BetTypeGroup    = CASE WHEN LEN(BetTypeGroup)   = 0 THEN NULL ELSE BetTypeGroup     END

	WHERE LEN(SportType)			= 0
		   OR LEN(BetType)			= 0
		   OR LEN(IsLive)			= 0
		   OR LEN(ProductID)		= 0
		   OR LEN(Enabled)			= 0
		   OR LEN(IsTest)			= 0
		   OR LEN(EventType)		= 0
		   OR LEN(RefTable)			= 0
		   OR LEN(SportTypeGroup)	= 0
		   OR LEN(BetTypeGroup)		= 0

	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),ID), 
	              @ValueError 	= CASE WHEN LEN(SubProduct) > 500 THEN SubProduct
								  ELSE NULL END,
                  @LimitValue	= CASE WHEN LEN(SubProduct) > 500 THEN 500
				                       ELSE 1 END,
				  @ErrCode      = CASE WHEN LEN(SubProduct) > 500 THEN 1007									   
				                       ELSE 1008 END,
				  @ColumnName   = CASE WHEN [Enabled]		IS  NULL OR [Enabled]	NOT IN (0,1)		THEN 'Enabled'
									   WHEN IsTest			IS  NULL OR IsTest		NOT IN (0,1)		THEN 'IsTest'
									   WHEN IsLive			IS  NULL OR IsLive		NOT IN (0,1)		THEN 'IsLive'
									   WHEN EventType		IS  NULL OR EventType	NOT BETWEEN 0 AND 5 THEN 'EventType'
									   WHEN RefTable		IS  NULL OR RefTable	NOT BETWEEN 0 AND 3 THEN 'RefTable'	
									   WHEN BetTypeGroup	IS NULL THEN 'BetTypeGroup'
									   WHEN SportTypeGroup	IS NULL THEN 'SportTypeGroup'
								  ELSE NULL END
	FROM #inputTmp
	WHERE  LEN(SubProduct) > 500
			OR IsLive		IS  NULL OR IsLive			NOT IN (0,1) 
			OR [Enabled]	IS  NULL OR [Enabled]		NOT IN (0,1) 
			OR IsTest		IS  NULL OR IsTest			NOT IN (0,1) 
			OR EventType	IS  NULL OR EventType		NOT BETWEEN 0 AND 5	
		    OR RefTable		IS  NULL OR RefTable		NOT BETWEEN 0 AND 3
			OR BetTypeGroup IS  NULL OR SportTypeGroup	IS NULL
			
	IF @ErrCode <> 0
	   BEGIN
	     IF @ErrCode = 1007
		 SELECT  @ErrMsg = 'Row "' + ISNULL(@MatrixError,'') + 
				          '" - The value "' + ISNULL(@ValueError,'') + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) +'.'
		 IF @ErrCode = 1008
		  SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @MatrixError + '".Please check them again.'  

	     RETURN
	   END
	   
	BEGIN TRY
		INSERT INTO #input
		(	SportType,
			BetType,
			IsLive,
			ProductID,
			Enabled,
			IsTest,
			EventType,
			SubProduct,
			RefTable,
			SportTypeGroup,
			BetTypeGroup
		)
		SELECT 
			SportType,
			BetType,
			IsLive,
			ProductID,
			Enabled,
			IsTest,
			EventType,
			SubProduct,
			RefTable,
			SportTypeGroup,
			BetTypeGroup

		FROM #inputTmp
	END TRY
	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	--Check bettype, Sporttype, Productid, SportTypeGroup, BetTypeGroup
	
	SELECT	@MatrixError 	= CONVERT(VARCHAR(5),I.ID),
			@ErrCode = 1007,
			@ValueError = CASE WHEN s.SportType		IS NULL THEN i.SportType
							   WHEN b.typeid		IS NULL THEN i.BetType
							   WHEN p.ProductID		IS NULL THEN i.ProductID
							   WHEN bg.typeid		IS NULL THEN i.BetTypeGroup
						  ELSE i.SportTypeGroup END,

			@ColumnName = CASE WHEN s.SportType		IS NULL THEN 'Sporttype'
			                   WHEN b.typeid		IS NULL THEN 'Bettype'
							   WHEN p.ProductID		IS NULL THEN 'ProductID'
							   WHEN bg.typeid		IS NULL THEN 'BetTypeGroup'
						  ELSE 'SportTypeGroup' END
	FROM #input i
	     LEFT JOIN dbo.Sports s		WITH(NOLOCK) ON s.SportType = i.SportType
		 LEFT JOIN dbo.Bettype b	WITH(NOLOCK) ON b.typeid = i.BetType
		 LEFT JOIN dbo.Products p	WITH(NOLOCK) ON p.ProductID = i.ProductID
		 LEFT JOIN dbo.Bettype bg	WITH(NOLOCK) ON bg.typeid = i.BetTypeGroup
		 LEFT JOIN CS_f_SportTypeGroup_OrderSel(1) f ON f.SportTypeGroup = i.SportTypeGroup
		 
	WHERE s.SportType		IS NULL 
		OR b.typeid			IS NULL 
		OR p.ProductID		IS NULL
		OR bg.typeid		IS NULL
		OR f.SportTypeGroup IS NULL

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'Row "' + ISNULL(@MatrixError,'') + '" - ' + @ColumnName + ' = "' + ISNULL(@ValueError,'') + '" does not exist.'
		RETURN
	END

	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),I.ID), 
	              @ValueError 	= i.BetType,
				  @ErrCode      = CASE WHEN i.BetType >= 19999 THEN 1009								   
								  ELSE 1010 END
	FROM #input i
		INNER JOIN #input p ON i.BetType = p.BetType
		LEFT JOIN CS_SportBettypeMatrix m WITH(NOLOCK) ON i.BetType = m.BetType
	WHERE i.ProductID <> p.ProductID OR i.RefTable <> p.RefTable OR i.EventType <> p.EventType OR i.BetType >= 19999
		
		OR (m.BetType IS NOT NULL AND (i.ProductID <> m.ProductID OR i.RefTable <> m.RefTable OR i.EventType <> m.EventType))	

	IF @ErrCode <> 0
	   BEGIN
	     IF @ErrCode = 1009
		 SELECT @ErrMsg = 'BetType must be less than 19999 on row "' + @MatrixError + '".'
		 IF @ErrCode = 1010 
		 SELECT @ErrMsg = 'The ProductID, RefTable, EventType of row "' + @MatrixError +'" must be the same for the same BetType.'	                              
	     RETURN
	   END

	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE()

		BEGIN TRY
			INSERT INTO dbo.CS_SportBettypeMatrix
			(	SportType,
				BetType,
				IsLive,
				ProductID,
				Enabled,
				IsTest,
				EventType,
				SubProduct,
				RefTable,
				SportTypeGroup,
				BetTypeGroup
		    )			
			SELECT  
				SportType,
				BetType,
				IsLive,
				ProductID,
				Enabled,
				IsTest,
				EventType,
				SubProduct,
				RefTable,
				SportTypeGroup,
				BetTypeGroup

			FROM #input
			WHERE ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
			RETURN
		END CATCH
		
		SELECT @LogSPData = '<R SportType="'+ COALESCE(CAST(SportType AS VARCHAR(6)), SPACE(1)) + '" ' +
		                    'BetType="' + COALESCE(CAST(BetType  AS VARCHAR(6)), SPACE(1)) + '" ' +
		                    'IsLive="' + COALESCE(CAST(IsLive   AS VARCHAR(2)), SPACE(1)) + '" ' +
							'ProductID="' + COALESCE(CAST(ProductID  AS VARCHAR(4)), SPACE(1)) + '" ' +
							'Enabled="' + COALESCE(CAST(Enabled  AS VARCHAR(2)), SPACE(1)) + '" ' +
							'IsTest="' + COALESCE(CAST(IsTest  AS VARCHAR(2)), SPACE(1)) + '" ' +
							'EventType="' + COALESCE(CAST(EventType  AS VARCHAR(4)), SPACE(1)) + '" ' +
							'SubProduct="' + COALESCE(CAST(SubProduct  AS VARCHAR(500)), SPACE(1)) + '" ' +
							'RefTable="' + COALESCE(CAST(RefTable  AS NVARCHAR(4)), SPACE(1)) + '" ' +		
							'SportTypeGroup="' + COALESCE(CAST(SportTypeGroup  AS VARCHAR(8)), SPACE(1)) + '" ' +
							'BetTypeGroup="' + COALESCE(CAST(BetTypeGroup  AS NVARCHAR(8)), SPACE(1)) + '" ' +	
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM #input
		WHERE ID = @CurrentRow

		SET @endRun = GETDATE()
	    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95023,
				@TrackingValue = @LogSPData,
				@duration = @duration
	END

	DROP TABLE #input

	DROP TABLE #inputTmp
END