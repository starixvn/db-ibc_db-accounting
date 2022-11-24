/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE  dbo.Acc_RefResource_Upd
	@File		 NVARCHAR(MAX)
	,@LoginIP	 VARCHAR(20) = ''
	,@ErrCode	 INT = 0 OUTPUT
	,@ErrMsg	 NVARCHAR(4000) = '' OUTPUT
	,@UserID	 INT
	,@IsMultiple BIT = 0
AS

/*
Created: 20200703@Malcolm
Task :   NAP-Manage RefResource
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200703@Malcolm:  NAP-Manage RefResource [Redmine: #131241]
		- 20211115@Malcolm: Add RepUpdateTime column [Redmine: #164321]
		- 20221118@Eddie: Enhance RefResource Function  [RedmineId: #180381]
	Param's Explanation:
	- @Fie:		
		<ROOT>
			<File 
				RefId		 = ""
				ResourceId	 = ""
				Resource_en  = ""
				Resource_ch  = ""
				Resource_cs  = ""
				Resource_jp  = ""
				Resource_it  = ""
				Resource_th  = ""
				Resource_ko  = ""
				Resource_es  = ""
				Sort1		 = ""
				Sort2		 = ""
				Resource_el  = ""
				Resource_vn  = ""
				Resource_pl  = ""
				Resource_id  = ""
				Resource_hi  = ""
				Resource_mm  = ""
				Resource_fr  = ""
				Resource_ru  = ""
				Resource_pt  = ""
				Resource_de  = ""
			/>
		</ROOT>	
	- @IsMultiple: 0 - Edit, 1 - Update By Excel
*/
BEGIN
    SET NOCOUNT ON
	
    IF ISNULL(@File, '') = ''
		RETURN

	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @RefId VARCHAR(20), @ResourceId VARCHAR(20), @RefResourceError INT = 0, @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

    DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	
	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1)
		,RefId			VARCHAR(20)	
		,ResourceId		VARCHAR(20)	
		,Resource_en	NVARCHAR(50)
		,Resource_ch	NVARCHAR(50)
		,Resource_cs	NVARCHAR(50)
		,Resource_jp	NVARCHAR(50)
		,Resource_it	NVARCHAR(50)
		,Resource_th	NVARCHAR(50)
		,Resource_ko	NVARCHAR(50)
		,Resource_es	NVARCHAR(50)
		,Sort1			INT
		,Sort2			INT
		,Resource_el	NVARCHAR(50)
		,Resource_vn	NVARCHAR(50)
		,Resource_pl	NVARCHAR(50)
		,Resource_id	NVARCHAR(50)
		,Resource_hi	NVARCHAR(50)
		,Resource_mm	NVARCHAR(50)
		,Resource_fr	NVARCHAR(50)
		,Resource_ru	NVARCHAR(64)
		,Resource_pt	NVARCHAR(50)
		,Resource_de	NVARCHAR(50)
	)

	CREATE TABLE #inputTmp
	(    
		ID				INT IDENTITY (1,1)
		,RefId			NVARCHAR(MAX)
		,ResourceId		NVARCHAR(MAX)
		,Resource_en	NVARCHAR(MAX)
		,Resource_ch	NVARCHAR(MAX)
		,Resource_cs	NVARCHAR(MAX)
		,Resource_jp	NVARCHAR(MAX)
		,Resource_it	NVARCHAR(MAX)
		,Resource_th	NVARCHAR(MAX)
		,Resource_ko	NVARCHAR(MAX)
		,Resource_es	NVARCHAR(MAX)
		,Sort1			NVARCHAR(MAX)
		,Sort2			NVARCHAR(MAX)
		,Resource_el	NVARCHAR(MAX)
		,Resource_vn	NVARCHAR(MAX)
		,Resource_pl	NVARCHAR(MAX)
		,Resource_id	NVARCHAR(MAX)
		,Resource_hi	NVARCHAR(MAX)
		,Resource_mm	NVARCHAR(MAX)
		,Resource_fr	NVARCHAR(MAX)
		,Resource_ru	NVARCHAR(MAX)
		,Resource_pt	NVARCHAR(MAX)
		,Resource_de	NVARCHAR(MAX)
	)

	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
		INSERT #inputTmp 
		(
				RefId	
				,ResourceId
				,Resource_en
				,Resource_ch
				,Resource_cs
				,Resource_jp
				,Resource_it
				,Resource_th
				,Resource_ko
				,Resource_es
				,Sort1
				,Sort2
				,Resource_el
				,Resource_vn
				,Resource_pl
				,Resource_id
				,Resource_hi
				,Resource_mm
				,Resource_fr
				,Resource_ru
				,Resource_pt
				,Resource_de
		)
		SELECT  RefId
				,ResourceId
				,Resource_en
				,Resource_ch
				,Resource_cs
				,Resource_jp
				,Resource_it
				,Resource_th
				,Resource_ko
				,Resource_es
				,Sort1
				,Sort2
				,Resource_el
				,Resource_vn
				,Resource_pl
				,Resource_id
				,Resource_hi
				,Resource_mm
				,Resource_fr
				,Resource_ru
				,Resource_pt
				,Resource_de
		FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (RefId			NVARCHAR(MAX)
													,ResourceId		NVARCHAR(MAX)
													,Resource_en	NVARCHAR(MAX)
													,Resource_ch	NVARCHAR(MAX)
													,Resource_cs	NVARCHAR(MAX)
													,Resource_jp	NVARCHAR(MAX)
													,Resource_it	NVARCHAR(MAX)
													,Resource_th	NVARCHAR(MAX)
													,Resource_ko	NVARCHAR(MAX)
													,Resource_es	NVARCHAR(MAX)
													,Sort1			NVARCHAR(MAX)
													,Sort2			NVARCHAR(MAX)
													,Resource_el	NVARCHAR(MAX)
													,Resource_vn	NVARCHAR(MAX)
													,Resource_pl	NVARCHAR(MAX)
													,Resource_id	NVARCHAR(MAX)
													,Resource_hi	NVARCHAR(MAX)
													,Resource_mm	NVARCHAR(MAX)
													,Resource_fr	NVARCHAR(MAX)
													,Resource_ru	NVARCHAR(MAX)
													,Resource_pt	NVARCHAR(MAX)
													,Resource_de	NVARCHAR(MAX))
		EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	IF @IsMultiple = 0 -- edit
	BEGIN
		UPDATE #inputTmp
		SET RefId		 = CASE WHEN LEN(RefId)		  = 0 THEN NULL ELSE RefId		 END
			,ResourceId	 = CASE WHEN LEN(ResourceId)  = 0 THEN NULL ELSE ResourceId	 END
			,Resource_en = CASE WHEN LEN(Resource_en) = 0 THEN NULL ELSE Resource_en END
			,Resource_ch = CASE WHEN LEN(Resource_ch) = 0 THEN NULL ELSE Resource_ch END
			,Resource_cs = CASE WHEN LEN(Resource_cs) = 0 THEN NULL ELSE Resource_cs END
			,Resource_jp = CASE WHEN LEN(Resource_jp) = 0 THEN NULL ELSE Resource_jp END
			,Resource_it = CASE WHEN LEN(Resource_it) = 0 THEN NULL ELSE Resource_it END
			,Resource_th = CASE WHEN LEN(Resource_th) = 0 THEN NULL ELSE Resource_th END
			,Resource_ko = CASE WHEN LEN(Resource_ko) = 0 THEN NULL ELSE Resource_ko END
			,Resource_es = CASE WHEN LEN(Resource_es) = 0 THEN NULL ELSE Resource_es END
			,Sort1		 = CASE WHEN LEN(Sort1)       = 0 THEN NULL ELSE Sort1		 END
			,Sort2		 = CASE WHEN LEN(Sort2)       = 0 THEN NULL ELSE Sort2		 END
			,Resource_el = CASE WHEN LEN(Resource_el) = 0 THEN NULL ELSE Resource_el END
			,Resource_vn = CASE WHEN LEN(Resource_vn) = 0 THEN NULL ELSE Resource_vn END
			,Resource_pl = CASE WHEN LEN(Resource_pl) = 0 THEN NULL ELSE Resource_pl END
			,Resource_id = CASE WHEN LEN(Resource_id) = 0 THEN NULL ELSE Resource_id END
			,Resource_hi = CASE WHEN LEN(Resource_hi) = 0 THEN NULL ELSE Resource_hi END
			,Resource_mm = CASE WHEN LEN(Resource_mm) = 0 THEN NULL ELSE Resource_mm END
			,Resource_fr = CASE WHEN LEN(Resource_fr) = 0 THEN NULL ELSE Resource_fr END
			,Resource_ru = CASE WHEN LEN(Resource_ru) = 0 THEN NULL ELSE Resource_ru END
			,Resource_pt = CASE WHEN LEN(Resource_pt) = 0 THEN NULL ELSE Resource_pt END
			,Resource_de = CASE WHEN LEN(Resource_de) = 0 THEN NULL ELSE Resource_de END
		WHERE  LEN(RefId)		= 0 
			OR LEN(ResourceId)	= 0 
			OR LEN(Resource_en) = 0 
			OR LEN(Resource_ch) = 0 
			OR LEN(Resource_cs) = 0 
			OR LEN(Resource_jp) = 0 
			OR LEN(Resource_it) = 0 
			OR LEN(Resource_th) = 0 
			OR LEN(Resource_ko) = 0 
			OR LEN(Resource_es) = 0 
			OR LEN(Sort1)		= 0 
			OR LEN(Sort2)		= 0 
			OR LEN(Resource_el) = 0 
			OR LEN(Resource_vn) = 0 
			OR LEN(Resource_pl) = 0 
			OR LEN(Resource_id) = 0 
			OR LEN(Resource_hi) = 0 
			OR LEN(Resource_mm) = 0 
			OR LEN(Resource_fr) = 0 
			OR LEN(Resource_ru) = 0 
			OR LEN(Resource_pt) = 0 
			OR LEN(Resource_de) = 0
	END
	ELSE -- Update By Excel
	BEGIN
		SELECT @ErrCode = 1009
		FROM #inputTmp it
		WHERE NOT EXISTS( SELECT 1 FROM dbo.RefResource rr WITH(ROWLOCK) WHERE rr.RefId = it.RefId AND rr.ResourceId = it.ResourceId)
		
		IF @ErrCode = 1009
		BEGIN
			SELECT TOP(1) @ErrMsg = 'RefID: ' + ISNULL(it.RefId, '') + ' - ResourceID: ' + ISNULL(it.ResourceId, '') + ' does not exist in the system.'
			FROM #inputTmp it
			WHERE NOT EXISTS( SELECT 1 FROM dbo.RefResource rr WITH(ROWLOCK) WHERE rr.RefId = it.RefId AND rr.ResourceId = it.ResourceId)
			RETURN
		END
		
		UPDATE it
		SET it.RefId		 = rr.RefId
			,it.ResourceId	 = rr.ResourceId
		    ,it.Resource_en	 = CASE WHEN ISNULL(it.Resource_en, '') = '' THEN rr.Resource_en ELSE it.Resource_en END
		    ,it.Resource_ch	 = CASE WHEN ISNULL(it.Resource_ch, '') = '' THEN rr.Resource_ch ELSE it.Resource_ch END
		    ,it.Resource_cs	 = CASE WHEN ISNULL(it.Resource_cs, '') = '' THEN rr.Resource_cs ELSE it.Resource_cs END
		    ,it.Resource_jp	 = CASE WHEN ISNULL(it.Resource_jp, '') = '' THEN rr.Resource_jp ELSE it.Resource_jp END
		    ,it.Resource_it	 = CASE WHEN ISNULL(it.Resource_it, '') = '' THEN rr.Resource_it ELSE it.Resource_it END
		    ,it.Resource_th	 = CASE WHEN ISNULL(it.Resource_th, '') = '' THEN rr.Resource_th ELSE it.Resource_th END
		    ,it.Resource_ko	 = CASE WHEN ISNULL(it.Resource_ko, '') = '' THEN rr.Resource_ko ELSE it.Resource_ko END
		    ,it.Resource_es	 = CASE WHEN ISNULL(it.Resource_es, '') = '' THEN rr.Resource_es ELSE it.Resource_es END
		    ,it.Sort1     	 = CASE WHEN ISNULL(it.Sort1,       '') = '' THEN rr.Sort1       ELSE it.Sort1       END
		    ,it.Sort2     	 = CASE WHEN ISNULL(it.Sort2,       '') = '' THEN rr.Sort2       ELSE it.Sort2       END
		    ,it.Resource_el	 = CASE WHEN ISNULL(it.Resource_el, '') = '' THEN rr.Resource_el ELSE it.Resource_el END
		    ,it.Resource_vn	 = CASE WHEN ISNULL(it.Resource_vn, '') = '' THEN rr.Resource_vn ELSE it.Resource_vn END
		    ,it.Resource_pl	 = CASE WHEN ISNULL(it.Resource_pl, '') = '' THEN rr.Resource_pl ELSE it.Resource_pl END
		    ,it.Resource_id	 = CASE WHEN ISNULL(it.Resource_id, '') = '' THEN rr.Resource_id ELSE it.Resource_id END
		    ,it.Resource_hi	 = CASE WHEN ISNULL(it.Resource_hi, '') = '' THEN rr.Resource_hi ELSE it.Resource_hi END
		    ,it.Resource_mm	 = CASE WHEN ISNULL(it.Resource_mm, '') = '' THEN rr.Resource_mm ELSE it.Resource_mm END
		    ,it.Resource_fr	 = CASE WHEN ISNULL(it.Resource_fr, '') = '' THEN rr.Resource_fr ELSE it.Resource_fr END
		    ,it.Resource_ru	 = CASE WHEN ISNULL(it.Resource_ru, '') = '' THEN rr.Resource_ru ELSE it.Resource_ru END
		    ,it.Resource_pt	 = CASE WHEN ISNULL(it.Resource_pt, '') = '' THEN rr.Resource_pt ELSE it.Resource_pt END
		    ,it.Resource_de	 = CASE WHEN ISNULL(it.Resource_de, '') = '' THEN rr.Resource_de ELSE it.Resource_de END
		FROM dbo.RefResource rr WITH(ROWLOCK)
			INNER JOIN #inputTmp it ON it.RefId = rr.RefId AND it.ResourceId = rr.ResourceId 
		WHERE (ISNULL(it.Resource_en, '') = '')
		   OR (ISNULL(it.Resource_ch, '') = '')
		   OR (ISNULL(it.Resource_cs, '') = '')
		   OR (ISNULL(it.Resource_jp, '') = '')
		   OR (ISNULL(it.Resource_it, '') = '')
		   OR (ISNULL(it.Resource_th, '') = '')
		   OR (ISNULL(it.Resource_ko, '') = '')
		   OR (ISNULL(it.Resource_es, '') = '')
		   OR (ISNULL(it.Sort1,       '') = '')
		   OR (ISNULL(it.Sort2,       '') = '')
		   OR (ISNULL(it.Resource_el, '') = '')
		   OR (ISNULL(it.Resource_vn, '') = '')
		   OR (ISNULL(it.Resource_pl, '') = '')
		   OR (ISNULL(it.Resource_id, '') = '')
		   OR (ISNULL(it.Resource_hi, '') = '')
		   OR (ISNULL(it.Resource_mm, '') = '')
		   OR (ISNULL(it.Resource_fr, '') = '')
		   OR (ISNULL(it.Resource_ru, '') = '')
		   OR (ISNULL(it.Resource_pt, '') = '')
		   OR (ISNULL(it.Resource_de, '') = '')
	END

	SELECT TOP(1) @RefResourceError = ID, 
	              @ValueError = CASE WHEN LEN(RefId)        > 20 THEN RefId
									 WHEN LEN(ResourceId)	> 20 THEN ResourceId	
									 WHEN LEN(Resource_en)	> 50 THEN Resource_en	
									 WHEN LEN(Resource_ch)	> 50 THEN Resource_ch	
									 WHEN LEN(Resource_cs)	> 50 THEN Resource_cs   
									 WHEN LEN(Resource_jp)	> 50 THEN Resource_jp	
									 WHEN LEN(Resource_it)	> 50 THEN Resource_it	
									 WHEN LEN(Resource_th)	> 50 THEN Resource_th 
									 WHEN LEN(Resource_ko)	> 50 THEN Resource_ko
									 WHEN LEN(Resource_es)	> 50 THEN Resource_es		
									 WHEN LEN(Resource_el)	> 50 THEN Resource_el	
									 WHEN LEN(Resource_vn)	> 50 THEN Resource_vn	
									 WHEN LEN(Resource_pl)	> 50 THEN Resource_pl	
									 WHEN LEN(Resource_id)	> 50 THEN Resource_id
									 WHEN LEN(Resource_hi)	> 50 THEN Resource_hi	
									 WHEN LEN(Resource_mm)	> 50 THEN Resource_mm
									 WHEN LEN(Resource_fr)	> 50 THEN Resource_fr	
									 WHEN LEN(Resource_ru)	> 64 THEN Resource_ru
									 WHEN LEN(Resource_pt)	> 50 THEN Resource_pt	
									 WHEN LEN(Resource_de)	> 50 THEN Resource_de	
									 ELSE '' END,
				  @LimitValue = CASE WHEN LEN(RefId) > 20 OR LEN(ResourceId) > 20 THEN 20
									 WHEN LEN(Resource_ru) > 64 THEN 64
									 ELSE 50 END
	FROM #inputTmp
	WHERE LEN(RefId)	    > 20
		OR LEN(ResourceId)	> 20
		OR LEN(Resource_en)	> 50
		OR LEN(Resource_ch)	> 50
		OR LEN(Resource_cs)	> 50
		OR LEN(Resource_jp)	> 50
		OR LEN(Resource_it)	> 50
		OR LEN(Resource_th)	> 50
		OR LEN(Resource_ko)	> 50
		OR LEN(Resource_es)	> 50
		OR LEN(Resource_el)	> 50
		OR LEN(Resource_vn)	> 50
		OR LEN(Resource_pl)	> 50
		OR LEN(Resource_id)	> 50
		OR LEN(Resource_hi)	> 50
		OR LEN(Resource_mm)	> 50
		OR LEN(Resource_fr)	> 50
		OR LEN(Resource_ru)	> 64
		OR LEN(Resource_pt)	> 50
		OR LEN(Resource_de)	> 50

	IF @ValueError <> ''
	BEGIN
		IF @IsMultiple = 1 
		BEGIN
			SELECT @ErrCode = 1007, 
				   @ErrMsg = 'Row "' + CONVERT(VARCHAR(10),@RefResourceError) + '" - The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) + '.'
		END
		ELSE
		BEGIN
			SELECT @ErrCode = 1007, 
				   @ErrMsg = 'The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) + '.'
		END
	    RETURN
	END
	   
	BEGIN TRY
		INSERT INTO #input
		(
			    RefId
				,ResourceId
				,Resource_en
				,Resource_ch
				,Resource_cs
				,Resource_jp
				,Resource_it
				,Resource_th
				,Resource_ko
				,Resource_es
				,Sort1
				,Sort2
				,Resource_el
				,Resource_vn
				,Resource_pl
				,Resource_id
				,Resource_hi
				,Resource_mm
				,Resource_fr
				,Resource_ru
				,Resource_pt
				,Resource_de
		)
		SELECT  RefId	
				,ResourceId
				,Resource_en
				,Resource_ch
				,Resource_cs
				,Resource_jp
				,Resource_it
				,Resource_th
				,Resource_ko
				,Resource_es
				,Sort1
				,Sort2
				,Resource_el
				,Resource_vn
				,Resource_pl
				,Resource_id
				,Resource_hi
				,Resource_mm
				,Resource_fr
				,Resource_ru
				,Resource_pt
				,Resource_de
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
	
		SELECT @RefId = RefId, @ResourceId = ResourceId 
		FROM #input
		WHERE ID = @CurrentRow

		SELECT @LogSPData2 = (SELECT RefId        AS '@RefId'
									,ResourceId   AS '@ResourceId'
									,Resource_en  AS '@Resource_en'
									,Resource_ch  AS '@Resource_ch'
									,Resource_cs  AS '@Resource_cs'
									,Resource_jp  AS '@Resource_jp'
									,Resource_it  AS '@Resource_it'
									,Resource_th  AS '@Resource_th'
									,Resource_ko  AS '@Resource_ko'
									,Resource_es  AS '@Resource_es'
									,Sort1	      AS '@Sort1'
									,Sort2        AS '@Sort2' 
									,Resource_el  AS '@Resource_el'
									,Resource_vn  AS '@Resource_vn'
									,Resource_pl  AS '@Resource_pl'
									,Resource_id  AS '@Resource_id'
									,Resource_hi  AS '@Resource_hi'
									,Resource_mm  AS '@Resource_mm'
									,Resource_fr  AS '@Resource_fr'
									,Resource_ru  AS '@Resource_ru'
									,Resource_pt  AS '@Resource_pt'
									,Resource_de  AS '@Resource_de'
									,@LoginIP     AS '@LoginIP'
						      FROM dbo.RefResource WITH(NOLOCK)
						      WHERE RefId = @RefId AND ResourceId = @ResourceId
						      FOR XML PATH('R'))	
		BEGIN TRY
			UPDATE f
			SET f.Resource_en    = t.Resource_en
				,f.Resource_ch   = t.Resource_ch
				,f.Resource_cs   = t.Resource_cs
				,f.Resource_jp   = t.Resource_jp
				,f.Resource_it   = t.Resource_it
				,f.Resource_th   = t.Resource_th
				,f.Resource_ko   = t.Resource_ko
				,f.Resource_es   = t.Resource_es
				,f.Sort1	     = t.Sort1
				,f.Sort2	     = t.Sort2
				,f.Resource_el   = t.Resource_el
				,f.Resource_vn   = t.Resource_vn
				,f.Resource_pl   = t.Resource_pl
				,f.Resource_id   = t.Resource_id
				,f.Resource_hi   = t.Resource_hi
				,f.Resource_mm   = t.Resource_mm
				,f.Resource_fr   = t.Resource_fr
				,f.Resource_ru   = t.Resource_ru
				,f.Resource_pt   = t.Resource_pt
				,f.Resource_de   = t.Resource_de 
				,f.RepUpdateTime = SYSDATETIME()
			FROM dbo.RefResource f WITH(ROWLOCK)
				INNER JOIN #input t ON  f.RefId = t.RefId AND f.ResourceId = t.ResourceId
			WHERE t.ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH
			     
	    SELECT @LogSPData = (SELECT	RefId        AS '@RefId'
									,ResourceId  AS '@ResourceId'
									,Resource_en AS '@Resource_en'
									,Resource_ch AS '@Resource_ch'
									,Resource_cs AS '@Resource_cs'
									,Resource_jp AS '@Resource_jp'
									,Resource_it AS '@Resource_it'
									,Resource_th AS '@Resource_th'
									,Resource_ko AS '@Resource_ko'
									,Resource_es AS '@Resource_es'
									,Sort1	     AS '@Sort1'
									,Sort2       AS '@Sort2'
									,Resource_el AS '@Resource_el'
									,Resource_vn AS '@Resource_vn'
									,Resource_pl AS '@Resource_pl'
									,Resource_id AS '@Resource_id'
									,Resource_hi AS '@Resource_hi'
									,Resource_mm AS '@Resource_mm'
									,Resource_fr AS '@Resource_fr'
									,Resource_ru AS '@Resource_ru'
									,Resource_pt AS '@Resource_pt'
									,Resource_de AS '@Resource_de'
									,@LoginIP    AS '@LoginIP'
							FROM #input
							WHERE ID = @CurrentRow
							FOR XML PATH('R'))
							
		SET @endRun   = GETDATE()
	    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID
			,@ActionID = 95029
			,@TrackingValue = @LogSPData
			,@TrackingValue2 = @LogSPData2
			,@duration = @duration
	END
	DROP TABLE #input
	DROP TABLE #inputTmp
END

