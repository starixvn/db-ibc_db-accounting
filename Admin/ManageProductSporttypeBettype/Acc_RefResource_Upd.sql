/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE  dbo.Acc_RefResource_Upd
	@File		NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserID		INT
AS

/*
Created: 20200703@Malcolm
Task :   NAP-Manage RefResource
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200703@Malcolm:  NAP-Manage RefResource [Redmine: #131241]
	Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
					 RefId		  = ""
					 ResourceId	  = ""
					 Resource_en  = ""
					 Resource_ch  = ""
					 Resource_cs  = ""
					 Resource_jp  = ""
					 Resource_it  = ""
					 Resource_th  = ""
					 Resource_ko  = ""
					 Resource_es  = ""
					 Sort1		  = ""
					 Sort2		  = ""
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
		
*/
BEGIN
    SET NOCOUNT ON
	
    IF ISNULL(@File, '') = ''
		RETURN


	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @RefId VARCHAR(20), @ResourceId VARCHAR(20), @RefResourceError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

    DECLARE @startRun DATETIME = GETDATE(), @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	
	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		RefId			VARCHAR(20),		
		ResourceId		VARCHAR(20),		
		Resource_en		NVARCHAR(50),	
		Resource_ch		NVARCHAR(50),	
		Resource_cs		NVARCHAR(50),	
		Resource_jp		NVARCHAR(50),	
		Resource_it		NVARCHAR(50),	
		Resource_th		NVARCHAR(50),	
		Resource_ko		NVARCHAR(50),	
		Resource_es		NVARCHAR(50),	
		Sort1			INT,	
		Sort2			INT,	
		Resource_el		NVARCHAR(50),	
		Resource_vn		NVARCHAR(50),	
		Resource_pl		NVARCHAR(50),	
		Resource_id		NVARCHAR(50),	
		Resource_hi		NVARCHAR(50),	
		Resource_mm		NVARCHAR(50),	
		Resource_fr		NVARCHAR(50),	
		Resource_ru		NVARCHAR(64),	
		Resource_pt		NVARCHAR(50),	
		Resource_de		NVARCHAR(50)	
	)

	CREATE TABLE #inputTmp
	(    
		ID				INT IDENTITY (1,1),
		RefId			NVARCHAR(MAX),
		ResourceId		NVARCHAR(MAX),
		Resource_en		NVARCHAR(MAX),
		Resource_ch		NVARCHAR(MAX),
		Resource_cs		NVARCHAR(MAX),
		Resource_jp		NVARCHAR(MAX),
		Resource_it		NVARCHAR(MAX),
		Resource_th		NVARCHAR(MAX),
		Resource_ko		NVARCHAR(MAX),
		Resource_es		NVARCHAR(MAX),
		Sort1			NVARCHAR(MAX),
		Sort2			NVARCHAR(MAX),
		Resource_el		NVARCHAR(MAX),
		Resource_vn		NVARCHAR(MAX),
		Resource_pl		NVARCHAR(MAX),
		Resource_id		NVARCHAR(MAX),
		Resource_hi		NVARCHAR(MAX),
		Resource_mm		NVARCHAR(MAX),
		Resource_fr		NVARCHAR(MAX),
		Resource_ru		NVARCHAR(MAX),
		Resource_pt		NVARCHAR(MAX),
		Resource_de		NVARCHAR(MAX)
	)

	BEGIN TRY
		  EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
		  INSERT #inputTmp 
		  (
							RefId,		
							ResourceId,
							Resource_en,
							Resource_ch,
							Resource_cs,
							Resource_jp,
							Resource_it,
							Resource_th,
							Resource_ko,
							Resource_es,
							Sort1,		
							Sort2,		
							Resource_el,
							Resource_vn,
							Resource_pl,
							Resource_id,
							Resource_hi,
							Resource_mm,
							Resource_fr,
							Resource_ru,
							Resource_pt,
							Resource_de
			)
			SELECT         	RefId,		
							ResourceId,
							Resource_en,
							Resource_ch,
							Resource_cs,
							Resource_jp,
							Resource_it,
							Resource_th,
							Resource_ko,
							Resource_es,
							Sort1,		
							Sort2,		
							Resource_el,
							Resource_vn,
							Resource_pl,
							Resource_id,
							Resource_hi,
							Resource_mm,
							Resource_fr,
							Resource_ru,
							Resource_pt,
							Resource_de

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (RefId			NVARCHAR(MAX),
														ResourceId		NVARCHAR(MAX),
														Resource_en		NVARCHAR(MAX),
														Resource_ch		NVARCHAR(MAX),
														Resource_cs		NVARCHAR(MAX),
														Resource_jp		NVARCHAR(MAX),
														Resource_it		NVARCHAR(MAX),
														Resource_th		NVARCHAR(MAX),
														Resource_ko		NVARCHAR(MAX),
														Resource_es		NVARCHAR(MAX),
														Sort1			NVARCHAR(MAX),
														Sort2			NVARCHAR(MAX),
														Resource_el		NVARCHAR(MAX),
														Resource_vn		NVARCHAR(MAX),
														Resource_pl		NVARCHAR(MAX),
														Resource_id		NVARCHAR(MAX),
														Resource_hi		NVARCHAR(MAX),
														Resource_mm		NVARCHAR(MAX),
														Resource_fr		NVARCHAR(MAX),
														Resource_ru		NVARCHAR(MAX),
														Resource_pt		NVARCHAR(MAX),
														Resource_de		NVARCHAR(MAX))
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	UPDATE #inputTmp
	SET  RefId		= CASE WHEN LEN(RefId)		 = 0 THEN NULL ELSE  RefId		 END,
	     ResourceId	= CASE WHEN LEN(ResourceId)  = 0 THEN NULL ELSE  ResourceId	 END,
		 Resource_en= CASE WHEN LEN(Resource_en) = 0 THEN NULL ELSE  Resource_en END,
		 Resource_ch= CASE WHEN LEN(Resource_ch) = 0 THEN NULL ELSE  Resource_ch END,
		 Resource_cs= CASE WHEN LEN(Resource_cs) = 0 THEN NULL ELSE  Resource_cs END,
		 Resource_jp= CASE WHEN LEN(Resource_jp) = 0 THEN NULL ELSE  Resource_jp END,
		 Resource_it= CASE WHEN LEN(Resource_it) = 0 THEN NULL ELSE  Resource_it END,
		 Resource_th= CASE WHEN LEN(Resource_th) = 0 THEN NULL ELSE  Resource_th END,
		 Resource_ko= CASE WHEN LEN(Resource_ko) = 0 THEN NULL ELSE  Resource_ko END,
		 Resource_es= CASE WHEN LEN(Resource_es) = 0 THEN NULL ELSE  Resource_es END,
		 Sort1		= CASE WHEN LEN(Sort1)       = 0 THEN NULL ELSE  Sort1		 END,
		 Sort2		= CASE WHEN LEN(Sort2)       = 0 THEN NULL ELSE  Sort2		 END,
		 Resource_el= CASE WHEN LEN(Resource_el) = 0 THEN NULL ELSE  Resource_el END,
		 Resource_vn= CASE WHEN LEN(Resource_vn) = 0 THEN NULL ELSE  Resource_vn END,
		 Resource_pl= CASE WHEN LEN(Resource_pl) = 0 THEN NULL ELSE  Resource_pl END,
		 Resource_id= CASE WHEN LEN(Resource_id) = 0 THEN NULL ELSE  Resource_id END,
		 Resource_hi= CASE WHEN LEN(Resource_hi) = 0 THEN NULL ELSE  Resource_hi END,
		 Resource_mm= CASE WHEN LEN(Resource_mm) = 0 THEN NULL ELSE  Resource_mm END,
		 Resource_fr= CASE WHEN LEN(Resource_fr) = 0 THEN NULL ELSE  Resource_fr END,
		 Resource_ru= CASE WHEN LEN(Resource_ru) = 0 THEN NULL ELSE  Resource_ru END,
		 Resource_pt= CASE WHEN LEN(Resource_pt) = 0 THEN NULL ELSE  Resource_pt END,
		 Resource_de= CASE WHEN LEN(Resource_de) = 0 THEN NULL ELSE  Resource_de END

	WHERE   LEN(RefId)		 = 0 
		 OR LEN(ResourceId)	 = 0 
		 OR LEN(Resource_en) = 0 
		 OR LEN(Resource_ch) = 0 
		 OR LEN(Resource_cs) = 0 
		 OR LEN(Resource_jp) = 0 
		 OR LEN(Resource_it) = 0 
		 OR LEN(Resource_th) = 0 
		 OR LEN(Resource_ko) = 0 
		 OR LEN(Resource_es) = 0 
		 OR LEN(Sort1)		 = 0 
		 OR LEN(Sort2)		 = 0 
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

	SELECT TOP(1) @RefResourceError = ID, 
	              @ValueError = CASE  WHEN LEN(RefId)       > 20 THEN 	RefId
									  WHEN LEN(ResourceId)	> 20 THEN 	ResourceId	
									  WHEN LEN(Resource_en)	> 50 THEN 	Resource_en	
									  WHEN LEN(Resource_ch)	> 50 THEN 	Resource_ch	
									  WHEN LEN(Resource_cs)	> 50 THEN   Resource_cs   
									  WHEN LEN(Resource_jp)	> 50 THEN 	Resource_jp	
									  WHEN LEN(Resource_it)	> 50 THEN 	Resource_it	
									  WHEN LEN(Resource_th)	> 50 THEN   Resource_th 
									  WHEN LEN(Resource_ko)	> 50 THEN 	Resource_ko
									  WHEN LEN(Resource_es)	> 50 THEN 	Resource_es			
									  WHEN LEN(Resource_el)	> 50 THEN 	Resource_el	
									  WHEN LEN(Resource_vn)	> 50 THEN 	Resource_vn	
									  WHEN LEN(Resource_pl)	> 50 THEN 	Resource_pl	
									  WHEN LEN(Resource_id)	> 50 THEN   Resource_id
									  WHEN LEN(Resource_hi)	> 50 THEN 	Resource_hi	
									  WHEN LEN(Resource_mm)	> 50 THEN   Resource_mm
									  WHEN LEN(Resource_fr)	> 50 THEN 	Resource_fr	
									  WHEN LEN(Resource_ru)	> 64 THEN   Resource_ru
									  WHEN LEN(Resource_pt)	> 50 THEN 	Resource_pt	
								ELSE  Resource_de END,

				@LimitValue =   CASE  WHEN LEN(RefId) > 20 OR LEN(ResourceId) > 20 THEN 20
									  WHEN LEN(Resource_ru) > 64 THEN 64
								ELSE 50 END
	FROM #inputTmp
	WHERE	  LEN(RefId)	    > 20
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
		 SELECT @ErrCode = 1007, 
		        @ErrMsg = 'The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) +'.'
	     RETURN
	   END
	   
	BEGIN TRY
		INSERT INTO #input
		(
			    RefId,		
				ResourceId,
				Resource_en,
				Resource_ch,
				Resource_cs,
				Resource_jp,
				Resource_it,
				Resource_th,
				Resource_ko,
				Resource_es,
				Sort1,		
				Sort2,		
				Resource_el,
				Resource_vn,
				Resource_pl,
				Resource_id,
				Resource_hi,
				Resource_mm,
				Resource_fr,
				Resource_ru,
				Resource_pt,
				Resource_de	
	)
		SELECT  RefId,		
				ResourceId,
				Resource_en,
				Resource_ch,
				Resource_cs,
				Resource_jp,
				Resource_it,
				Resource_th,
				Resource_ko,
				Resource_es,
				Sort1,		
				Sort2,		
				Resource_el,
				Resource_vn,
				Resource_pl,
				Resource_id,
				Resource_hi,
				Resource_mm,
				Resource_fr,
				Resource_ru,
				Resource_pt,
				Resource_de

		FROM #inputTmp
	END TRY
	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH


	SELECT @RefId = RefId, @ResourceId = ResourceId FROM #input

	SELECT @LogSPData2 = (SELECT	   RefId       AS '@RefId', 
									   ResourceId  AS '@ResourceId', 
									   Resource_en AS '@Resource_en', 
									   Resource_ch AS '@Resource_ch', 
									   Resource_cs AS '@Resource_cs', 
									   Resource_jp AS '@Resource_jp', 
									   Resource_it AS '@Resource_it', 
									   Resource_th AS '@Resource_th', 
									   Resource_ko AS '@Resource_ko', 
									   Resource_es AS '@Resource_es', 
									   Sort1	   AS '@Sort1', 
									   Sort2       AS '@Sort2', 
									   Resource_el AS '@Resource_el', 
									   Resource_vn AS '@Resource_vn', 
									   Resource_pl AS '@Resource_pl', 
									   Resource_id AS '@Resource_id', 
									   Resource_hi AS '@Resource_hi', 
									   Resource_mm AS '@Resource_mm', 
									   Resource_fr AS '@Resource_fr', 
									   Resource_ru AS '@Resource_ru', 
									   Resource_pt AS '@Resource_pt', 
									   Resource_de AS '@Resource_de', 
									   @LoginIP    AS '@LoginIP'
							 FROM dbo.RefResource WITH(NOLOCK)
							 WHERE RefId = @RefId AND ResourceId = @ResourceId
							 FOR XML PATH('R'))	

		BEGIN TRY
			UPDATE f
			SET f.Resource_en = t.Resource_en,
				f.Resource_ch = t.Resource_ch,
				f.Resource_cs = t.Resource_cs,
				f.Resource_jp = t.Resource_jp,
				f.Resource_it = t.Resource_it,
				f.Resource_th = t.Resource_th,
				f.Resource_ko = t.Resource_ko,
				f.Resource_es = t.Resource_es,
				f.Sort1		  = t.Sort1,
				f.Sort2		  = t.Sort2,
				f.Resource_el = t.Resource_el,
				f.Resource_vn = t.Resource_vn,
				f.Resource_pl = t.Resource_pl,
				f.Resource_id = t.Resource_id,
				f.Resource_hi = t.Resource_hi,
				f.Resource_mm = t.Resource_mm,
				f.Resource_fr = t.Resource_fr,
				f.Resource_ru = t.Resource_ru,
				f.Resource_pt = t.Resource_pt,
				f.Resource_de = t.Resource_de	 
			FROM dbo.RefResource f
				INNER JOIN #input t ON  f.RefId = t.RefId AND f.ResourceId = t.ResourceId		
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH
			     
	    SELECT @LogSPData = (SELECT	   RefId       AS '@RefId', 
									   ResourceId  AS '@ResourceId', 
									   Resource_en AS '@Resource_en', 
									   Resource_ch AS '@Resource_ch', 
									   Resource_cs AS '@Resource_cs', 
									   Resource_jp AS '@Resource_jp', 
									   Resource_it AS '@Resource_it', 
									   Resource_th AS '@Resource_th', 
									   Resource_ko AS '@Resource_ko', 
									   Resource_es AS '@Resource_es', 
									   Sort1	   AS '@Sort1', 
									   Sort2       AS '@Sort2', 
									   Resource_el AS '@Resource_el', 
									   Resource_vn AS '@Resource_vn', 
									   Resource_pl AS '@Resource_pl', 
									   Resource_id AS '@Resource_id', 
									   Resource_hi AS '@Resource_hi', 
									   Resource_mm AS '@Resource_mm', 
									   Resource_fr AS '@Resource_fr', 
									   Resource_ru AS '@Resource_ru', 
									   Resource_pt AS '@Resource_pt', 
									   Resource_de AS '@Resource_de', 
									   @LoginIP    AS '@LoginIP'
							 FROM #input
							 FOR XML PATH('R'))	
		
		SET @endRun = GETDATE()
	    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95029,
				@TrackingValue = @LogSPData,
				@TrackingValue2 = @LogSPData2,
				@duration = @duration

	DROP TABLE #input
	DROP TABLE #inputTmp
END

