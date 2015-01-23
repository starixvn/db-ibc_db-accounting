ALTER PROCEDURE [dbo].[Lrf_LicenseeBetSettingUpd] 
	@CustID INT
	,@Sporttype INT
	,@Bettype INT = 0
	,@MinBet MONEY
	,@MaxBet MONEY
	,@MaxPerMatch MONEY
	,@MaxPerBall MONEY = 0
	,@ExistedMember BIT
	,@Enable BIT = 0
	,@EnableDownline BIT = 0
	,@UserID INT = 0
	,@Language varchar(2) = 'E'
	,@IP VARCHAR(15)=''
	,@ErrCode INT = 0 OUTPUT
    ,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20150108
	Task : Licensee Setting Configuration - Update Bet Setting [#6304]
	DB: DBCUST/CustDB
	Original:

	Revisions:

	Param's Explanation:
	Example:	DECLARE @ErrCode INT = 0, @ErrMsg NVARCHAR(4000) = ''
				EXEC Lrf_LicenseeBetSettingUpd @CustID = 16947245, @Sporttype = 151, @Bettype = 31, @MinBet = 25, @MaxBet = 205, @MaxPerMatch = 2005, @ExistedMember = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
				SELECT @ErrCode, @ErrMsg
		
*/ 
BEGIN
 SET NOCOUNT ON
	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = getdate()

	EXEC DBAGE.bodb02.dbo.Lrf_CustomerSelCheckAllowedDownlines
		@custid = @CustID
		,@Language = 'E'
		,@ErrMsg = @ErrMsg OUTPUT
		,@ErrCode=@ErrCode OUTPUT

	IF @ErrCode <> 0 
		RETURN 
	
	CREATE TABLE #temp(custid INT PRIMARY KEY, isfinished BIT DEFAULT(0))
	INSERT INTO #temp(custid)
	SELECT custid
	FROM custinfo WITH(NOLOCK)	
	WHERE srecommend = @CustID
			AND mrecommend NOT IN (SELECT custid FROM custinfo WITH(NOLOCK)
									WHERE srecommend = @CustID AND username LIKE '%Acc%' AND roleid=3)
	BEGIN TRY
		DECLARE @ids VARCHAR(MAX), @rowcnt INT
		WHILE (1=1)
		BEGIN
			SELECT @ids = ''
	
			UPDATE TOP (10000) #temp
			SET @ids = @ids + CASE @ids WHEN '' THEN '' ELSE ',' END + CAST(custid AS VARCHAR(12))
				,isfinished = 1
			FROM #temp
			WHERE isfinished = 0

			SELECT @rowcnt = @@rowcount	

			EXEC Acc_CustSetting3rd_11 @ids = @ids, @srecommend = @CustID, @Sporttype = @Sporttype, @Bettype = @Bettype, @MinBet = @MinBet, @MaxBet = @MaxBet, @MaxPerMatch = @MaxPerMatch, @MaxPerBall = @MaxPerBall, @ExistedMember = @ExistedMember, @Enable = @Enable, @EnableDownline = @EnableDownline

			IF @rowcnt < 10000 RETURN

			WAITFOR DELAY '00:00:01'
		END

		IF @Enable = 1 AND @EnableDownline = 0 	
		BEGIN		
			IF @Sporttype BETWEEN 151 AND 153 --Racing
			BEGIN
				UPDATE Custinfo WITH(UPDLOCK,ROWLOCK)
				SET DisableHorseracing = CASE WHEN @Sporttype = 151 AND @Bettype = 31 THEN 0 ELSE DisableHorseracing END,
					DisableOpenTote = CASE WHEN @Sporttype = 151 AND @Bettype = 41 THEN 0 ELSE DisableOpenTote END,
					Disable151_AU = CASE WHEN @Sporttype = 151 AND @Bettype = 51 THEN 0 ELSE Disable151_AU END,
					Disable152_UK = CASE WHEN @Sporttype = 152 AND @Bettype = 41 THEN 0 ELSE Disable152_UK END,
					Disable152_AU = CASE WHEN @Sporttype = 152 AND @Bettype = 51 THEN 0 ELSE Disable152_AU END,
					Disable153_AU = CASE WHEN @Sporttype = 153 AND @Bettype = 51 THEN 0 ELSE Disable153_AU END	
				WHERE custid = @CustID
			END

			IF @Sporttype BETWEEN 180 AND 186 --Virtual sport
			BEGIN
				UPDATE Custinfo WITH(UPDLOCK,ROWLOCK)
				SET DisableVirtualSports = 0,
					HideVirtualSports = 0
				WHERE custid = @CustID
			END
			IF @Sporttype = 202 --Keno
			BEGIN
				UPDATE cg WITH(UPDLOCK,ROWLOCK)
				SET	IsDisabled = 0	
				FROM CustGameType cg 
				WHERE cg.CustID = @CustID AND cg.GameTypeID = @Bettype - 1500
			END
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = 'Sorry. Update process unsucessful. Please check data again'
			,@ErrCode  = 101   
					
		RETURN
	END CATCH

	DECLARE @LogSPData VARCHAR(8000)

	SELECT  @LogSPData ='<Lrf_LicenseeBetSettingUpd custid="'+ coalesce(cast(@CustID AS VARCHAR(20)),space(1))+ '" ' +
						'Sporttype="'+ coalesce(cast(@Sporttype AS VARCHAR(20)),space(1))+ '" ' +
						'Bettype="'+ coalesce(cast(@Bettype AS VARCHAR(20)),space(1))+ '" ' +
						'MinBet="'+ coalesce(cast(@MinBet AS VARCHAR(50)),space(1))+ '" ' +
						'MaxBet="'+ coalesce(cast(@MaxBet AS VARCHAR(50)),space(1))+ '" ' +
						'MaxPerMatch="'+ coalesce(cast(@MaxPerMatch AS VARCHAR(50)),space(1))+ '" ' +
						'MaxPerBall="'+ coalesce(cast(@MaxPerBall AS VARCHAR(50)),space(1))+ '" ' +
						'ApplyMember="'+ coalesce(cast(@ExistedMember AS VARCHAR(1)),space(1))+ '" ' +
						'Enable="'+ coalesce(cast(@Enable AS VARCHAR(1)),space(1))+ '" ' +
						'EnableDownline="'+ coalesce(cast(@EnableDownline AS VARCHAR(1)),space(1))+ '" ' +
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
						'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(4000)),space(1)) + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 2043, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT  @LogSPData ='<Lrf_LicenseeBetSettingUpd custid="'+ coalesce(cast(@CustID AS VARCHAR(20)),space(1))+ '" ' +
						'Sporttype="'+ coalesce(cast(@Sporttype AS VARCHAR(20)),space(1))+ '" ' +
						'Bettype="'+ coalesce(cast(@Bettype AS VARCHAR(20)),space(1))+ '" ' +
						'MinBet="'+ coalesce(cast(@MinBet AS VARCHAR(50)),space(1))+ '" ' +
						'MaxBet="'+ coalesce(cast(@MaxBet AS VARCHAR(50)),space(1))+ '" ' +
						'MaxPerMatch="'+ coalesce(cast(@MaxPerMatch AS VARCHAR(50)),space(1))+ '" ' +
						'MaxPerBall="'+ coalesce(cast(@MaxPerBall AS VARCHAR(50)),space(1))+ '" ' +
						'ApplyMember="'+ coalesce(cast(@ExistedMember AS VARCHAR(1)),space(1))+ '" ' +
						'Enable="'+ coalesce(cast(@Enable AS VARCHAR(1)),space(1))+ '" ' +
						'EnableDownline="'+ coalesce(cast(@EnableDownline AS VARCHAR(1)),space(1))+ '" ' +
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
						'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
						'ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + 
						'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1)) + '" />'
					
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 2043, 
			@TrackingValue = @LogSPData,
			@duration = @duration	
	END CATCH		
END

GO
GRANT EXECUTE ON [dbo].[Lrf_LicenseeBetSettingUpd] TO [bodbadminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Lrf_LicenseeBetSettingUpd] TO [vnteam] AS [dbo]