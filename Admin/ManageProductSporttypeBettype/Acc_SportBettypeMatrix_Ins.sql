/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_SportBettypeMatrix_Ins
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
					SportType = "" BetType = "" IsLive = "" ProductID = "" Enabled = "" IsTest = "" EventType = "" SubProduct = "" RefTable	= ""
				/>
		</ROOT>	
		
*/
BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN

   

	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	

	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @MatrixError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

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

			SELECT          SportType,
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

	DELETE #inputTmp
	WHERE  LEN(SportType)		= 0
		   AND LEN(BetType)		= 0
		   AND LEN(IsLive)		= 0
		   AND LEN(ProductID)	= 0
		   AND LEN(Enabled)		= 0
		   AND LEN(IsTest)		= 0
		   AND LEN(EventType)	= 0
		   AND LEN(SubProduct)	= 0
		   AND LEN(RefTable)	= 0

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
		        @ErrMsg = 'At Row = "' + @MatrixError + 
				          '" . The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) +'.'
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

	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE()

		BEGIN TRY
			INSERT INTO dbo.SportBettypeMatrix
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
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM #input
		WHERE ID = @CurrentRow

		SET @endRun = GETDATE()
	    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95013,
				@TrackingValue = @LogSPData,
				@duration = @duration
	END
	DROP TABLE #input
	DROP TABLE #inputTmp
END