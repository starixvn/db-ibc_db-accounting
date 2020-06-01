/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE  dbo.Acc_SportBettypeMatrix_Upd
	@File		NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserID		INT
AS

/*
Created: 20200416@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200416@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		
*/
BEGIN
    SET NOCOUNT ON
	
    IF ISNULL(@File, '') = ''
		RETURN

	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @Sporttype  SMALLINT = 0, @Bettype SMALLINT, @Islive BIT, 
			@MatrixError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

    DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	
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
		RefTable		TINYINT 
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
		RefTable		NVARCHAR(MAX)
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
							RefTable)

			SELECT         SportType,
						   BetType,
						   IsLive,
						   ProductID,
						   Enabled,
						   IsTest,
						   EventType,
						   SubProduct,
						   RefTable

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (SportType		NVARCHAR(MAX),
														BetType			NVARCHAR(MAX),
														IsLive			NVARCHAR(MAX),
														ProductID		NVARCHAR(MAX),
														Enabled			NVARCHAR(MAX),
														IsTest			NVARCHAR(MAX),
														EventType		NVARCHAR(MAX),
														SubProduct		NVARCHAR(MAX),
														RefTable		NVARCHAR(MAX))
														
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	UPDATE #inputTmp
	SET	    SportType	= CASE WHEN LEN(SportType)	= 0 THEN NULL ELSE SportType	END,
			BetType     = CASE WHEN LEN(BetType)    = 0 THEN NULL ELSE BetType      END,
			IsLive      = CASE WHEN LEN(IsLive)     = 0 THEN NULL ELSE IsLive       END,
			ProductID   = CASE WHEN LEN(ProductID)  = 0 THEN NULL ELSE ProductID    END,
			Enabled     = CASE WHEN LEN(Enabled)    = 0 THEN NULL ELSE Enabled      END,
			IsTest      = CASE WHEN LEN(IsTest)     = 0 THEN NULL ELSE IsTest       END,
			EventType   = CASE WHEN LEN(EventType)  = 0 THEN NULL ELSE EventType    END,
			RefTable    = CASE WHEN LEN(RefTable)   = 0 THEN NULL ELSE RefTable     END

	WHERE LEN(SportType)		= 0
		   OR LEN(BetType)		= 0
		   OR LEN(IsLive)		= 0
		   OR LEN(ProductID)	= 0
		   OR LEN(Enabled)		= 0
		   OR LEN(IsTest)		= 0
		   OR LEN(EventType)	= 0
		   OR LEN(RefTable)		= 0

	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),ID), 
	              @ValueError 	= SubProduct,
                  @LimitValue	= 500
	FROM #inputTmp
	WHERE  LEN(SubProduct) > 500

	IF @ValueError <> ''
	   BEGIN
		 SELECT @ErrCode = 1007, 
		        @ErrMsg = 'The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) +'.'
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
			RefTable
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
			RefTable

		FROM #inputTmp
	END TRY
	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),I.ID), 
	              @ValueError 	= i.BetType,
				  @ErrCode      = CASE WHEN i.BetType >= 19999 THEN 1009								   
								  ELSE 1010 END
	FROM #input i
		INNER JOIN #input p ON i.BetType = p.BetType
		LEFT JOIN SportBettypeMatrix m WITH(NOLOCK) ON i.BetType = m.BetType
	WHERE i.ProductID <> p.ProductID OR i.RefTable <> p.RefTable OR i.EventType <> p.EventType 
		OR (m.BetType IS NOT NULL 
			AND (m.SportType <> p.SportType OR m.IsLive <> p.IsLive) 
			AND (i.ProductID <> M.ProductID OR i.RefTable <> m.RefTable OR i.EventType <> m.EventType))	

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'the ProductID, RefTable, EventType of Rows must be the same for the same BetType.'
		RETURN
	END

	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow = @CurrentRow + 1, @startRun = GETDATE()

		SELECT @Sporttype = SportType, @Bettype = BetType, @Islive = IsLive FROM #input WHERE ID = @CurrentRow

		SELECT @LogSPData2 = '<R SportType="'+ COALESCE(CAST(SportType AS VARCHAR(6)), SPACE(1)) + '" ' +
		                    'BetType="' + COALESCE(CAST(BetType  AS VARCHAR(6)), SPACE(1)) + '" ' +
		                    'IsLive="' + COALESCE(CAST(IsLive   AS VARCHAR(2)), SPACE(1)) + '" ' +
							'ProductID="' + COALESCE(CAST(ProductID  AS VARCHAR(4)), SPACE(1)) + '" ' +
							'Enabled="' + COALESCE(CAST(Enabled  AS VARCHAR(2)), SPACE(1)) + '" ' +
							'IsTest="' + COALESCE(CAST(IsTest  AS VARCHAR(2)), SPACE(1)) + '" ' +
							'EventType="' + COALESCE(CAST(EventType  AS VARCHAR(4)), SPACE(1)) + '" ' +
							'SubProduct="' + COALESCE(CAST(SubProduct  AS VARCHAR(500)), SPACE(1)) + '" ' +
							'RefTable="' + COALESCE(CAST(RefTable  AS NVARCHAR(4)), SPACE(1)) + '" ' +														
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM dbo.SportBettypeMatrix WITH(NOLOCK)
		WHERE SportType = @Sporttype 
		      AND BetType = @Bettype 
			  AND IsLive = @Islive

		BEGIN TRY
			UPDATE f
			SET f.ProductID   = t.ProductID,
				f.Enabled     = t.Enabled,
				f.IsTest      = t.IsTest,
				f.EventType   = t.EventType,
				f.SubProduct  = t.SubProduct,
				f.RefTable    = t.RefTable
				
			FROM dbo.SportBettypeMatrix f
				INNER JOIN #input t ON  f.SportType = t.SportType AND f.BetType = t.BetType AND f.IsLive = t.IsLive
	   	    WHERE t.ID = @CurrentRow
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
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM #input 
		WHERE  ID = @CurrentRow
		
		SET @endRun = GETDATE()
	    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95014,
				@TrackingValue = @LogSPData,
				@TrackingValue2 = @LogSPData2,
				@duration = @duration
	END
	DROP TABLE #input
	DROP TABLE #inputTmp
END

