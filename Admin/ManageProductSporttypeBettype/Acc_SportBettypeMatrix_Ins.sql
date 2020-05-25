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
		RefTable		NVARCHAR(MAX),
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
	              @ValueError 	= CASE WHEN IsLive		NOT IN (0,1) AND IsLive		IS NOT NULL	THEN  IsLive
									   WHEN [Enabled]	NOT IN (0,1) AND [Enabled]	IS NOT NULL	THEN  [Enabled]
									   WHEN IsTest		NOT IN (0,1) AND IsTest		IS NOT NULL	THEN  IsTest
									   ELSE SubProduct	END,
                  @LimitValue	= CASE WHEN LEN(SubProduct) > 500 THEN 500
				                       ELSE 1 END,
				  @ErrCode      = CASE WHEN LEN(SubProduct) > 500 THEN 1007
				                       ELSE 1008 END
	FROM #inputTmp
	WHERE  LEN(SubProduct) > 500
			OR (IsLive		NOT IN (0,1) AND IsLive		IS NOT NULL)
			OR ([Enabled]	NOT IN (0,1) AND [Enabled]	IS NOT NULL)
			OR (IsTest		NOT IN (0,1) AND IsTest		IS NOT NULL)


	IF @ValueError <> ''
	   BEGIN
	     IF @ErrCode = 1007
		 SELECT  @ErrMsg = 'At Row = "' + ISNULL(@MatrixError,'') + 
				          '" . The values "' + ISNULL(@ValueError,'') + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) +'.'
		 IF @ErrCode = 1008
		 SELECT  @ErrMsg = 'At Row = "' + ISNULL(@MatrixError,'') + 
				          '" . The values "' + ISNULL(@ValueError,'') + '" is invalid'+'.'

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
	              @ValueError 	= CASE WHEN i.BetType >= 19999 THEN i.BetType
									   WHEN i.EventType NOT BETWEEN 0 AND 5 OR i.EventType IS NULL THEN  i.EventType
									   WHEN  i.RefTable NOT BETWEEN 0 AND 3 OR i.RefTable  IS NULL THEN i.RefTable
								  ELSE i.BetType END,

				  @ErrCode      = CASE WHEN i.BetType >= 19999 THEN 1009
									   WHEN i.EventType NOT BETWEEN 0 AND 5 THEN  1010
									   WHEN  i.RefTable NOT BETWEEN 0 AND 3 THEN  1011
								  ELSE 1012 END
	FROM #input i
		INNER JOIN #input p ON i.BetType = p.BetType
	WHERE i.ProductID <> p.ProductID 
		OR i.RefTable <> p.RefTable 
		OR i.EventType <> p.EventType
	    OR i.BetType >= 19999
		OR i.EventType NOT BETWEEN 0 AND 5	
		OR i.RefTable NOT BETWEEN 0 AND 3
		OR i.EventType  IS NULL
		OR I.RefTable IS NULL
	

	IF @ValueError <> ''
	   BEGIN
	     IF @ErrCode = 1009
		 SELECT @ErrMsg = 'At Row = "' + ISNULL(@MatrixError,'') + '". The values "' + ISNULL(@ValueError,'') + '" is invalid (BetType < 19999).'

		 IF @ErrCode = 1010 
		 SELECT @ErrMsg = 'At Row = "' + ISNULL(@MatrixError,'') + '". The values "' + ISNULL(@ValueError,'') + '" is invalid (EventType between 0 and 5)'

		 IF @ErrCode = 1011 
		 SELECT @ErrMsg = 'At Row = "' + ISNULL(@MatrixError,'') + '". The values "' + ISNULL(@ValueError,'') + '" is invalid (RefTable between 0 and 3)'

		 IF @ErrCode = 1012 
		 SELECT @ErrMsg = 'At Row = "' + ISNULL(@MatrixError,'') + '". The values "' + ISNULL(@ValueError,'') + '" is invalid'

	     RETURN
	   END
	

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