/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  dbo.Acc_Manual_MoveBet_Adjust
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
DB: DBTXN-bodb02
Original:

	Revisions:
		- 20210204@Danny: Initialize SP [Redmine: #150053]
		
	Param's Explanation:
	- @FromDate	: User input in UI
	- @ToDate	: User input in UI
	- @File:		
		<ROOT>
				<File 
						MBDate="YYYY-MM-DD"
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

	IF @CurrentTime >= '23:59'
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

	SELECT TOP(1) @ErrCode = 1002, 
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
	WHERE ISDATE(MBDate) = 0 OR MBDate IS NULL OR MBDate = '' 
		  OR Isbackday1 NOT IN (0,1)
		  OR Isbackday2 NOT IN (0,1)
		  OR Isbackday3 NOT IN (0,1)
		  OR Isbackday4 NOT IN (0,1)
		  OR Isbackday5 NOT IN (0,1)
		  OR Isbackday6 NOT IN (0,1)
		  OR Isbackday7 NOT IN (0,1)
		 
	IF @ErrCode = 1002
	BEGIN
			SELECT @ErrCode = 1002, @ErrMsg = 'Invalid "' + @ColumnName + '" with value "' + ISNULL(@ValueError,' ') + '".Please check them again.'

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

		CREATE TABLE #MBDetail (RunningDate SMALLDATETIME, MBDate SMALLDATETIME)

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
					,Isbackday1 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday1 ELSE CASE WHEN mmc.Isbackday1 IS NOT NULL THEN mmc.Isbackday1 ELSE dc.Isbackday1 END END
					,Isbackday2 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday2 ELSE CASE WHEN mmc.Isbackday2 IS NOT NULL THEN mmc.Isbackday2 ELSE dc.Isbackday2 END END
					,Isbackday3 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday3 ELSE CASE WHEN mmc.Isbackday3 IS NOT NULL THEN mmc.Isbackday3 ELSE dc.Isbackday3 END END
					,Isbackday4 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday4 ELSE CASE WHEN mmc.Isbackday4 IS NOT NULL THEN mmc.Isbackday4 ELSE dc.Isbackday4 END END
					,Isbackday5 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday5 ELSE CASE WHEN mmc.Isbackday5 IS NOT NULL THEN mmc.Isbackday5 ELSE dc.Isbackday5 END END
					,Isbackday6 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday6 ELSE CASE WHEN mmc.Isbackday6 IS NOT NULL THEN mmc.Isbackday6 ELSE dc.Isbackday6 END END
					,Isbackday7 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday7 ELSE CASE WHEN mmc.Isbackday7 IS NOT NULL THEN mmc.Isbackday7 ELSE dc.Isbackday7 END END
		INTO		#check_MB_duplicate
		from		@calendarTable t
		left join	#DefaultMovebetConfig dc ON dc._weekDay = t.weekday_
		left join	#input mc ON t.scheduleDate = mc.MBDate
		left join	dbo.Acc_ManualMovebetConfig mmc ON mmc.MBDate = t.scheduleDate

		---------------
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -1, scheduleDate) FROM #check_MB_duplicate where  Isbackday1 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -2, scheduleDate) FROM #check_MB_duplicate where  Isbackday2 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -3, scheduleDate) FROM #check_MB_duplicate where  Isbackday3 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -4, scheduleDate) FROM #check_MB_duplicate where  Isbackday4 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -5, scheduleDate) FROM #check_MB_duplicate where  Isbackday5 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -6, scheduleDate) FROM #check_MB_duplicate where  Isbackday6 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -7, scheduleDate) FROM #check_MB_duplicate where  Isbackday7 = 1
		---------------

		---- Duplicate MB checking
		SELECT TOP(1) @ErrCode = 1003, @ValueError = CAST(MBDate as NVARCHAR(50))  
		FROM #MBDetail
		GROUP BY MBDate
		HAVING COUNT(1) > 1

		IF @ErrCode <> 0
		BEGIN
				SELECT @ErrCode = 1003, @ErrMsg = 'Duplicate MoveBet on "' + @ValueError + ' .Please check them again.'
				RETURN
		END

		---- Missing MB checking
		DECLARE @FromMissingDate SMALLDATETIME
		DECLARE @ToMissingDate SMALLDATETIME

		CREATE TABLE #MB_Missing_check( RunningDate SMALLDATETIME, MBDate SMALLDATETIME, RN INT)
		INSERT INTO #MB_Missing_check(RunningDate, MBDate, RN)
		SELECT RunningDate, MBDate, ROW_NUMBER() OVER (ORDER BY MBDate asc ) AS RN   FROM #MBDetail 

		CREATE CLUSTERED INDEX cix_#MB_Missing_check ON #MB_Missing_check(RN)

		SELECT TOP(1) @ErrCode = 1004, @FromMissingDate = f.MBDate, @ToMissingDate = t.MBDate
		FROM #MB_Missing_check f
		INNER JOIN #MB_Missing_check t ON F.RN = t.RN - 1
		WHERE DATEDIFF(DAY, f.MBDate, t.MBDate) > 1

		IF @ErrCode <> 0
		BEGIN
				SELECT @ErrCode = 1004, @ErrMsg = 'Missing MoveBet beetween ' + CAST (@FromMissingDate AS NVARCHAR(20)) + ' AND '+  CAST (@ToMissingDate AS NVARCHAR(20))  + ' .Please check them again.'
				RETURN
		END

		----Failure logic MB checking

		CREATE TABLE #MB_Logical_check( RunningDate SMALLDATETIME, MBDate SMALLDATETIME, RN INT)
		INSERT INTO #MB_Logical_check(RunningDate, MBDate, RN)
		SELECT RunningDate, MBDate, ROW_NUMBER() OVER (ORDER BY RunningDate asc, MBDate asc) AS RN   FROM #MBDetail 

		CREATE CLUSTERED INDEX cix_#MB_Logical_check ON #MB_Logical_check(RN)

		DECLARE @FromLogicalDate SMALLDATETIME
		DECLARE @ToLogicalDate SMALLDATETIME

		SELECT TOP(1) @ErrCode = 1005, @FromLogicalDate = f.MBDate, @ToLogicalDate = t.MBDate
		FROM #MB_Logical_check f
		INNER JOIN #MB_Logical_check t ON F.RN < t.RN 
		WHERE  f.MBDate >= t.MBDate

		IF @ErrCode <> 0
		BEGIN
				SELECT @ErrCode = 1005, @ErrMsg = 'Failure!! MoveBet on ' + CAST (@FromLogicalDate AS NVARCHAR(20)) + ' will happen before '+  CAST (@ToLogicalDate AS NVARCHAR(20))  + ' .Please check them again.'
				RETURN
		END
		
		DROP TABLE #MBDetail
		DROP TABLE #MB_Missing_check
		DROP TABLE #MB_Logical_check
		DROP TABLE #check_MB_duplicate
		DROP TABLE #DefaultMovebetConfig
		
	END TRY

	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH


	BEGIN TRY
		;MERGE dbo.Acc_ManualMovebetConfig AS t
		USING #input AS s ON t.MBDate = s.MBDate
		WHEN MATCHED THEN UPDATE 
		SET  	MBDate = s.MBDate
				,Isbackday1 = s.Isbackday1
				,Isbackday2 = s.Isbackday2
				,Isbackday3 = s.Isbackday3
				,Isbackday4 = s.Isbackday4
				,Isbackday5 = s.Isbackday5
				,Isbackday6 = s.Isbackday6
				,Isbackday7 = s.Isbackday7
		WHEN NOT MATCHED THEN
		INSERT (MBDate
				,Isbackday1   
				,Isbackday2 
				,Isbackday3 
				,Isbackday4 
				,Isbackday5 
				,Isbackday6 
				,Isbackday7 )
		VALUES
				(
				s.MBDate
				,s.Isbackday1   
				,s.Isbackday2 
				,s.Isbackday3 
				,s.Isbackday4 
				,s.Isbackday5 
				,s.Isbackday6 
				,s.Isbackday7 
				);
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH 
	
	DROP TABLE #input
	DROP TABLE #inputTmp
END