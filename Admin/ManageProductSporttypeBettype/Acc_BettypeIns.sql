/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_BettypeIns
	@File			VARCHAR(MAX),
	@LoginIP VARCHAR(20)='',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT,
	@UserID INT
AS
/*
Created: 20200328@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200328@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
	Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
						typeid = "14111"
						typenamee= "a"
						typenamec=""
						typedesc= ""
						creator=""
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
				/>
		</ROOT>	
		
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN

	DECLARE @iDoc	 INT,
			@RowTotal INT = 0,
			@CurrentRow INT = 0

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)

	CREATE TABLE #input 
	(    
		ID INT identity (1,1),
		typeid int,
		typenamee nvarchar(128),
		typenamec nvarchar(128),
		typedesc nvarchar(128),
		creator int,
		typenamec_uni nvarchar,
		typenamej nvarchar(128),
		typenamcn nvarchar(128) ,
		typenamecn nvarchar(128),
		typenameth nvarchar(128) ,
		typenameit nvarchar(128) ,
		typenameko nvarchar(128) ,
		typenameES nvarchar(128),
		typenameVN nvarchar(128),
		typenameEL nvarchar(128) ,
		typenamee_Eu nvarchar(128) ,
		typenameRU nvarchar(128) ,
		typenameID nvarchar(128) ,
		typenamePT nvarchar(128) ,
		typenameFR nvarchar(128) ,
		ParentTypeid int,
		typenameMMR nvarchar(128),
		typenameHI nvarchar(128) ,
		DisplayedTypeID int
		)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #input ( typeid ,typenamee,typenamec,typedesc,creator,typenamec_uni,typenamej,typenamcn,
							typenamecn,typenameth,typenameit,typenameko,typenameES,typenameVN,typenameEL,typenamee_Eu,
							typenameRU,typenameID,typenamePT,typenameFR,ParentTypeid,typenameMMR,typenameHI,DisplayedTypeID)

			SELECT typeid ,typenamee,typenamec,typedesc,creator,typenamec_uni,typenamej,typenamcn,
				   typenamecn,typenameth,typenameit,typenameko,typenameES,typenameVN,typenameEL,typenamee_Eu,
				   typenameRU,typenameID,typenamePT,typenameFR,ParentTypeid,typenameMMR,typenameHI,DisplayedTypeID

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (typeid int,
														typenamee nvarchar(128),
														typenamec nvarchar(128),
														typedesc nvarchar(128),
														creator int,
														typenamec_uni nvarchar,
														typenamej nvarchar(128),
														typenamcn nvarchar(128) ,
														typenamecn nvarchar(128),
														typenameth nvarchar(128) ,
														typenameit nvarchar(128) ,
														typenameko nvarchar(128) ,
														typenameES nvarchar(128),
														typenameVN nvarchar(128),
														typenameEL nvarchar(128) ,
														typenamee_Eu nvarchar(128) ,
														typenameRU nvarchar(128) ,
														typenameID nvarchar(128) ,
														typenamePT nvarchar(128) ,
														typenameFR nvarchar(128) ,
														ParentTypeid int,
														typenameMMR nvarchar(128),
														typenameHI nvarchar(128) ,
														DisplayedTypeID int)
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH

	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE();

		BEGIN TRY
			INSERT INTO dbo.bettype( typeid ,typenamee,typenamec,typedesc,creator,typenamec_uni,typenamej,typenamcn,
								     typenamecn,typenameth,typenameit,typenameko,typenameES,typenameVN,typenameEL,typenamee_Eu,
								     typenameRU,typenameID,typenamePT,typenameFR,ParentTypeid,typenameMMR,typenameHI,DisplayedTypeID)
			SELECT  typeid ,typenamee,typenamec,typedesc,creator,typenamec_uni,typenamej,typenamcn,
					typenamecn,typenameth,typenameit,typenameko,typenameES,typenameVN,typenameEL,typenamee_Eu,
					typenameRU,typenameID,typenamePT,typenameFR,ParentTypeid,typenameMMR,typenameHI,DisplayedTypeID
			FROM #input
			WHERE ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH 
		

		SELECT @LogSPData =   '<R typeid="'+ COALESCE(CAST(typeid AS VARCHAR(40)), SPACE(1)) + '" ' +
								'typenamee="' + COALESCE(CAST(typenamee  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenamec="' + COALESCE(CAST(typenamec  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typedesc="' + COALESCE(CAST(typedesc  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'creator="' + COALESCE(CAST(creator  AS VARCHAR(40)), SPACE(1)) + '" ' +
								'typenamec_uni="' + COALESCE(CAST(typenamec_uni  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenamej="' + COALESCE(CAST(typenamej  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenamcn="' + COALESCE(CAST(typenamcn  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenamecn="' + COALESCE(CAST(typenamecn  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameth="' + COALESCE(CAST(typenameth  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameit="' + COALESCE(CAST(typenameit  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameko="' + COALESCE(CAST(typenameko  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameES="' + COALESCE(CAST(typenameES  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameVN="' + COALESCE(CAST(typenameVN  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameEL="' + COALESCE(CAST(typenameEL  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenamee_Eu="' + COALESCE(CAST(typenamee_Eu  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameRU="' + COALESCE(CAST(typenameRU  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameID="' + COALESCE(CAST(typenameID  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenamePT="' + COALESCE(CAST(typenamePT  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameFR="' + COALESCE(CAST(typenameFR  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'ParentTypeid="' + COALESCE(CAST(ParentTypeid  AS VARCHAR(40)), SPACE(1)) + '" ' +
								'typenameMMR="' + COALESCE(CAST(typenameMMR  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameHI="' + COALESCE(CAST(typenameHI  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'DisplayedTypeID="' + COALESCE(CAST(DisplayedTypeID  AS VARCHAR(40)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
			FROM #input
			WHERE ID = @CurrentRow

			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@CustID = 0,
					@ActionID = 95005,
					@TrackingValue = @LogSPData	,
					@duration = @duration
	END
	
	DROP TABLE #input
END