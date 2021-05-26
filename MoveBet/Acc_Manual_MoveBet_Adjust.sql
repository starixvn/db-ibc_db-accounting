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
						IsBackDay1="0"
						IsBackDay2="0"
						IsBackDay3="1"
						IsBackDay4="0"
						IsBackDay5="0"
						IsBackDay6="0"
						IsBackDay7="0"
				/>
		</ROOT>	
*/

BEGIN
    SET NOCOUNT ON

	DECLARE @iDoc INT, @RowTotal INT = 0, @CurrentRow INT = 0, @MBDateError NVARCHAR(MAX) = '', @ValueError NVARCHAR(MAX) = '', @LimitValue BIGINT, @ColumnName VARCHAR(100)
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	
	IF ISNULL(@File, '') = ''
			RETURN

	--- Check moveBet is running
	IF EXISTS (
			SELECT 1
			FROM dbo.SystemSettings WITH(NOLOCK)
			WHERE VValue 	= 1 
			AND VName 		= 'isMovingBet_Local'
			)
	BEGIN
		SELECT @ErrCode = 1006, @ErrMsg = 'You can not adjust the schedule during Move Bet Time.'
		RETURN
	END

	---- Get MoveBet, BU
	DECLARE @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
	DECLARE @MBU TABLE ( MoveBetsDay SMALLDATETIME, BalanceUpDay SMALLDATETIME)

	INSERT INTO @MBU (BalanceUpDay, MoveBetsDay)
	EXEC dbo.Age_SelBalanceUpDay


	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay
	FROM @MBU

	---- End

	CREATE TABLE #input 
	(    
		ID				INT IDENTITY (1,1),
		MBDate			SMALLDATETIME,
		IsBackDay1		BIT,
		IsBackDay2		BIT,
		IsBackDay3		BIT,
		IsBackDay4		BIT,
		IsBackDay5		BIT,
		IsBackDay6		BIT,
		IsBackDay7		BIT 
		)

	CREATE TABLE #inputTmp
	(    
		ID              INT IDENTITY (1,1),
		MBDate          NVARCHAR(MAX),
		IsBackDay1		NVARCHAR(MAX),
		IsBackDay2		NVARCHAR(MAX),
		IsBackDay3		NVARCHAR(MAX),
		IsBackDay4		NVARCHAR(MAX),
		IsBackDay5		NVARCHAR(MAX),
		IsBackDay6		NVARCHAR(MAX),
		IsBackDay7		NVARCHAR(MAX)
		)

	BEGIN TRY
			EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
			INSERT #inputTmp ( 
							MBDate,
							IsBackDay1,
							IsBackDay2,
							IsBackDay3,
							IsBackDay4,
							IsBackDay5,
							IsBackDay6,
							IsBackDay7
							)

			SELECT			MBDate,
							IsBackDay1,
							IsBackDay2,
							IsBackDay3,
							IsBackDay4,
							IsBackDay5,
							IsBackDay6,
							IsBackDay7
			FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH  (MBDate			NVARCHAR(MAX),
														IsBackDay1		NVARCHAR(MAX),
														IsBackDay2		NVARCHAR(MAX),
														IsBackDay3		NVARCHAR(MAX),
														IsBackDay4		NVARCHAR(MAX),
														IsBackDay5		NVARCHAR(MAX),
														IsBackDay6		NVARCHAR(MAX),
														IsBackDay7		NVARCHAR(MAX)
														)
		    
			EXEC sp_xml_removedocument @iDoc
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();
		RETURN
	END CATCH

	SELECT TOP(1) @ErrCode = 1002, 
	              @ValueError   = CASE WHEN ISDATE(MBDate) = 0 THEN MBDate
									   WHEN IsBackDay1 NOT IN (0,1) THEN IsBackDay1
									   WHEN IsBackDay2 NOT IN (0,1) THEN IsBackDay2
									   WHEN IsBackDay3 NOT IN (0,1) THEN IsBackDay3
							           WHEN IsBackDay4 NOT IN (0,1) THEN IsBackDay4
							           WHEN IsBackDay5 NOT IN (0,1) THEN IsBackDay5
							           WHEN IsBackDay6 NOT IN (0,1) THEN IsBackDay6
									   WHEN IsBackDay7 NOT IN (0,1) THEN IsBackDay7
									END,
				
					@ColumnName = CASE WHEN ISDATE(MBDate) = 0 THEN 'MBDate'
									   WHEN IsBackDay1 NOT IN (0,1) THEN 'IsBackDay1'
									   WHEN IsBackDay2 NOT IN (0,1) THEN 'IsBackDay2'
									   WHEN IsBackDay3 NOT IN (0,1) THEN 'IsBackDay3'
							           WHEN IsBackDay4 NOT IN (0,1) THEN 'IsBackDay4'
							           WHEN IsBackDay5 NOT IN (0,1) THEN 'IsBackDay5'
							           WHEN IsBackDay6 NOT IN (0,1) THEN 'IsBackDay6'
									   WHEN IsBackDay7 NOT IN (0,1) THEN 'IsBackDay7'
									END
	FROM #inputTmp
	WHERE ISDATE(MBDate) = 0 OR MBDate IS NULL OR MBDate = '' 
		  OR IsBackDay1 NOT IN (0,1)
		  OR IsBackDay2 NOT IN (0,1)
		  OR IsBackDay3 NOT IN (0,1)
		  OR IsBackDay4 NOT IN (0,1)
		  OR IsBackDay5 NOT IN (0,1)
		  OR IsBackDay6 NOT IN (0,1)
		  OR IsBackDay7 NOT IN (0,1)
		 
	IF @ErrCode = 1002
	BEGIN
			SELECT @ErrCode = 1002, @ErrMsg = 'Invalid "' + @ColumnName + '" with value "' + ISNULL(@ValueError,' ') + '".Please check them again.'

		RETURN
	END
	   
	BEGIN TRY
		INSERT INTO #input
		(
				MBDate,
				IsBackDay1,
				IsBackDay2,
				IsBackDay3,
				IsBackDay4,
				IsBackDay5,
				IsBackDay6,
				IsBackDay7
		)
		SELECT	MBDate,
				IsBackDay1,
				IsBackDay2,
				IsBackDay3,
				IsBackDay4,
				IsBackDay5,
				IsBackDay6,
				IsBackDay7
		FROM #inputTmp
	END TRY

	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Check MB 
	IF EXISTS (SELECT 1 FROM #input WHERE MBDate <= @MoveBetsDay)
	BEGIN
			SELECT TOP(1)  @ValueError = CAST(MBDate as NVARCHAR(50))  
			FROM #input
			WHERE MBDate <= @MoveBetsDay

			SELECT @ErrCode = 1000, @ErrMsg = 'You cannot adjust the schedule of date "' + @ValueError + ' . It has moved bet already.'
			RETURN
	END


	-- Generate data for checking duplicate MB date
	BEGIN TRY
		 CREATE TABLE #DefaultMovebetConfig
		 (
			_weekDay SmallInt, 
			IsBackDay1 BIT,  
			IsBackDay2 BIT,
			IsBackDay3 BIT,
			IsBackDay4 BIT,
			IsBackDay5 BIT,
			IsBackDay6 BIT,
			IsBackDay7 BIT,   
		)

		CREATE TABLE #MBDetail (RunningDate SMALLDATETIME, MBDate SMALLDATETIME)

		INSERT INTO #DefaultMovebetConfig (_weekDay,IsBackDay1,IsBackDay2,IsBackDay3,IsBackDay4,IsBackDay5,IsBackDay6,IsBackDay7 )
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
					,IsBackDay1 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay1 ELSE CASE WHEN mmc.IsBackDay1 IS NOT NULL THEN mmc.IsBackDay1 ELSE dc.IsBackDay1 END END
					,IsBackDay2 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay2 ELSE CASE WHEN mmc.IsBackDay2 IS NOT NULL THEN mmc.IsBackDay2 ELSE dc.IsBackDay2 END END
					,IsBackDay3 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay3 ELSE CASE WHEN mmc.IsBackDay3 IS NOT NULL THEN mmc.IsBackDay3 ELSE dc.IsBackDay3 END END
					,IsBackDay4 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay4 ELSE CASE WHEN mmc.IsBackDay4 IS NOT NULL THEN mmc.IsBackDay4 ELSE dc.IsBackDay4 END END
					,IsBackDay5 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay5 ELSE CASE WHEN mmc.IsBackDay5 IS NOT NULL THEN mmc.IsBackDay5 ELSE dc.IsBackDay5 END END
					,IsBackDay6 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay6 ELSE CASE WHEN mmc.IsBackDay6 IS NOT NULL THEN mmc.IsBackDay6 ELSE dc.IsBackDay6 END END
					,IsBackDay7 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay7 ELSE CASE WHEN mmc.IsBackDay7 IS NOT NULL THEN mmc.IsBackDay7 ELSE dc.IsBackDay7 END END
		INTO		#check_MB_duplicate
		from		@calendarTable t
		left join	#DefaultMovebetConfig dc ON dc._weekDay = t.weekday_
		left join	#input mc ON t.scheduleDate = mc.MBDate
		left join	dbo.Acc_ManualMovebetConfig mmc ON mmc.MBDate = t.scheduleDate

		---------------
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -1, scheduleDate) FROM #check_MB_duplicate where  IsBackDay1 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -2, scheduleDate) FROM #check_MB_duplicate where  IsBackDay2 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -3, scheduleDate) FROM #check_MB_duplicate where  IsBackDay3 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -4, scheduleDate) FROM #check_MB_duplicate where  IsBackDay4 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -5, scheduleDate) FROM #check_MB_duplicate where  IsBackDay5 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -6, scheduleDate) FROM #check_MB_duplicate where  IsBackDay6 = 1
		INSERT INTO #MBDetail (RunningDate,MBDate) SELECT scheduleDate, DATEADD(day, -7, scheduleDate) FROM #check_MB_duplicate where  IsBackDay7 = 1
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
				,IsBackDay1 = s.IsBackDay1
				,IsBackDay2 = s.IsBackDay2
				,IsBackDay3 = s.IsBackDay3
				,IsBackDay4 = s.IsBackDay4
				,IsBackDay5 = s.IsBackDay5
				,IsBackDay6 = s.IsBackDay6
				,IsBackDay7 = s.IsBackDay7
		WHEN NOT MATCHED THEN
		INSERT (MBDate
				,IsBackDay1   
				,IsBackDay2 
				,IsBackDay3 
				,IsBackDay4 
				,IsBackDay5 
				,IsBackDay6 
				,IsBackDay7 )
		VALUES
				(
				s.MBDate
				,s.IsBackDay1   
				,s.IsBackDay2 
				,s.IsBackDay3 
				,s.IsBackDay4 
				,s.IsBackDay5 
				,s.IsBackDay6 
				,s.IsBackDay7 
				);
	END TRY

	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH 
	
	DROP TABLE #input
	DROP TABLE #inputTmp
END