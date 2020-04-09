/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Sporttype_Ins
	@File		NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserId		INT
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
					SportType = "1" SportName = "m" SportNameCh = "" SportNameCs = "" SportNameJp = "" SportNameIt= ""
					SportNameTh = "" ParlayMaxPayout ="" SportNameKo = "" SportNameES = "" SportNameVN = "" SportNameEL = ""
					SportNameRU  = "" SportNameID  = "" SportNamePT = "" SportNameFR = "" SportNameMMR  = "" SportNamePL = "" SportNameHI =""			
				/>
		</ROOT>	
		
*/
BEGIN
    SET NOCOUNT ON
	
	IF ISNULL(@File, '') = ''
			RETURN

   

	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	

	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @SportError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT

	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		SportType		SMALLINT,
		SportName		NVARCHAR(50),
		SportNameCh		NVARCHAR(50),
		SportNameCs		NVARCHAR(50),
		SportNameJp		NVARCHAR(50),
		SportNameIt		NVARCHAR(50),
		SportNameTh		NVARCHAR(50),
		ParlayMaxPayout INT,
		SportNameKo		NVARCHAR(50),
		SportNameES		NVARCHAR(50),
		SportNameVN		NVARCHAR(50),
		SportNameEL		NVARCHAR(50),
		SportNameRU		NVARCHAR(50),
		SportNameID		NVARCHAR(50),
		SportNamePT		NVARCHAR(50),
		SportNameFR		NVARCHAR(50),
		SportNameMMR	NVARCHAR(50),
		SportNamePL		NVARCHAR(50),
		SportNameHI		NVARCHAR(50)
	)

	CREATE TABLE #inputTmp
	(    
		SportType		NVARCHAR(MAX),
		SportName		NVARCHAR(MAX),
		SportNameCh		NVARCHAR(MAX),
		SportNameCs		NVARCHAR(MAX),
		SportNameJp		NVARCHAR(MAX),
		SportNameIt		NVARCHAR(MAX),
		SportNameTh		NVARCHAR(MAX),
		ParlayMaxPayout NVARCHAR(MAX),
		SportNameKo		NVARCHAR(MAX),
		SportNameES		NVARCHAR(MAX),
		SportNameVN		NVARCHAR(MAX),
		SportNameEL		NVARCHAR(MAX),
		SportNameRU		NVARCHAR(MAX),
		SportNameID		NVARCHAR(MAX),
		SportNamePT		NVARCHAR(MAX),
		SportNameFR		NVARCHAR(MAX),
		SportNameMMR	NVARCHAR(MAX),
		SportNamePL		NVARCHAR(MAX),
		SportNameHI		NVARCHAR(MAX)
	)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
		  INSERT #inputTmp (SportType,
						   SportName,
						   SportNameCh,
						   SportNameCs,
						   SportNameJp,
						   SportNameIt,
						   SportNameTh,
						   ParlayMaxPayout,
						   SportNameKo,
						   SportNameES,
						   SportNameVN,
						   SportNameEL,
						   SportNameRU,
						   SportNameID,
						   SportNamePT,
						   SportNameFR,
						   SportNameMMR,
						   SportNamePL,
						   SportNameHI)

			SELECT         SportType,
						   SportName,
						   SportNameCh,
						   SportNameCs,
						   SportNameJp,
						   SportNameIt,
						   SportNameTh,
						   ParlayMaxPayout,
						   SportNameKo,
						   SportNameES,
						   SportNameVN,
						   SportNameEL,
						   SportNameRU,
						   SportNameID,
						   SportNamePT,
						   SportNameFR,
						   SportNameMMR,
						   SportNamePL,
						   SportNameHI

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (SportType		NVARCHAR(MAX),
														SportName		NVARCHAR(MAX),
														SportNameCh		NVARCHAR(MAX),
														SportNameCs		NVARCHAR(MAX),
														SportNameJp		NVARCHAR(MAX),
														SportNameIt		NVARCHAR(MAX),
														SportNameTh		NVARCHAR(MAX),
														ParlayMaxPayout NVARCHAR(MAX),
														SportNameKo		NVARCHAR(MAX),
														SportNameES		NVARCHAR(MAX),
														SportNameVN		NVARCHAR(MAX),
														SportNameEL		NVARCHAR(MAX),
														SportNameRU		NVARCHAR(MAX),
														SportNameID		NVARCHAR(MAX),
														SportNamePT		NVARCHAR(MAX),
														SportNameFR		NVARCHAR(MAX),
														SportNameMMR	NVARCHAR(MAX),
														SportNamePL		NVARCHAR(MAX),
														SportNameHI		NVARCHAR(MAX))
														
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	DELETE #inputTmp
	WHERE  LEN(SportName)		    = 0
		   AND LEN(SportNameCh)		= 0
		   AND LEN(SportNameCs)		= 0
		   AND LEN(SportNameJp)		= 0
		   AND LEN(SportNameIt)		= 0
		   AND LEN(SportNameTh)		= 0
		   AND LEN(SportNameKo)		= 0
		   AND LEN(SportNameES)		= 0
		   AND LEN(SportNameVN)		= 0
		   AND LEN(SportNameEL)		= 0
		   AND LEN(SportNameRU)		= 0
		   AND LEN(SportNameID)		= 0
		   AND LEN(SportNamePT)		= 0
		   AND LEN(SportNameFR)		= 0
		   AND LEN(SportNameMMR)    = 0
		   AND LEN(SportNamePL)		= 0
		   AND LEN(SportNameHI)		= 0
		   AND LEN(SportType)       = 0
		   AND LEN(ParlayMaxPayout) = 0

	SELECT TOP(1) @SportError = SportType, 
	              @ValueError = CASE  WHEN LEN(SportName)	> 50 THEN SportName			
								  WHEN LEN(SportNameCh)		> 50 THEN SportNameCh		
								  WHEN LEN(SportNameCs)		> 50 THEN SportNameCs		
								  WHEN LEN(SportNameJp)		> 50 THEN SportNameJp		
								  WHEN LEN(SportNameIt)		> 50 THEN SportNameIt      
								  WHEN LEN(SportNameTh)		> 50 THEN SportNameTh		
								  WHEN LEN(SportNameKo)		> 50 THEN SportNameKo		
								  WHEN LEN(SportNameES)		> 50 THEN SportNameES      
								  WHEN LEN(SportNameVN)		> 50 THEN SportNameVN		
								  WHEN LEN(SportNameEL)		> 50 THEN SportNameEL		
								  WHEN LEN(SportNameRU)		> 50 THEN SportNameRU		
								  WHEN LEN(SportNameID)		> 50 THEN SportNameID		
								  WHEN LEN(SportNamePT)		> 50 THEN SportNamePT		
								  WHEN LEN(SportNameFR)		> 50 THEN SportNameFR		
								  WHEN LEN(SportNameMMR)	> 50 THEN SportNameMMR		
								  WHEN LEN(SportNamePL)		> 50 THEN SportNamePL
								  WHEN LEN(SportType)	    = 0  THEN 'SportType'
								  WHEN LEN(ParlayMaxPayout)	= 0  THEN 'ParlayMaxPayout'
								  ELSE SportNameHI  END,

				@LimitValue =     50
	FROM #inputTmp
	WHERE  LEN(SportName)		    > 50
		   OR LEN(SportNameCh)		> 50
		   OR LEN(SportNameCs)		> 50
		   OR LEN(SportNameJp)		> 50
		   OR LEN(SportNameIt)		> 50
		   OR LEN(SportNameTh)		> 50
		   OR LEN(SportNameKo)		> 50
		   OR LEN(SportNameES)		> 50
		   OR LEN(SportNameVN)		> 50
		   OR LEN(SportNameEL)		> 50
		   OR LEN(SportNameRU)		> 50
		   OR LEN(SportNameID)		> 50
		   OR LEN(SportNamePT)		> 50
		   OR LEN(SportNameFR)		> 50
		   OR LEN(SportNameMMR)		> 50
		   OR LEN(SportNamePL)		> 50
		   OR LEN(SportNameHI)		> 50
		   OR LEN(SportType)        = 0
		   OR LEN(ParlayMaxPayout)  = 0

	IF @ValueError <> ''
	   BEGIN
	     IF @ValueError NOT IN('SportType','ParlayMaxPayout')
		 SELECT @ErrCode = 1007, 
		        @ErrMsg = 'At Sporttype = ' + @SportError + 
				           ' . The values "' + @ValueError + '" is exceeded max length ' + CONVERT(VARCHAR(8),@LimitValue) +'.'
		 ELSE
		 SELECT @ErrCode = 1007,
				@ErrMsg = 'At bettype = ' + @SportError + 
				           ' . the value of "' + @ValueError +'" column must be different from "".'
	     RETURN
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
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE()

		BEGIN TRY
			INSERT INTO dbo.Sports(SportType,
								   SportName,
								   SportNameCh,
								   SportNameCs,
								   SportNameJp,
								   SportNameIt,
								   SportNameTh,
								   ParlayMaxPayout,
								   SportNameKo,
								   SportNameES,
								   SportNameVN,
								   SportNameEL,
							       SportNameRU,
								   SportNameID,
								   SportNamePT,
								   SportNameFR,
								   SportNameMMR,
								   SportNamePL,
								   SportNameHI)
			
			SELECT                 SportType,
			                       SportName,
								   SportNameCh,
								   SportNameCs,
								   SportNameJp,
								   SportNameIt,
					               SportNameTh,
								   ParlayMaxPayout,
								   SportNameKo,
								   SportNameES,
								   SportNameVN,
								   SportNameEL,
					               SportNameRU,
								   SportNameID,
								   SportNamePT,
								   SportNameFR,
								   SportNameMMR,
								   SportNamePL,
								   SportNameHI
			FROM #input
			WHERE ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
			RETURN
		END CATCH
		
		SELECT @LogSPData = '<R SportType="'+ COALESCE(CAST(SportType AS VARCHAR(6)), SPACE(1)) + '" ' +
		                    'ParlayMaxPayout="' + COALESCE(CAST(ParlayMaxPayout  AS VARCHAR(15)), SPACE(1)) + '" ' +
		                    'SportName="' + COALESCE(CAST(SportName   AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameCh="' + COALESCE(CAST(SportNameCh  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameCs="' + COALESCE(CAST(SportNameCs  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameJp="' + COALESCE(CAST(SportNameJp  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameIt="' + COALESCE(CAST(SportNameIt  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameTh="' + COALESCE(CAST(SportNameTh  AS NVARCHAR(50)), SPACE(1)) + '" ' +							
							'SportNameKo="' + COALESCE(CAST(SportNameKo  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameES="' + COALESCE(CAST(SportNameES  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameVN="' + COALESCE(CAST(SportNameVN  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameEL="' + COALESCE(CAST(SportNameEL  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameRU="' + COALESCE(CAST(SportNameRU  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameID="' + COALESCE(CAST(SportNameID  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNamePT="' + COALESCE(CAST(SportNamePT  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameFR="' + COALESCE(CAST(SportNameFR  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameMMR="' + COALESCE(CAST(SportNameMMR  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNamePL="' + COALESCE(CAST(SportNamePL  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameHI="' + COALESCE(CAST(SportNameHI  AS NVARCHAR(50)), SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM #input
		WHERE ID = @CurrentRow

		SET @endRun = GETDATE()
	    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95007,
				@TrackingValue = @LogSPData,
				@duration = @duration
	END
	DROP TABLE #input
	DROP TABLE #inputTmp
END