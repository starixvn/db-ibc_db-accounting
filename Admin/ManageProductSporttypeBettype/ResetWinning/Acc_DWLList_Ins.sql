/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_DWLList_Ins
	@File	    NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserID		INT,
	@IsTest		BIT
AS
/*
Created: 20200916@Danny
Task :  NAP Manage Reset Winning
DB: DBACC/bodb_ACC
Original:

	Revisions:
		- 20200917@Danny: NAP Manage Reset Winning [Redmine: #131241][Task: #141775]
	Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
						CustID = "6911909"
						Product= "SPL"
						Seq="1"
						ProductID= "1"
						IsDeleted="1"			
				/>
		</ROOT>	
		
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN


	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @DWLListError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT, @ColumnName NVARCHAR(200)

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)

	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		CustID			INT,
		Product			VARCHAR(50),
		Seq				TINYINT,
		ProductID		TINYINT,
		IsDeleted		BIT
	)

	CREATE TABLE #inputTmp
	(    
		ID				INT IDENTITY (1,1),
		CustID          NVARCHAR(MAX),
		Product			NVARCHAR(MAX),
		Seq				NVARCHAR(MAX),
		ProductID		NVARCHAR(MAX),
		IsDeleted		NVARCHAR(MAX)
	)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #inputTmp ( 
							CustID,
							Product,
							Seq,
							ProductID,
							IsDeleted
							)

			SELECT			CustID,
							Product,
							Seq,
							ProductID,
							IsDeleted
			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (CustID		NVARCHAR(MAX),
														Product		NVARCHAR(MAX),
														Seq			NVARCHAR(MAX),
														ProductID	NVARCHAR(MAX),
														IsDeleted	NVARCHAR(MAX)
														)
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH
	-- remove row
	DELETE #inputTmp  
	WHERE LEN(CustID)			= 0
	      AND LEN(Product)		= 0
		  AND LEN(Seq)			= 0
		  AND LEN(ProductID)	= 0
		  AND LEN(IsDeleted)	= 0
		 
   
    UPDATE #inputTmp
	SET CustID		= CASE WHEN LEN(CustID)	= 0 THEN  NULL ELSE CustID	END,
		Seq			= CASE WHEN LEN(Seq) = 0 THEN  NULL ELSE Seq	END,
		ProductID	= CASE WHEN LEN(ProductID) = 0 THEN  NULL ELSE ProductID END,
		IsDeleted	= CASE WHEN LEN(IsDeleted) = 0 THEN  NULL ELSE IsDeleted END
	WHERE LEN(CustID)		= 0 
	      OR LEN(Seq)		= 0
		  OR LEN(ProductID)	= 0
		  OR LEN(IsDeleted)	= 0

	SELECT TOP(1) @DWLListError = CONVERT(VARCHAR(5),ID), 
	              @ValueError   = CASE	WHEN LEN(Product)	> 50 THEN Product END,
				  @LimitValue	= CASE	WHEN LEN(Product)	> 50 THEN 50 END,
				  @ErrCode		= CASE	WHEN LEN(Product)	> 50 THEN 1007 ELSE 1008 END,
				  @ColumnName	= CASE	WHEN IsDeleted IS NULL OR IsDeleted NOT IN (0,1) THEN 'IsDeleted'
										WHEN Seq IS NULL OR Seq NOT BETWEEN 0 AND 255 THEN 'Seq'
										WHEN ProductID IS NULL OR ProductID NOT BETWEEN 0 AND 255 THEN 'ProductID'
										WHEN Product IS NULL OR  LEN(Product)= 0 THEN 'Product'
								  ELSE NULL END
 
	FROM #inputTmp t
	WHERE LEN(Product)	> 50
	OR IsDeleted IS NULL OR IsDeleted NOT IN (0,1)
	OR Seq IS NULL OR Seq NOT BETWEEN 0 AND 255
	OR ProductID IS NULL OR ProductID NOT BETWEEN 0 AND 255
	OR Product IS NULL OR  LEN(Product)= 0
 
	IF @DWLListError <> ''
		BEGIN
			IF @ErrCode = 1007 
			SELECT @ErrMsg = 'Row "' + ISNULL(@DWLListError,'') + 
							'" - The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) + '.'

			IF @ErrCode = 1008
			SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @DWLListError + 
						CASE WHEN @ColumnName = 'IsDeleted'	THEN '"- The values must be IN (0,1)' 
							 WHEN @ColumnName = 'Seq'		THEN '"- The values must be IN (0,255)' 
							 WHEN @ColumnName = 'ProductID'	THEN '"- The values must be IN (0,255)' 
							 WHEN @ColumnName = 'Product'	THEN '"- The values must be not null' 				 
							 ELSE '' END
			RETURN
		END
	ELSE
		BEGIN
			SELECT TOP(1)	@DWLListError = t.ID, 
							@ValueError   =	t.CustID				
			FROM #inputTmp t
			WHERE NOT EXISTS (SELECT 1 FROM bodb02.dbo.Customer cus WITH(NOLOCK) WHERE cus.CustID = t.CustID)
			OR CustID IS NULL OR LEN(CustID) = 0

			IF @DWLListError <> ''
			BEGIN
				SELECT @ErrCode = 1009, 
				@ErrMsg = CASE WHEN @ValueError IS NULL OR LEN(@ValueError) = 0 THEN 'CustID must be not null'
								ELSE 'Row "' + @DWLListError + '" - CustID "' + @ValueError + '" is does not exist in Customer table.' END
				RETURN
			END
			ELSE
			BEGIN
				SELECT TOP(1)	@DWLListError = t.ID, 
								@ValueError   =	t.ProductID				
				FROM #inputTmp t
				WHERE NOT EXISTS (SELECT 1 FROM bodb02.dbo.Products pro WITH(NOLOCK) WHERE pro.ProductID = t.ProductID)

				IF @DWLListError <> ''
				BEGIN
					SELECT @ErrCode = 1010, 
					@ErrMsg = 'Row "' + @DWLListError + 
								'" - ProductID "' + @ValueError + '" is does not exist in Products table.'
					RETURN
				END
			END
		END

	BEGIN TRY
		INSERT INTO #input
		(
				CustID,
				Product,
				Seq,
				ProductID,
				IsDeleted
		)
		SELECT	CustID,
				Product,
				Seq,
				ProductID,
				IsDeleted
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
			IF @IsTest = 0
			BEGIN
				INSERT INTO dbo.Acc_DWLList(CustID,
											Product,
											Seq,
											ProductID,
											IsDeleted)

				SELECT						CustID,
											Product,
											Seq,
											ProductID,
											IsDeleted
				FROM #input
				WHERE ID = @CurrentRow
			END
			
			IF @IsTest = 1
			BEGIN
				INSERT INTO dbo.Acc_DWLList_xtest(CustID,
											Product,
											Seq,
											ProductID,
											IsDeleted)

				SELECT						CustID,
											Product,
											Seq,
											ProductID,
											IsDeleted
				FROM #input
				WHERE ID = @CurrentRow
			END
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH 
		
		SELECT @LogSPData =   '<R CustID="'+ COALESCE(CAST(CustID AS VARCHAR(15)), SPACE(1)) + '" ' +
								'Seq="' + COALESCE(CAST(Seq  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'ProductID="' + COALESCE(CAST(ProductID  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'Product="' + COALESCE(CAST(Product  AS VARCHAR(50)), SPACE(1)) + '" ' +
								'IsDeleted="' + COALESCE(CAST(IsDeleted  AS VARCHAR(3)), SPACE(1)) + '" ' +
								'@IsTest="' + COALESCE(CAST(@IsTest  AS VARCHAR(3)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as NVARCHAR(20)),SPACE(1)) + '" />'
		FROM #input
		WHERE ID = @CurrentRow

		SET @endRun = GETDATE()
		SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95032,
				@TrackingValue = @LogSPData,
				@duration = @duration
	END
	
	DROP TABLE #input
	DROP TABLE #inputTmp
END