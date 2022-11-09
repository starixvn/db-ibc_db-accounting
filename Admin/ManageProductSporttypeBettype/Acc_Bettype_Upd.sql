/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Bettype_Upd
	@File		NVARCHAR(MAX),
	@LoginIP	VARCHAR(20) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserID		INT,
	@IsMultiple BIT = 0
AS
/*
Created: 20200328@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200328@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		- 20200917@Danny: NAP Manage Bettype add column LicSpreadBetTypeGroupId [Redmine: #131241]
		- 20200930@Danny: NAP Manage Bettype add column Is3rdParty [Redmine: #131241]
		- 20211115@Malcolm: Add RepUpdateTime column [Redmine: #164321]
		- 20221025@Eddie: Enhance Bettype Function [Redmine: #178092]
	Param's Explanation:
		- @IsMultiple: 0 - Edit, 1 - Update By Exel
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN
 
	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @Bettype INT, @BettypeError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT, @ColumnName VARCHAR(100)

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)

	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		typeid			INT,
		typenamee		NVARCHAR(128),
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
		LicSpreadBetTypeGroupId TINYINT,
		Is3rdParty		BIT
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
		LicSpreadBetTypeGroupId  NVARCHAR(MAX),
		Is3rdParty		BIT
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
							LicSpreadBetTypeGroupId,
							Is3rdParty)

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
							LicSpreadBetTypeGroupId,
							Is3rdParty

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
														LicSpreadBetTypeGroupId NVARCHAR(MAX),
														Is3rdParty		NVARCHAR(MAX))
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH

	IF @IsMultiple = 0 -- edit
	BEGIN
		UPDATE #inputTmp
		SET typeid			 = CASE WHEN LEN(typeid)			= 0 THEN  NULL ELSE typeid			END,
			ParentTypeid     = CASE WHEN LEN(ParentTypeid)		= 0 THEN  NULL ELSE ParentTypeid	END,
			DisplayedTypeID  = CASE WHEN LEN(DisplayedTypeID)	= 0 THEN  NULL ELSE DisplayedTypeID END,
			LicSpreadBetTypeGroupId = CASE WHEN LEN(LicSpreadBetTypeGroupId)	= 0 THEN  NULL ELSE LicSpreadBetTypeGroupId END,
			Is3rdParty		 = CASE WHEN LEN(Is3rdParty)	= 0 THEN  NULL ELSE Is3rdParty END
		WHERE LEN(typeid) = 0  
			  OR LEN(ParentTypeid) = 0 
			  OR LEN(DisplayedTypeID) = 0 
			  OR LEN(LicSpreadBetTypeGroupId) = 0 
			  OR LEN(Is3rdParty) = 0
	END
	ELSE -- update by excel
	BEGIN 
		
		SELECT @ErrCode = 1009
		FROM #inputTmp it
		WHERE  NOT EXISTS( SELECT 1 FROM bettype t WITH(ROWLOCK) WHERE t.typeid = it.typeid )
		
		IF @ErrCode = 1009
		BEGIN
			SELECT TOP(1) @ErrMsg = 'Bet Type: ' + ISNULL(it.typeid, '') + ' does not exist in the system.'
			FROM #inputTmp it
			WHERE  NOT EXISTS( SELECT 1 FROM bettype t WITH(ROWLOCK) WHERE t.typeid = it.typeid)
			RETURN
		END
		
		UPDATE it
		SET it.typeid		 = t.typeid,
		    it.typenamee	 = CASE WHEN ISNULL(it.typenamee,   '') = '' THEN t.typenamee  ELSE it.typenamee END,
		    it.typenamec	 = CASE WHEN ISNULL(it.typenamec,   '') = '' THEN t.typenamec  ELSE it.typenamec END,
		    it.typedesc		 = CASE WHEN ISNULL(it.typedesc,    '') = '' THEN t.typedesc   ELSE it.typedesc END,
		    it.typenamec_uni = CASE WHEN ISNULL(it.typenamec_uni,'') = '' THEN t.typenamec_uni  ELSE it.typenamec_uni END,
		    it.typenamej     = CASE WHEN ISNULL(it.typenamej,   '') = '' THEN t.typenamej  ELSE it.typenamej END,
		    it.typenamcn     = CASE WHEN ISNULL(it.typenamcn,   '') = '' THEN t.typenamcn  ELSE it.typenamcn END,
		    it.typenamecn    = CASE WHEN ISNULL(it.typenamecn,  '') = '' THEN t.typenamecn ELSE it.typenamecn END,
		    it.typenameth    = CASE WHEN ISNULL(it.typenameth,  '') = '' THEN t.typenameth ELSE it.typenameth END,
		    it.typenameit    = CASE WHEN ISNULL(it.typenameit,  '') = '' THEN t.typenameit ELSE it.typenameit END,
		    it.typenameko    = CASE WHEN ISNULL(it.typenameko,  '') = '' THEN t.typenameko ELSE it.typenameko END,
		    it.typenameES    = CASE WHEN ISNULL(it.typenameES,  '') = '' THEN t.typenameES ELSE it.typenameES END,
		    it.typenameVN    = CASE WHEN ISNULL(it.typenameVN,  '') = '' THEN t.typenameVN ELSE it.typenameVN END,
		    it.typenameEL    = CASE WHEN ISNULL(it.typenameEL,  '') = '' THEN t.typenameEL ELSE it.typenameEL END,
		    it.typenamee_Eu  = CASE WHEN ISNULL(it.typenamee_Eu,'') = '' THEN t.typenamee_Eu ELSE it.typenamee_Eu END,
		    it.typenameRU    = CASE WHEN ISNULL(it.typenameRU,  '') = '' THEN t.typenameRU ELSE it.typenameRU END,
		    it.typenameID    = CASE WHEN ISNULL(it.typenameID,  '') = '' THEN t.typenameID ELSE it.typenameID END,
		    it.typenamePT    = CASE WHEN ISNULL(it.typenamePT,  '') = '' THEN t.typenamePT ELSE it.typenamePT END,
		    it.typenameFR    = CASE WHEN ISNULL(it.typenameFR,  '') = '' THEN t.typenameFR ELSE it.typenameFR END,
		    it.ParentTypeid  = CASE WHEN ISNULL(it.ParentTypeid,'') = '' THEN t.ParentTypeid ELSE it.ParentTypeid END,
		    it.typenameMMR   = CASE WHEN ISNULL(it.typenameMMR, '') = '' THEN t.typenameMMR ELSE it.typenameMMR END,
		    it.typenameHI    = CASE WHEN ISNULL(it.typenameHI,  '') = '' THEN t.typenameHI ELSE it.typenameHI END,
		    it.DisplayedTypeID	= CASE WHEN ISNULL(it.DisplayedTypeID,'') = '' THEN t.DisplayedTypeID ELSE it.DisplayedTypeID END,
		    it.LicSpreadBetTypeGroupId = CASE WHEN ISNULL(it.LicSpreadBetTypeGroupId,'') = '' THEN t.LicSpreadBetTypeGroupId ELSE it.LicSpreadBetTypeGroupId END,
		    it.Is3rdParty	 = CASE WHEN ISNULL(it.Is3rdParty,  '') = '' THEN t.Is3rdParty ELSE it.Is3rdParty END
		FROM bettype t WITH(ROWLOCK)
			INNER JOIN #inputTmp it ON t.typeid = it.typeid  
		WHERE (ISNULL(it.typenamee,    '') = '')
		   OR (ISNULL(it.typenamec,    '') = '')
		   OR (ISNULL(it.typedesc,     '') = '')
		   OR (ISNULL(it.typenamec_uni,'') = '')
		   OR (ISNULL(it.typenamej,    '') = '')
		   OR (ISNULL(it.typenamcn,    '') = '')
		   OR (ISNULL(it.typenamecn,   '') = '')
		   OR (ISNULL(it.typenameth,   '') = '')
		   OR (ISNULL(it.typenameit,   '') = '')
		   OR (ISNULL(it.typenameko,   '') = '')
		   OR (ISNULL(it.typenameES,   '') = '')
		   OR (ISNULL(it.typenameVN,   '') = '')
		   OR (ISNULL(it.typenameEL,   '') = '')
		   OR (ISNULL(it.typenamee_Eu, '') = '')
		   OR (ISNULL(it.typenameRU,   '') = '')
		   OR (ISNULL(it.typenameID,   '') = '')
		   OR (ISNULL(it.typenamePT,   '') = '')
		   OR (ISNULL(it.typenameFR,   '') = '')
		   OR (ISNULL(it.ParentTypeid, '') = '')
		   OR (ISNULL(it.typenameMMR,  '') = '')
		   OR (ISNULL(it.typenameHI,   '') = '')
		   OR (ISNULL(it.DisplayedTypeID, '') = '')
		   OR (ISNULL(it.LicSpreadBetTypeGroupId,'') = '')
		   OR (ISNULL(it.Is3rdParty,   '') = '')
	END

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
							           WHEN LEN(typenameHI)  	> 128 THEN typenameHI
							           ELSE '' END,
				@LimitValue = 128,
				@ErrCode	= CASE WHEN LicSpreadBetTypeGroupId IS NULL
											  OR LicSpreadBetTypeGroupId NOT BETWEEN 0 AND 255
											  OR Is3rdParty IS NULL
											  OR Is3rdParty NOT IN (0,1) THEN 1008 ELSE 1007 END,
				@ColumnName = CASE WHEN LicSpreadBetTypeGroupId IS NULL OR LicSpreadBetTypeGroupId NOT BETWEEN 0 AND 255 THEN 'LicSpreadBetTypeGroupId'
								   WHEN Is3rdParty IS NULL OR Is3rdParty NOT IN (0,1) THEN 'Is3rdParty' ELSE NULL END
	FROM #inputTmp
		WHERE LEN(typenamee)	  > 128 
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
		  OR LicSpreadBetTypeGroupId IS NULL
		  OR LicSpreadBetTypeGroupId NOT BETWEEN 0 AND 255
		  OR Is3rdParty IS NULL
		  OR Is3rdParty NOT IN (0,1)
							
	IF (@ValueError <> '' OR @ErrCode <> 0)
	BEGIN
		IF @ErrCode = 1007
			SELECT @ErrMsg = 'Row ' + @BettypeError + 
							' - The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) + '.'
		IF @ErrCode = 1008
			SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @BettypeError + '".Please check them again.'

		RETURN
	END
	   
	BEGIN TRY
		INSERT INTO #input
		(
				typeid
				,typenamee
				,typenamec
				,typedesc
				,typenamec_uni
				,typenamej
				,typenamcn
				,typenamecn
				,typenameth
				,typenameit
				,typenameko
				,typenameES
				,typenameVN
				,typenameEL
				,typenamee_Eu
				,typenameRU
				,typenameID
				,typenamePT
				,typenameFR
				,ParentTypeid
				,typenameMMR
				,typenameHI
				,DisplayedTypeID
				,LicSpreadBetTypeGroupId
				,Is3rdParty
		)
		SELECT	typeid
			    ,typenamee
			    ,typenamec
			    ,typedesc
			    ,typenamec_uni
			    ,typenamej
			    ,typenamcn
			    ,typenamecn
			    ,typenameth
			    ,typenameit
			    ,typenameko
			    ,typenameES
			    ,typenameVN
			    ,typenameEL
			    ,typenamee_Eu
			    ,typenameRU
			    ,typenameID
			    ,typenamePT
			    ,typenameFR
			    ,ParentTypeid
			    ,typenameMMR
			    ,typenameHI
			    ,DisplayedTypeID
			    ,LicSpreadBetTypeGroupId
			    ,Is3rdParty
		FROM #inputTmp
	END TRY

	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow = @CurrentRow + 1, @startRun = GETDATE();

		SELECT @Bettype = typeid
		FROM #input 
		WHERE ID = @CurrentRow

		SELECT @LogSPData2 =   '<R typeid="'+ COALESCE(CAST(typeid AS VARCHAR(15)), SPACE(1)) + '" ' +
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
								'Is3rdParty="' + COALESCE(CAST(Is3rdParty  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as NVARCHAR(20)),SPACE(1)) + '" />'
			FROM bettype WITH(NOLOCK)
			WHERE typeid = @Bettype

        BEGIN TRY
			UPDATE t
			SET t.typeid          = i.typeid,
				t.typenamee		  = i.typenamee,
				t.typenamec		  = i.typenamec,
				t.typedesc	      = i.typedesc,				
				t.typenamec_uni   = i.typenamec_uni,
				t.typenamej       = i.typenamej,
				t.typenamcn		  = i.typenamcn,
				t.typenamecn	  = i.typenamecn,
				t.typenameth	  = i.typenameth,
				t.typenameit	  = i.typenameit,
				t.typenameko	  = i.typenameko,
				t.typenameES	  = i.typenameES,
				t.typenameVN	  = i.typenameVN,
				t.typenameEL	  = i.typenameEL,
				t.typenamee_Eu    = i.typenamee_Eu,
				t.typenameRU	  = i.typenameRU,
				t.typenameID	  = i.typenameID,
				t.typenamePT	  = i.typenamePT,
				t.typenameFR	  = i.typenameFR,
				t.ParentTypeid	  = i.ParentTypeid,
				t.typenameMMR	  = i.typenameMMR,
				t.typenameHI	  = i.typenameHI,
				t.DisplayedTypeID = i.DisplayedTypeID,
				t.LicSpreadBetTypeGroupId = i.LicSpreadBetTypeGroupId,
				t.Is3rdParty	  = i.Is3rdParty,
				t.RepUpdateTime   = SYSDATETIME()
			FROM bettype t WITH(ROWLOCK)
				INNER JOIN  #input i ON  t.typeid = i.typeid
			WHERE ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
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
								'Is3rdParty="' + COALESCE(CAST(Is3rdParty  AS VARCHAR(15)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as NVARCHAR(20)),SPACE(1)) + '" />'
			FROM #input
			WHERE ID = @CurrentRow

			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@ActionID = 95006,
					@TrackingValue = @LogSPData	,
					@TrackingValue2 = @LogSPData2,
					@duration = @duration
	END
	DROP TABLE #input
	DROP TABLE #inputTmp
END