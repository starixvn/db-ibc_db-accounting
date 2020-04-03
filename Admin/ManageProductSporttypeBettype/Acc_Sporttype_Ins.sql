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

	IF LEN(@File) > 4000
	   BEGIN
	       SELECT @ErrCode = 1, @ErrMsg = 'The number of characters of file must be smaller than 4000'
		   RETURN
	   END 
   

	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	

	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0

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

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #input (SportType,
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

			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (SportType		SMALLINT,
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
														SportNameHI		NVARCHAR(50))
														
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
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
				@CustID = 0,
				@ActionID = 95007,
				@TrackingValue = @LogSPData,
				@duration = @duration
	END
	DROP TABLE #input
END