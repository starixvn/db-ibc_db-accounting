/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Manual_MoveBet_Adjust
	@File	    NVARCHAR(MAX),
	@LoginIP	VARCHAR(20)='',
	@FromDate	SMALLDATETIME,
	@ToDate		SMALLDATETIME,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT,
	@UserID		INT
AS
/*
Created: 20210204@Danny
Task :  NAP Manage MoveBet Insert
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20210204@Danny: Initialize SP [Redmine: #150053]
		
	Param's Explanation:
	- @Fie:		
		<ROOT>
				<File 
						MB="YYYY-MM-DD"
						Isbackday1="0"
						Isbackday2="0"
						Isbackday3="1"
						Isbackday4="0"
						Isbackday5="0"
						Isbackday6="0"
						Isbackday7="0"
				/>
		</ROOT>	
*/

BEGIN
    SET NOCOUNT ON

	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @MBDateError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT, @ColumnName VARCHAR(100)
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	
	IF ISNULL(@File, '') = ''
			RETURN

	DECLARE @CurrentTime TIME = CONVERT(TIME, GETDATE())

	IF @CurrentTime >= '05:30'
	BEGIN
			SELECT @ErrCode = 1001, @ErrMsg = 'You can not adjust the schedule after Move Bet Time.' 
			RETURN
	END

	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		MBDate			SMALLDATETIME,
		Isbackday1		BIT,
		Isbackday2		BIT,
		Isbackday3		BIT,
		Isbackday4		BIT,
		Isbackday5		BIT,
		Isbackday6		BIT,
		Isbackday7		BIT 
		)

	CREATE TABLE #inputTmp
	(    
		ID              INT IDENTITY (1,1),
		MBDate          NVARCHAR(MAX),
		Isbackday1		NVARCHAR(MAX),
		Isbackday2		NVARCHAR(MAX),
		Isbackday3		NVARCHAR(MAX),
		Isbackday4		NVARCHAR(MAX),
		Isbackday5		NVARCHAR(MAX),
		Isbackday6		NVARCHAR(MAX),
		Isbackday7		NVARCHAR(MAX)
		)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #inputTmp ( 
							MBDate,
							Isbackday1,
							Isbackday2,
							Isbackday3,
							Isbackday4,
							Isbackday5,
							Isbackday6,
							Isbackday7
							)

			SELECT			MBDate,
							Isbackday1,
							Isbackday2,
							Isbackday3,
							Isbackday4,
							Isbackday5,
							Isbackday6,
							Isbackday7
			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (MBDate			NVARCHAR(MAX),
														Isbackday1		NVARCHAR(MAX),
														Isbackday2		NVARCHAR(MAX),
														Isbackday3		NVARCHAR(MAX),
														Isbackday4		NVARCHAR(MAX),
														Isbackday5		NVARCHAR(MAX),
														Isbackday6		NVARCHAR(MAX),
														Isbackday7		NVARCHAR(MAX)
														)
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH

	SELECT TOP(1) @MBDateError = ID, 
	              @ValueError   = CASE WHEN ISDATE(MBDate) = 0 THEN MBDate
									   WHEN Isbackday1 NOT IN (0,1) THEN Isbackday1
									   WHEN Isbackday2 NOT IN (0,1) THEN Isbackday2
									   WHEN Isbackday3 NOT IN (0,1) THEN Isbackday3
							           WHEN Isbackday4 NOT IN (0,1) THEN Isbackday4
							           WHEN Isbackday5 NOT IN (0,1) THEN Isbackday5
							           WHEN Isbackday6 NOT IN (0,1) THEN Isbackday6
									   WHEN Isbackday7 NOT IN (0,1) THEN Isbackday7
									END,
				
					@ColumnName = CASE WHEN ISDATE(MBDate) = 0 THEN 'MBDate'
									   WHEN Isbackday1 NOT IN (0,1) THEN 'Isbackday1'
									   WHEN Isbackday2 NOT IN (0,1) THEN 'Isbackday2'
									   WHEN Isbackday3 NOT IN (0,1) THEN 'Isbackday3'
							           WHEN Isbackday4 NOT IN (0,1) THEN 'Isbackday4'
							           WHEN Isbackday5 NOT IN (0,1) THEN 'Isbackday5'
							           WHEN Isbackday6 NOT IN (0,1) THEN 'Isbackday6'
									   WHEN Isbackday7 NOT IN (0,1) THEN 'Isbackday7'
									END
	FROM #inputTmp
	WHERE ISDATE(MBDate) = 0 
		  OR Isbackday1 NOT IN (0,1)
		  OR Isbackday2 NOT IN (0,1)
		  OR Isbackday3 NOT IN (0,1)
		  OR Isbackday4 NOT IN (0,1)
		  OR Isbackday5 NOT IN (0,1)
		  OR Isbackday6 NOT IN (0,1)
		  OR Isbackday7 NOT IN (0,1)
		 
	IF @ErrCode <> 0
	BEGIN
		IF @ErrCode = 1001
			SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @MBDateError + '".Please check them again.'

		RETURN
	END
	   
	BEGIN TRY
		INSERT INTO #input
		(
				MBDate,
				Isbackday1,
				Isbackday2,
				Isbackday3,
				Isbackday4,
				Isbackday5,
				Isbackday6,
				Isbackday7
		)
		SELECT	MBDate,
				Isbackday1,
				Isbackday2,
				Isbackday3,
				Isbackday4,
				Isbackday5,
				Isbackday6,
				Isbackday7
		FROM #inputTmp
	END TRY

	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH


	-- Generate data for checking duplicate MB date
	BEGIN TRY
		 CREATE TABLE #DefaultMovebetConfig
		 (
			_weekDay SmallInt, 
			Isbackday1 BIT,  
			Isbackday2 BIT,
			Isbackday3 BIT,
			Isbackday4 BIT,
			Isbackday5 BIT,
			Isbackday6 BIT,
			Isbackday7 BIT,   
		)

		INSERT INTO #DefaultMovebetConfig (_weekDay,Isbackday1,Isbackday2,Isbackday3,Isbackday4,Isbackday5,Isbackday6,Isbackday7 )
		EXEC dbo.Acc_Manual_MoveBet_Sel @IsDefault = 1

		DECLARE @calendarTable TABLE (scheduleDate smalldatetime, weekday_ tinyint)

		;WITH CTE_Winlostdate (winlostdate ) AS
		(
			SELECT DATEADD(DAY, -7,@FromDate) AS winlostdate
			UNION ALL
			SELECT DATEADD(DAY, 1, winlostdate)
			FROM CTE_Winlostdate
			WHERE winlostdate < DATEADD(DAY, 7,@ToDate)
		)
		INSERT INTO @calendarTable(scheduleDate, weekday_)
		select  winlostdate, DATEPART(WEEKDAY, winlostdate) from CTE_Winlostdate
		OPTION (MAXRECURSION 0)


		select		t.scheduleDate  
					,t.weekday_  
					,Isbackday1 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday1 ELSE dc.Isbackday1 END
					,Isbackday2 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday2 ELSE dc.Isbackday2 END
					,Isbackday3 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday3 ELSE dc.Isbackday3 END
					,Isbackday4 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday4 ELSE dc.Isbackday4 END
					,Isbackday5 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday5 ELSE dc.Isbackday5 END
					,Isbackday6 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday6 ELSE dc.Isbackday6 END
					,Isbackday7 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday7 ELSE dc.Isbackday7 END
		INTO		#check_MB_duplicate
		from		@calendarTable t
		left join	#DefaultMovebetConfig dc ON dc._weekDay = t.weekday_
		left join	#input mc ON t.scheduleDate = mc.MBDate

		DROP TABLE #check_MB_duplicate
		DROP TABLE #DefaultMovebetConfig
		
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
									LicSpreadBetTypeGroupId,
									Is3rdParty)

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
									LicSpreadBetTypeGroupId,
									Is3rdParty
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
								'Is3rdParty="' + COALESCE(CAST(Is3rdParty  AS VARCHAR(15)), SPACE(1)) + '" ' +
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