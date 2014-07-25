ALTER PROCEDURE [NAP_Admin_Settlement_FGLG] @creator INT
	,@matchid INT
	,@action VARCHAR(10) = 'CAL-FT'
	,@betstatus NVARCHAR(50)
	,@IncludeLG BIT = 1
	,@IP VARCHAR(15) = ''
	,@goalrecord VARCHAR(50) = ''
	,@IsLoopTempTable BIT = 0
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*	Creator: Kathy
	Date: 20140213 
	Task: SP for settle FGLG
	DB: DBTXN/BODB02
	Original: Admin_Settlement_FGLG

	Revisions:
		- 20140426@Kathy: Add @action param (1H FGLG (bettype 127) ) [Redmine:#14449]
		- 20140618@Kathy: Correct betstatus
	Param's Explanation:
		+ @betstatus: FGLG status
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @ActionID INT
		,@bettype INT

	SELECT @ActionID = 108
		,@bettype = CASE 
			WHEN @action = 'CAL-HT' THEN 127
			ELSE 14
			END

	IF @IsLoopTempTable = 0
	BEGIN
		-- check and not allow attempt to settlement same game while it's still not finish
		IF EXISTS (
				SELECT 1
				FROM dbo.TempVariableNumber
				WHERE KeyID = 1 AND KeyValue = @matchid
				)
		BEGIN
			SELECT @ErrCode = 1000000
				,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

			RETURN
		END

		DECLARE @Remark VARCHAR(500)

		INSERT INTO dbo.TempVariableNumber (
			KeyID
			,KeyValue
			)
		VALUES (
			1
			,@matchid
			)

		IF (@@Error = 0)
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'ADD SUCCESS'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)

				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark
			END CATCH
		END
		ELSE
		BEGIN
			SELECT @ErrCode = 1000000
				,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

			RETURN
		END
	END

	---
	EXEC DBPRO.BODB02.dbo.NAP_Admin_Match_Update @Command = 'NAP_Admin_Settlement_FGLG'
		,@MatchID = @matchid
		,@BetStatus = @betstatus
		,@GoalRecord = @goalrecord
		,@creator = @creator

	-------------------------
	--First Goal, Last Goal 
	DECLARE @FGLG1 VARCHAR(10)
		,@FGLG2 VARCHAR(10)
		,@FLString VARCHAR(10)
		,@HT_FGLG1 VARCHAR(10)
		,@HT_FGLG2 VARCHAR(10)
		,@HT_FLString VARCHAR(10)
		,@temp_betstatus nvarchar(50)

	SELECT @FGLG1 = ''
		,@FGLG2 = ''
		,@HT_FGLG1 = ''
		,@HT_FGLG2 = ''
		,@temp_betstatus = @betstatus

	IF charindex('1FL:',@temp_betstatus) > 0 
	begin
		select @HT_FLString = SUBSTRING(@temp_betstatus,charindex('1FL:',@temp_betstatus) + 4, 3)
				,@temp_betstatus = REPLACE(@temp_betstatus,SUBSTRING(@temp_betstatus,CHARINDEX('1FL:',@temp_betstatus),7),'')
				,@HT_FGLG1 = case @HT_FLString when '0-0' then '0:0'
											 else left(@HT_FLString,1) + ':1'
						   end
				,@HT_FGLG2 = case @HT_FLString when '0-0' then ''
											 else right(@HT_FLString,1) + ':2'
						   end
	end
	IF charindex('FL:',@temp_betstatus) > 0
	begin
		select @FLString = SUBSTRING(@temp_betstatus,CHARINDEX('FL:',@temp_betstatus) + 3, 3)
				,@FGLG1 = case @FLString when '0-0' then '0:0' 
									   else left(@FLString,1) + ':1'
						end
				,@FGLG2 = case @FLString when '0-0' then ''
									   else right(@FLString,1) + ':2'
						end
	end

	

	-------------------------
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	DECLARE @TotalAccount INT
		,@TotalAccount_BalanceUpdate INT

	BEGIN
		--===
		INSERT INTO #BalanceBefore
		SELECT custid
			,SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans WITH (ROWLOCK)
		WHERE matchid = @matchid AND bettype = @bettype
		GROUP BY custid

		SET @TotalAccount = @@ROWCOUNT
			--===
	END

	-- bettype 14 : First Goal Last Goal - re-use the SP of Correct Score, so we have to call it twice		
	DECLARE @betcount_14 INT
		,@betcount_127 INT
		,@goaldiff SMALLMONEY

	SELECT @betcount_14 = SUM(CASE 
				WHEN bettype = 14 THEN 1
				ELSE 0
				END)
		,@betcount_127 = SUM(CASE 
				WHEN bettype = 127 THEN 1
				ELSE 0
				END)
	FROM dbo.bettrans WITH (NOLOCK)
	WHERE matchid = @matchid
	AND bettype IN (14, 127)

	IF @betcount_14 = 0 OR @betcount_127 = 0
	BEGIN
		SELECT @betcount_14 = CASE 
				WHEN @betcount_14 = 0 THEN SUM(CASE 
							WHEN bettype = 14 THEN 1
							ELSE 0
							END)
				ELSE @betcount_14
				END
			,@betcount_127 = CASE 
				WHEN @betcount_127 = 0 THEN SUM(CASE 
							WHEN bettype = 127 THEN 1
							ELSE 0
							END)
				ELSE @betcount_127
				END
		FROM dbo.bettransm WITH (NOLOCK)
		WHERE matchid = @matchid
	END

	SET @goaldiff = 0

	IF @action = 'CAL-HT'
	BEGIN
		-- cal HT
		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'CAL-FGLG'
			,@mode = 'CAL-HT'
			,@HT_FGLG1 = @HT_FGLG1
			,@goaldiff = @goaldiff
			,@HT_FGLG2 = @HT_FGLG2
			,@betcount_127 = @betcount_127

		IF @IncludeLG = 0
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
				,@action = 'CAL-FGLG'
				,@mode = 'CAL-FT'
				,@FGLG1 = @FGLG1
				,@goaldiff = @goaldiff
				,@FGLG2 = @FGLG2
				,@betcount_14 = @betcount_14

			EXEC dbo.NAP_Admin_Settlement_Refund_FGLG --refund  all LG
				@matchid = @matchid
				,@adminid = @creator
				,@action = 'REFUND'
				,@LGOnly = 1
				,@IP = @IP
				,@IsLoopTempTable = 1 ---Not check concurrency by TempVariableNumber table
		END
	END

	IF @action = 'CAL-FT'
	BEGIN
		-- cal FT
		EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
			,@action = 'CAL-FGLG'
			,@mode = 'CAL-FT'
			,@FGLG1 = @FGLG1
			,@goaldiff = @goaldiff
			,@FGLG2 = @FGLG2
			,@betcount_14 = @betcount_14

		IF @IncludeLG = 0
		BEGIN
			EXEC dbo.NAP_Admin_Settlement_Refund_FGLG --refund FT LG
				@matchid = @matchid
				,@adminid = @creator
				,@action = 'REFUND-FT'
				,@LGOnly = 1
				,@IP = @IP
				,@IsLoopTempTable = 1 ---Not check concurrency by TempVariableNumber table
		END
	END

	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	BEGIN
		--===
		INSERT INTO #BalanceAfter
		SELECT custid
			,SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans WITH (ROWLOCK)
		WHERE matchid = @matchid AND bettype = @bettype
		GROUP BY custid
			--===
	END

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (
		custid INT PRIMARY KEY
		,balance MONEY
		,Increased BIT
		)

	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid
		,a.balance - b.balance
		,CASE 
			WHEN a.balance > b.balance THEN 1
			ELSE 0
			END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance

	SET @TotalAccount_BalanceUpdate = @@ROWCOUNT

	INSERT INTO dbo.BalancePendingDebit (
		custid
		,balance
		)
	SELECT custid
		,ABS(balance)
	FROM #Balance
	WHERE Increased = 0

	INSERT INTO dbo.BalancePendingCredit (
		custid
		,balance
		)
	SELECT custid
		,balance
	FROM #Balance
	WHERE Increased = 1

	----
	-- Add Negative Balance into BalanceNegative table 
	----
	INSERT INTO [bodb02].[dbo].[BalanceNegative] (
		[ExecDate]
		,[MatchID]
		,[ActionID]
		,[GroupID]
		,[CustID]
		,[Balance]
		,[StatusID]
		,[Remark]
		)
	SELECT GETDATE()
		,@MatchID
		,@ActionID
		,1 -- Sportsbook Single bet Settlement 
		,CustID
		,Balance
		,0
		,NULL
	FROM #Balance WITH (NOLOCK)
	WHERE Increased = 0

	---------------------------------------------------
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter

	-------------------------------------------------------------
	---                      WRITE LOG                        ---
	---------------------------VVVV------------------------------
	--Write Log Settle
	DECLARE @finalhomescore INT
		,@finalawayscore INT
		,@hthomescore INT
		,@htawayscore INT

	SELECT @finalhomescore = finalhomescore
		,@finalawayscore = finalawayscore
		,@hthomescore = hthomescore
		,@htawayscore = htawayscore
	FROM DBPRO.BODB02.dbo.match WITH (NOLOCK)
	WHERE matchid = @matchid

	DECLARE @LogData VARCHAR(200)

	SELECT @LogData = 'NAP: Calculate FGLG for matchid:' + CAST(@matchid AS NVARCHAR(10)) + ' score:' + CAST(ISNULL(@finalhomescore, 0) AS NVARCHAR(10)) + '-' + CAST(ISNULL(@finalawayscore, 0) AS NVARCHAR(10)) + ' HT:' + CAST(@hthomescore AS NVARCHAR(10)) + '-' + CAST(@htawayscore AS NVARCHAR(10)) + ' GoalRecord:' + ISNULL(@goalrecord, '') + ') Remark(BetStatus=' + @betstatus + ', IncludeLG=' + convert(CHAR(1), @IncludeLG) + ', Action=' + @action + ')'

	EXEC dbo.WriteLog_UserLog @creator
		,@LogData

	SELECT @Remark = 'NAP: IncludeLG=' + convert(CHAR(1), @IncludeLG) + 'Action=' + @action

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @creator
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = @finalhomescore
			,@finalawayscore = @finalawayscore
			,@hthomescore = @hthomescore
			,@htawayscore = @htawayscore
			,@GoalRecord = @goalrecord
			,@betstatus = @betstatus
			,@Remark = @Remark
			,@IP = @IP
	END TRY

	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle @UserID = @creator
			,@Matchid = @matchid
			,@ActionID = @ActionID
			,@finalhomescore = @finalhomescore
			,@finalawayscore = @finalawayscore
			,@hthomescore = @hthomescore
			,@htawayscore = @htawayscore
			,@GoalRecord = @goalrecord
			,@betstatus = @betstatus
			,@Remark = @Remark
			,@IP = @IP
	END CATCH

	-----
	IF @IsLoopTempTable = 0
	BEGIN
		DELETE
		FROM dbo.TempVariableNumber WITH (ROWLOCK, UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid

		IF (@@Error = 0)
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'DEL SUCCESS'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)

				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark
			END CATCH
		END
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = 'DEL FAILED'
			END TRY

			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)

				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking @UserID = @creator
					,@Matchid = @matchid
					,@KeyID = 1
					,@ActionID = @ActionID
					,@Remark = @Remark
			END CATCH
		END
	END
END


GO

GRANT EXECUTE ON [NAP_Admin_Settlement_FGLG] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_FGLG] TO [vnteam] AS [dbo]
GO


