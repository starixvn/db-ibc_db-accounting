/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_BettypeUpd
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
		
*/

BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN

	DECLARE @iDoc	 INT,
			@RowTotal INT = 0,
			@CurrentRow INT = 0,
			@Bettype INT

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
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE();

		SELECT @Bettype = typeid
		FROM #input 
		WHERE ID = @CurrentRow

		SELECT @LogSPData2 =   '<R typeid="'+ COALESCE(CAST(typeid AS VARCHAR(40)), SPACE(1)) + '" ' +
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
								'typenameFR="' + COALESCE(CAST(typenameFR  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'ParentTypeid="' + COALESCE(CAST(ParentTypeid  AS VARCHAR(40)), SPACE(1)) + '" ' +
								'typenameMMR="' + COALESCE(CAST(typenameMMR  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'typenameHI="' + COALESCE(CAST(typenameHI  AS VARCHAR(128)), SPACE(1)) + '" ' +
								'DisplayedTypeID="' + COALESCE(CAST(DisplayedTypeID  AS VARCHAR(40)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
			FROM bettype WITH(NOLOCK)
			WHERE typeid = @Bettype

        BEGIN TRY
			UPDATE t
			SET t.typeid          = i.typeid,
				t.typenamee		  = i.typenamee,
				t.typenamec		  = i.typenamec,
				t.typedesc	      = i.typedesc,
				t.creator		  = i.creator,
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
				t.DisplayedTypeID = i.DisplayedTypeID
			FROM bettype t
				INNER JOIN  #input i ON  t.typeid = i.typeid
			WHERE ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
			RETURN
		END CATCH
		

		SELECT @LogSPData =   '<R typeid="'+ COALESCE(CAST(typeid AS VARCHAR(4)), SPACE(1)) + '" ' +
								'typenamee="' + COALESCE(CAST(typenamee  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenamec="' + COALESCE(CAST(typenamec  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typedesc="' + COALESCE(CAST(typedesc  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'creator="' + COALESCE(CAST(creator  AS VARCHAR(4)), SPACE(1)) + '" ' +
								'typenamec_uni="' + COALESCE(CAST(typenamec_uni  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenamej="' + COALESCE(CAST(typenamej  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenamcn="' + COALESCE(CAST(typenamcn  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenamecn="' + COALESCE(CAST(typenamecn  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameth="' + COALESCE(CAST(typenameth  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameit="' + COALESCE(CAST(typenameit  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameko="' + COALESCE(CAST(typenameko  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameES="' + COALESCE(CAST(typenameES  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameVN="' + COALESCE(CAST(typenameVN  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameEL="' + COALESCE(CAST(typenameEL  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenamee_Eu="' + COALESCE(CAST(typenamee_Eu  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameRU="' + COALESCE(CAST(typenameRU  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameID="' + COALESCE(CAST(typenameID  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenamePT="' + COALESCE(CAST(typenamePT  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameFR="' + COALESCE(CAST(typenameFR  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'ParentTypeid="' + COALESCE(CAST(ParentTypeid  AS VARCHAR(4)), SPACE(1)) + '" ' +
								'typenameMMR="' + COALESCE(CAST(typenameMMR  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'typenameHI="' + COALESCE(CAST(typenameHI  AS VARCHAR(256)), SPACE(1)) + '" ' +
								'DisplayedTypeID="' + COALESCE(CAST(DisplayedTypeID  AS VARCHAR(4)), SPACE(1)) + '" ' +
								'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
			FROM #input
			WHERE ID = @CurrentRow

			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@CustID = 0,
					@ActionID = 95006,
					@TrackingValue = @LogSPData	,
					@TrackingValue2 = @LogSPData2,
					@duration = @duration
	END
	DROP TABLE #input
END