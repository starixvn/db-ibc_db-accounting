/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_SporttypeUpd
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
			@Sporttype tinyint = 0

    DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	
	CREATE TABLE #input 
	(    
		ID INT identity (1,1),
		SportType tinyint ,
		SportName nvarchar(50) ,
		SportNameCh nvarchar(50) ,
		SportNameCs nvarchar(50) ,
		SportNameJp nvarchar(50) ,
		SportNameIt nvarchar(50) ,
		SportNameTh nvarchar(50) ,
		ParlayMaxPayout int ,
		SportNameKo nvarchar(50) ,
		SportNameES nvarchar(50) ,
		SportNameVN nvarchar(50) ,
		SportNameEL nvarchar(50) ,
		SportNameRU nvarchar(50) ,
		SportNameID nvarchar(50) ,
		SportNamePT nvarchar(50) ,
		SportNameFR nvarchar(50) ,
		SportNameMMR nvarchar(50) ,
		SportNamePL nvarchar(50) ,
		SportNameHI nvarchar(50) 
	)

	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
		INSERT #input ( SportType ,SportName ,SportNameCh ,SportNameCs ,SportNameJp ,SportNameIt ,
		                SportNameTh  ,ParlayMaxPayout ,SportNameKo ,SportNameES ,SportNameVN ,SportNameEL ,
						SportNameRU  ,SportNameID  ,SportNamePT ,SportNameFR ,SportNameMMR ,SportNamePL ,SportNameHI)

		SELECT SportType ,SportName ,SportNameCh ,SportNameCs ,SportNameJp ,SportNameIt ,
		       SportNameTh  ,ParlayMaxPayout ,SportNameKo ,SportNameES ,SportNameVN ,SportNameEL ,
			   SportNameRU  ,SportNameID  ,SportNamePT ,SportNameFR ,SportNameMMR ,SportNamePL ,SportNameHI

		FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (SportType tinyint ,
													SportName nvarchar(50) ,
													SportNameCh nvarchar(50) ,
													SportNameCs nvarchar(50) ,
													SportNameJp nvarchar(50) ,
													SportNameIt nvarchar(50) ,
													SportNameTh nvarchar(50) ,
													ParlayMaxPayout int ,
													SportNameKo nvarchar(50) ,
													SportNameES nvarchar(50) ,
													SportNameVN nvarchar(50) ,
													SportNameEL nvarchar(50) ,
													SportNameRU nvarchar(50) ,
													SportNameID nvarchar(50) ,
													SportNamePT nvarchar(50) ,
													SportNameFR nvarchar(50) ,
													SportNameMMR nvarchar(50) ,
													SportNamePL nvarchar(50) ,
													SportNameHI nvarchar(50))
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	SELECT  @RowTotal = COUNT(*) FROM #input

	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE()

		SELECT @Sporttype = SportType FROM #input WHERE ID = @CurrentRow

		SELECT @LogSPData2 = '<R SportType="'+ COALESCE(CAST(SportType AS VARCHAR(40)), SPACE(1)) + '" ' +
		                    'SportName="' + COALESCE(CAST(SportName   AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameCh="' + COALESCE(CAST(SportNameCh  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameCs="' + COALESCE(CAST(SportNameCs  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameJp="' + COALESCE(CAST(SportNameJp  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameIt="' + COALESCE(CAST(SportNameIt  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameTh="' + COALESCE(CAST(SportNameTh  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ParlayMaxPayout="' + COALESCE(CAST(ParlayMaxPayout  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameKo="' + COALESCE(CAST(SportNameKo  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameES="' + COALESCE(CAST(SportNameES  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameVN="' + COALESCE(CAST(SportNameVN  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameEL="' + COALESCE(CAST(SportNameEL  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameRU="' + COALESCE(CAST(SportNameRU  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameID="' + COALESCE(CAST(SportNameID  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNamePT="' + COALESCE(CAST(SportNamePT  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameFR="' + COALESCE(CAST(SportNameFR  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameMMR="' + COALESCE(CAST(SportNameMMR  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNamePL="' + COALESCE(CAST(SportNamePL  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameHI="' + COALESCE(CAST(SportNameHI  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM Sports WITH(NOLOCK)
		WHERE SportType = @Sporttype

		BEGIN TRY
			UPDATE f
			SET f.SportName       = t.SportName,
				f.SportNameCh     = t.SportNameCh,
				f.SportNameCs     = t.SportNameCs,
				f.SportNameJp     = t.SportNameJp,
				f.SportNameIt     = t.SportNameIt,
				f.SportNameTh     = t.SportNameTh,
				f.ParlayMaxPayout = t.ParlayMaxPayout ,
				f.SportNameKo	  = t.SportNameKo,
				f.SportNameES     = t.SportNameES,
				f.SportNameVN     = t.SportNameVN,
				f.SportNameEL     = t.SportNameEL,
				f.SportNameRU     = t.SportNameRU,
				f.SportNameID     = t.SportNameID,
				f.SportNamePT     = t.SportNamePT,
				f.SportNameFR     = t.SportNameFR,
				f.SportNameMMR    = t.SportNameMMR, 
				f.SportNamePL     = t.SportNamePL,
				f.SportNameHI     = t.SportNameHI 
			FROM Sports f
				INNER JOIN #input t ON  f.SportType = t.SportType		
	   	    WHERE t.ID = @CurrentRow
		END TRY

		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		    RETURN
		END CATCH
		
		     
	    SELECT @LogSPData = '<R SportType="'+ COALESCE(CAST(SportType AS VARCHAR(40)), SPACE(1)) + '" ' +
		                    'SportName="' + COALESCE(CAST(SportName   AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameCh="' + COALESCE(CAST(SportNameCh  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameCs="' + COALESCE(CAST(SportNameCs  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameJp="' + COALESCE(CAST(SportNameJp  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameIt="' + COALESCE(CAST(SportNameIt  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameTh="' + COALESCE(CAST(SportNameTh  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ParlayMaxPayout="' + COALESCE(CAST(ParlayMaxPayout  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameKo="' + COALESCE(CAST(SportNameKo  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameES="' + COALESCE(CAST(SportNameES  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameVN="' + COALESCE(CAST(SportNameVN  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameEL="' + COALESCE(CAST(SportNameEL  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameRU="' + COALESCE(CAST(SportNameRU  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameID="' + COALESCE(CAST(SportNameID  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNamePT="' + COALESCE(CAST(SportNamePT  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameFR="' + COALESCE(CAST(SportNameFR  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameMMR="' + COALESCE(CAST(SportNameMMR  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNamePL="' + COALESCE(CAST(SportNamePL  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SportNameHI="' + COALESCE(CAST(SportNameHI  AS VARCHAR(50)), SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM #input WITH(NOLOCK)
		WHERE  ID = @CurrentRow
		
		SET @endRun = GETDATE()
	    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@CustID = 0,
				@ActionID = 95008,
				@TrackingValue = @LogSPData,
				@TrackingValue2 = @LogSPData2,
				@duration = @duration
	END
	DROP TABLE #input
END

