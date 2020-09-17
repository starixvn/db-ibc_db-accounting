/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Bettype_Ins
	@File	    NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserID		INT
AS
/*
Created: 20200328@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200328@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		- 20200917@Danny: NAP Manage Bettype add column LicSpreadBetTypeGroupId [Redmine: #131241]
	Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
						typeid = "14111"
						typenamee= "a"
						typenamec=""
						typedesc= ""
						typenamec_uni=""
						typenamej=""
						typenamcn=""
						typenamecn=""
						typenameth=""
						typenameit=""
						typenameko=""
						typenameES=""
						typenameVN=""
						typenameEL=""
						typenamee_Eu=""
                        typenameRU=""
						typenameID=""
						typenamePT=""
						typenameFR=""
						ParentTypeid="4"
						typenameMMR=""
						typenameHI=""
						DisplayedTypeID="5"	
						LicSpreadBetTypeGroupId="0"
				/>
		</ROOT>	
		
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN


	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @BettypeError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)

	CREATE TABLE #input 
	(    
		ID              INT IDENTITY (1,1),
		typeid          INT,
		typenamee       NVARCHAR(128),
		typenamec		NVARCHAR(128),
		typedesc		NVARCHAR(128),
		typenamec_uni	NVARCHAR(128),
		typenamej		NVARCHAR(128),
		typenamcn		NVARCHAR(128),
		typenamecn		NVARCHAR(128),
		typenameth		NVARCHAR(128),
		typenameit		NVARCHAR(128),
		typenameko		NVARCHAR(128),
		typenameES		NVARCHAR(128),
		typenameVN		NVARCHAR(128),
		typenameEL		NVARCHAR(128),
		typenamee_Eu	NVARCHAR(128),
		typenameRU		NVARCHAR(128),
		typenameID		NVARCHAR(128),
		typenamePT		NVARCHAR(128),
		typenameFR		NVARCHAR(128),
		ParentTypeid	INT,
		typenameMMR		NVARCHAR(128),
		typenameHI		NVARCHAR(128),
		DisplayedTypeID INT,
		LicSpreadBetTypeGroupId TINYINT
		)

	CREATE TABLE #inputTmp
	(    
		ID              INT IDENTITY (1,1),
		typeid          NVARCHAR(MAX),
		typenamee       NVARCHAR(MAX),
		typenamec		NVARCHAR(MAX),
		typedesc		NVARCHAR(MAX),
		typenamec_uni	NVARCHAR(MAX),
		typenamej		NVARCHAR(MAX),
		typenamcn		NVARCHAR(MAX),
		typenamecn		NVARCHAR(MAX),
		typenameth		NVARCHAR(MAX),
		typenameit		NVARCHAR(MAX),
		typenameko		NVARCHAR(MAX),
		typenameES		NVARCHAR(MAX),
		typenameVN		NVARCHAR(MAX),
		typenameEL		NVARCHAR(MAX),
		typenamee_Eu	NVARCHAR(MAX),
		typenameRU		NVARCHAR(MAX),
		typenameID		NVARCHAR(MAX),
		typenamePT		NVARCHAR(MAX),
		typenameFR		NVARCHAR(MAX),
		ParentTypeid	NVARCHAR(MAX),
		typenameMMR		NVARCHAR(MAX),
		typenameHI		NVARCHAR(MAX),
		DisplayedTypeID NVARCHAR(MAX),
		LicSpreadBetTypeGroupId NVARCHAR(MAX)
		)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #inputTmp ( typeid,
							typenamee,
							typenamec,
							typedesc,
							typenamec_uni,
							typenamej,
							typenamcn,
							typenamecn,
							typenameth,
							typenameit,
							typenameko,
							typenameES,
							typenameVN,
							typenameEL,
							typenamee_Eu,
							typenameRU,
							typenameID,
							typenamePT,
							typenameFR,
							ParentTypeid,
							typenameMMR,
							typenameHI,
							DisplayedTypeID,
							LicSpreadBetTypeGroupId)

			SELECT          typeid ,
							typenamee,
							typenamec,
							typedesc,
							typenamec_uni,
							typenamej,
							typenamcn,
							typenamecn,
							typenameth,
							typenameit,
							typenameko,
							typenameES,
							typenameVN,
							typenameEL,
							typenamee_Eu,
							typenameRU,
							typenameID,
							typenamePT,
							typenameFR,
							ParentTypeid,
							typenameMMR,
							typenameHI,
							DisplayedTypeID,
							LicSpreadBetTypeGroupId

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (typeid			NVARCHAR(MAX),
														typenamee		NVARCHAR(MAX),
														typenamec		NVARCHAR(MAX),
														typedesc		NVARCHAR(MAX),
														typenamec_uni	NVARCHAR(MAX),
														typenamej		NVARCHAR(MAX),
														typenamcn		NVARCHAR(MAX),
														typenamecn		NVARCHAR(MAX),
														typenameth		NVARCHAR(MAX),
														typenameit		NVARCHAR(MAX),
														typenameko		NVARCHAR(MAX),
														typenameES		NVARCHAR(MAX),
														typenameVN		NVARCHAR(MAX),
														typenameEL		NVARCHAR(MAX),
														typenamee_Eu	NVARCHAR(MAX),
														typenameRU		NVARCHAR(MAX),
														typenameID		NVARCHAR(MAX),
														typenamePT		NVARCHAR(MAX),
														typenameFR		NVARCHAR(MAX),
														ParentTypeid	NVARCHAR(MAX),
														typenameMMR		NVARCHAR(MAX),
														typenameHI		NVARCHAR(MAX),
														DisplayedTypeID NVARCHAR(MAX),
														LicSpreadBetTypeGroupId NVARCHAR(MAX))
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH
	-- remove row
	DELETE #inputTmp  
	WHERE LEN(typeid)				= 0
	      AND LEN(ParentTypeid)		= 0
		  AND LEN(DisplayedTypeID)	= 0
		  AND LEN(typenamee)		= 0
		  AND LEN(typenamec)		= 0
		  AND LEN(typedesc)			= 0
		  AND LEN(typenamec_uni)	= 0
		  AND LEN(typenamej)		= 0
		  AND LEN(typenamcn)		= 0
		  AND LEN(typenamecn)		= 0
		  AND LEN(typenameth)		= 0
	      AND LEN(typenameit)		= 0
		  AND LEN(typenameko)		= 0
		  AND LEN(typenameES)		= 0
		  AND LEN(typenameVN)		= 0
		  AND LEN(typenameEL)		= 0
		  AND LEN(typenamee_Eu)		= 0
		  AND LEN(typenameRU)		= 0
		  AND LEN(typenameID)		= 0
		  AND LEN(typenamePT)		= 0
		  AND LEN(typenameFR)		= 0
		  AND LEN(typenameMMR)		= 0
		  AND LEN(typenameHI)		= 0
		  AND LEN(LicSpreadBetTypeGroupId)		= 0
   
    UPDATE #inputTmp
	SET typeid					= CASE WHEN LEN(typeid)			= 0 THEN  NULL ELSE typeid			END,
		ParentTypeid			= CASE WHEN LEN(ParentTypeid)		= 0 THEN  NULL ELSE ParentTypeid	END,
		DisplayedTypeID			= CASE WHEN LEN(DisplayedTypeID)	= 0 THEN  NULL ELSE DisplayedTypeID END,
		LicSpreadBetTypeGroupId = CASE WHEN LEN(LicSpreadBetTypeGroupId)	= 0 THEN  NULL ELSE LicSpreadBetTypeGroupId END

	WHERE LEN(typeid)				= 0 
	      OR LEN(ParentTypeid)		= 0
		  OR LEN(DisplayedTypeID)	= 0
		  OR LEN(LicSpreadBetTypeGroupId)= 0

	SELECT TOP(1) @BettypeError = ID, 
	              @ValueError   = CASE WHEN LEN(typenamee)		> 128 THEN typenamee
									   WHEN LEN(typenamec)		> 128 THEN typenamec
									   WHEN LEN(typedesc)		> 128 THEN typedesc
							           WHEN LEN(typenamec_uni)	> 128 THEN typenamec_uni
							           WHEN LEN(typenamej)		> 128 THEN typenamej
							           WHEN LEN(typenamcn)		> 128 THEN TYPENAMECN
									   WHEN LEN(typenamecn)		> 128 THEN typenamecn
									   WHEN LEN(typenameth)		> 128 THEN typenameth
							           WHEN LEN(typenameit)		> 128 THEN typenameit
							           WHEN LEN(typenameko)		> 128 THEN typenameko
							           WHEN LEN(typenameES)		> 128 THEN typenameES
							           WHEN LEN(typenameVN)		> 128 THEN typenameVN
									   WHEN LEN(typenameEL)		> 128 THEN typenameEL
							           WHEN LEN(typenamee_Eu)	> 128 THEN typenamee_Eu
							           WHEN LEN(typenameRU)		> 128 THEN typenameRU
							           WHEN LEN(typenameID)		> 128 THEN typenameID
							           WHEN LEN(typenamePT)		> 128 THEN typenamePT
							           WHEN LEN(typenameFR)		> 128 THEN typenameFR
							           WHEN LEN(typenameMMR)	> 128 THEN typenameMMR
							           ELSE typenameHI END,
				@LimitValue = 128
	FROM #inputTmp
	WHERE LEN(typenamee)		  > 128 
		  OR LEN(typenamec)		  > 128
		  OR LEN(typedesc)		  > 128
		  OR LEN(typenamec_uni)   > 128
		  OR LEN(typenamej)		  > 128
		  OR LEN(typenamcn)		  > 128
		  OR LEN(typenamecn)	  > 128
		  OR LEN(typenameth)	  > 128
	      OR LEN(typenameit)	  > 128
		  OR LEN(typenameko)	  > 128
		  OR LEN(typenameES)	  > 128
		  OR LEN(typenameVN)	  > 128
		  OR LEN(typenameEL)	  > 128
		  OR LEN(typenamee_Eu)	  > 128
		  OR LEN(typenameRU)	  > 128
		  OR LEN(typenameID)	  > 128
		  OR LEN(typenamePT)	  > 128
		  OR LEN(typenameFR)	  > 128
		  OR LEN(typenameMMR)	  > 128
		  OR LEN(typenameHI)	  > 128
							

	IF @ValueError <> ''
	   BEGIN
		 SELECT @ErrCode = 1007, 
		        @ErrMsg = 'Row "' + @BettypeError + 
				           '" - The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) + '.'

	     RETURN
	   END
	   
	BEGIN TRY
		INSERT INTO #input
		(
				typeid,
				typenamee,
				typenamec,
				typedesc,
				typenamec_uni,
				typenamej,
				typenamcn,
				typenamecn,
				typenameth,
				typenameit,
				typenameko,
				typenameES,
				typenameVN,
				typenameEL,
				typenamee_Eu,
				typenameRU,
				typenameID,
				typenamePT,
				typenameFR,
				ParentTypeid,
				typenameMMR,
				typenameHI,
				DisplayedTypeID,
				LicSpreadBetTypeGroupId
		)
		SELECT	typeid,
				typenamee,
				typenamec,
				typedesc,
				typenamec_uni,
				typenamej,
				typenamcn,
				typenamecn,
				typenameth,
				typenameit,
				typenameko,
				typenameES,
				typenameVN,
				typenameEL,
				typenamee_Eu,
				typenameRU,
				typenameID,
				typenamePT,
				typenameFR,
				ParentTypeid,
				typenameMMR,
				typenameHI,
				DisplayedTypeID,
				LicSpreadBetTypeGroupId
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
			INSERT INTO dbo.bettype(typeid,
									creator,
									typenamee,
									typenamec,
									typedesc,
									typenamec_uni,
									typenamej,
									typenamcn,
								    typenamecn,
									typenameth,
									typenameit,
									typenameko,
									typenameES,
									typenameVN,
									typenameEL,
									typenamee_Eu,
								    typenameRU,
									typenameID,
									typenamePT,
									typenameFR,
									ParentTypeid,
									typenameMMR,
									typenameHI,
									DisplayedTypeID,
									LicSpreadBetTypeGroupId)

			SELECT					typeid,
									@UserID,
									typenamee,
									typenamec,
									typedesc,
									typenamec_uni,
									typenamej,
									typenamcn,
									typenamecn,
									typenameth,
									typenameit,
									typenameko,
									typenameES,
									typenameVN,
									typenameEL,
									typenamee_Eu,
									typenameRU,
									typenameID,
									typenamePT,
									typenameFR,
									ParentTypeid,
									typenameMMR,
									typenameHI,
									DisplayedTypeID,
									LicSpreadBetTypeGroupId
			FROM #input
			WHERE ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH 
		

		SELECT @LogSPData =   '<R typeid="'+ COALESCE(CAST(typeid AS VARCHAR(15)), SPACE(1)) + '" ' +
								'DisplayedTypeID="' + COALESCE(CAST(DisplayedTypeID  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'ParentTypeid="' + COALESCE(CAST(ParentTypeid  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'typenamee="' + COALESCE(CAST(typenamee  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenamec="' + COALESCE(CAST(typenamec  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typedesc="' + COALESCE(CAST(typedesc  AS NVARCHAR(128)), SPACE(1)) + '" ' +								
								'typenamec_uni="' + COALESCE(CAST(typenamec_uni  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenamej="' + COALESCE(CAST(typenamej  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenamcn="' + COALESCE(CAST(typenamcn  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenamecn="' + COALESCE(CAST(typenamecn  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameth="' + COALESCE(CAST(typenameth  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameit="' + COALESCE(CAST(typenameit  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameko="' + COALESCE(CAST(typenameko  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameES="' + COALESCE(CAST(typenameES  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameVN="' + COALESCE(CAST(typenameVN  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameEL="' + COALESCE(CAST(typenameEL  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenamee_Eu="' + COALESCE(CAST(typenamee_Eu  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameRU="' + COALESCE(CAST(typenameRU  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameID="' + COALESCE(CAST(typenameID  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenamePT="' + COALESCE(CAST(typenamePT  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameFR="' + COALESCE(CAST(typenameFR  AS NVARCHAR(128)), SPACE(1)) + '" ' +							
								'typenameMMR="' + COALESCE(CAST(typenameMMR  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'typenameHI="' + COALESCE(CAST(typenameHI  AS NVARCHAR(128)), SPACE(1)) + '" ' +
								'LicSpreadBetTypeGroupId="' + COALESCE(CAST(LicSpreadBetTypeGroupId  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
			FROM #input
			WHERE ID = @CurrentRow

			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@ActionID = 95005,
					@TrackingValue = @LogSPData,
					@duration = @duration
	END
	
	DROP TABLE #input
	DROP TABLE #inputTmp
END