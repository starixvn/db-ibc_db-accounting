/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_DWLList_ExtraPT_Ins
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
		- 20200918@Danny: NAP Manage Reset Winning [Redmine: #131241][Task: #141775]
	Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
						CustId		= "37049559"
						GroupId		= "33"
						GroupName=	" CN88_03"
						IsDisabled	= "0"			
				/>
		</ROOT>	
		
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN


	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @DWLListExtraPTError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT, @ColumnName NVARCHAR(200)

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)

	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		CustID			INT,
		GroupID			INT,
		GroupName		VARCHAR(50),
		IsDisabled		BIT
	)

	CREATE TABLE #inputTmp
	(    
		ID				INT IDENTITY (1,1),
		CustID          NVARCHAR(MAX),
		GroupID			NVARCHAR(MAX),
		GroupName		NVARCHAR(MAX),
		IsDisabled		NVARCHAR(MAX)
	)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #inputTmp ( 
							CustID,
							GroupID,
							GroupName,
							IsDisabled
							)

			SELECT			CustID,
							GroupID,
							GroupName,
							IsDisabled
			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (CustID		NVARCHAR(MAX),
														GroupID		NVARCHAR(MAX),
														GroupName	NVARCHAR(MAX),
														IsDisabled	NVARCHAR(MAX)
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
	      AND LEN(GroupID)		= 0
		  AND LEN(GroupName)	= 0
		  AND LEN(IsDisabled)	= 0
		 
    UPDATE #inputTmp
	SET CustID		= CASE WHEN LEN(CustID)	= 0 THEN  NULL ELSE CustID	END,
		GroupID		= CASE WHEN LEN(GroupID) = 0 THEN  NULL ELSE GroupID END,
		IsDisabled	= CASE WHEN LEN(IsDisabled) = 0 THEN  NULL ELSE IsDisabled END
	WHERE LEN(CustID)		= 0 
	      OR LEN(GroupID)	= 0
		  OR LEN(IsDisabled)= 0

	SELECT TOP(1) @DWLListExtraPTError = CONVERT(VARCHAR(5),ID), 
	              @ValueError   =	CASE	WHEN LEN(GroupName)	> 50 THEN GroupName END,
				  @LimitValue	=	CASE	WHEN LEN(GroupName)	> 50 THEN 50 END,
				  @ErrCode		=	CASE	WHEN LEN(GroupName)	> 50 THEN 1007 ELSE 1008 END,
				  @ColumnName	=	CASE	WHEN IsDisabled IS NULL OR IsDisabled NOT IN (0,1) THEN 'IsDisabled'
											WHEN GroupID IS NULL  THEN 'GroupID'
											WHEN GroupName IS NULL OR  LEN(GroupName)= 0 THEN 'GroupName'
								  ELSE NULL END
	FROM #inputTmp
	WHERE LEN(GroupName)	> 50
	OR IsDisabled IS NULL OR IsDisabled NOT IN (0,1)
	OR GroupID IS NULL OR GroupName IS NULL OR LEN(GroupName)= 0
		  
							

	IF @DWLListExtraPTError <> ''
	   BEGIN
			IF @ErrCode = 1007
				SELECT @ErrMsg = 'Row "' + @DWLListExtraPTError + 
							   '" - The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) + '.'
			IF @ErrCode = 1008
				SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @DWLListExtraPTError + 
						CASE WHEN @ColumnName = 'IsDisabled'	THEN '"- The values must be IN (0,1)'  ELSE 'The values must be not null' END
			RETURN
	   END
	ELSE
		BEGIN
			SELECT TOP(1)	@DWLListExtraPTError = CONVERT(VARCHAR(5), t.ID), 
							@ValueError   =	t.CustID				
			FROM #inputTmp t
			WHERE NOT EXISTS (SELECT 1 FROM bodb02.dbo.Customer cus WITH(NOLOCK) WHERE cus.CustID = t.CustID)

			IF @DWLListExtraPTError <> ''
			BEGIN
				SELECT @ErrCode = 1009, 
				@ErrMsg = 'Row "' + @DWLListExtraPTError + 
						  '" - CustID "' + @ValueError + '" is does not exist in Customer table.'
				RETURN
			END
		END
	   
	BEGIN TRY
		INSERT INTO #input
		(
				CustID,
				GroupID,
				GroupName,
				IsDisabled
		)
		SELECT	CustID,
				GroupID,
				GroupName,
				IsDisabled
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
				INSERT INTO dbo.Acc_DWLList_ExtraPT(CustID,GroupID,GroupName,IsDisabled)
				SELECT	CustID,
						GroupID,
						GroupName,
						IsDisabled
				FROM #input
				WHERE ID = @CurrentRow
			END

			IF @IsTest = 1
			BEGIN
				INSERT INTO dbo.Acc_DWLList_ExtraPT_xtest(CustID,GroupID,GroupName,IsDisabled)
				SELECT	CustID,
						GroupID,
						GroupName,
						IsDisabled
				FROM #input
				WHERE ID = @CurrentRow
			END
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH 
		
		SELECT @LogSPData =   '<R CustID="'+ COALESCE(CAST(CustID AS VARCHAR(15)), SPACE(1)) + '" ' +
								'GroupID="' + COALESCE(CAST(GroupID  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'GroupName="' + COALESCE(CAST(GroupName  AS VARCHAR(50)), SPACE(1)) + '" ' +
								'IsDisabled="' + COALESCE(CAST(IsDisabled  AS VARCHAR(3)), SPACE(1)) + '" ' +
								'IsTest="' + COALESCE(CAST(@IsTest  AS VARCHAR(3)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as NVARCHAR(20)),SPACE(1)) + '" />'
		FROM #input
		WHERE ID = @CurrentRow

		SET @endRun = GETDATE()
		SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95034,
				@TrackingValue = @LogSPData,
				@duration = @duration
	END
	
	DROP TABLE #input
	DROP TABLE #inputTmp
END


