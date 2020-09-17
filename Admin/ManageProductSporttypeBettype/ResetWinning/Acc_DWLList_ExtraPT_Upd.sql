/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_DWLList_ExtraPT_Upd
	@File		NVARCHAR(MAX),
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
		- 20200328@Danny: NAP Manage Reset Winning [Redmine: #131241][Task: #141775]
*/


BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN
 
	DECLARE @iDoc INT, 
			@RowTotal INT = 0, 
			@CurrentRow INT = 0, 
			@CustID INT, 
			@DWLListExtraPTError NVARCHAR(MAX) = '', 
			@DWLListExtraPT NVARCHAR(MAX) = '', 
			@ValueError NVARCHAR(MAX) = '', 
			@LimitValue BIGINT

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

			SELECT          CustID,
							GroupID,
							GroupName,
							IsDisabled
			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (CustID			NVARCHAR(MAX),
														GroupID			NVARCHAR(MAX),
														GroupName		NVARCHAR(MAX),
														IsDisabled		NVARCHAR(MAX)
														)
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH

	UPDATE #inputTmp
	SET CustID			= CASE WHEN LEN(CustID)		= 0 THEN  NULL ELSE CustID END,
		GroupID			= CASE WHEN LEN(GroupID)	= 0 THEN  NULL ELSE GroupID	END,
		IsDisabled		= CASE WHEN LEN(IsDisabled)	= 0 THEN  NULL ELSE IsDisabled END
	WHERE LEN(CustID) = 0 OR LEN(GroupID) = 0 OR LEN(IsDisabled) = 0


	SELECT TOP(1) @DWLListExtraPTError =	CAST(CustID AS VARCHAR(15)),
	              @ValueError   =	CASE	WHEN LEN(GroupName)	> 50 THEN GroupName END,
				  @LimitValue	=	CASE	WHEN LEN(GroupName)	> 50 THEN 50 END								
	FROM #inputTmp
	WHERE LEN(GroupName) > 50
							
	IF @ValueError <> ''
	   BEGIN
		 SELECT @ErrCode = 1007, 
		        @ErrMsg = 'Row "' + @DWLListExtraPTError + 
				           '" - The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) + '.'
	     RETURN
	   END
	ELSE
		BEGIN
			SELECT TOP(1)	@DWLListExtraPTError = t.ID, 
							@ValueError   =	t.CustID				
			FROM #inputTmp t
			WHERE NOT EXISTS (SELECT 1 FROM bodb02.dbo.Customer cus WITH(NOLOCK) WHERE cus.CustID = t.CustID)

			IF @ValueError <> ''
			BEGIN
				SELECT @ErrCode = 1008, 
				@ErrMsg = 'Row "' + @DWLListExtraPTError + 
						  '" - CustID "' + @ValueError + '" is does not exist in Customer table.'
				RETURN
			END
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

		SELECT @CustID = CustID
		FROM #input 
		WHERE ID = @CurrentRow

		IF @IsTest = 0
		BEGIN
			SELECT @LogSPData2 =   '<R CustID="'+ COALESCE(CAST(CustID AS VARCHAR(15)), SPACE(1)) + '" ' +
									'GroupID="' + COALESCE(CAST(GroupID  AS VARCHAR(15)), SPACE(1)) + '" ' +
									'GroupName="' + COALESCE(CAST(GroupName  AS VARCHAR(50)), SPACE(1)) + '" ' +
									'IsDisabled="' + COALESCE(CAST(IsDisabled  AS VARCHAR(3)), SPACE(1)) + '" ' +
									'LoginIP="'+ COALESCE(CAST(@LoginIP as NVARCHAR(20)),SPACE(1)) + '" />'
			FROM Acc_DWLList_ExtraPT WITH(NOLOCK)
			WHERE CustID = @CustID 
		END

		IF @IsTest = 1
		BEGIN
			SELECT @LogSPData2 =   '<R CustID="'+ COALESCE(CAST(CustID AS VARCHAR(15)), SPACE(1)) + '" ' +
									'GroupID="' + COALESCE(CAST(GroupID  AS VARCHAR(15)), SPACE(1)) + '" ' +
									'GroupName="' + COALESCE(CAST(GroupName  AS VARCHAR(50)), SPACE(1)) + '" ' +
									'IsDisabled="' + COALESCE(CAST(IsDisabled  AS VARCHAR(3)), SPACE(1)) + '" ' +
									'LoginIP="'+ COALESCE(CAST(@LoginIP as NVARCHAR(20)),SPACE(1)) + '" />'
			FROM Acc_DWLList_ExtraPT_xtest WITH(NOLOCK)
			WHERE CustID = @CustID 
		END

        BEGIN TRY
			IF @IsTest = 0 
			BEGIN
				UPDATE t
				SET 
					t.CustID = i.CustID, 
					t.GroupID = i.GroupID,
					t.GroupName = i.GroupName,
					t.IsDisabled = i.IsDisabled
				FROM Acc_DWLList_ExtraPT t
				INNER JOIN  #input i ON  t.CustID = i.CustID 
				WHERE ID = @CurrentRow
			END

			IF @IsTest = 1 
			BEGIN
				UPDATE t
				SET 
					t.CustID = i.CustID, 
					t.GroupID = i.GroupID,
					t.GroupName = i.GroupName,
					t.IsDisabled = i.IsDisabled
				FROM Acc_DWLList_ExtraPT_xtest t
				INNER JOIN  #input i ON  t.CustID = i.CustID 
				WHERE ID = @CurrentRow
			END


		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
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
				@ActionID = 95035,
				@TrackingValue = @LogSPData	,
				@TrackingValue2 = @LogSPData2,
				@duration = @duration
	END
	DROP TABLE #input
	DROP TABLE #inputTmp
END