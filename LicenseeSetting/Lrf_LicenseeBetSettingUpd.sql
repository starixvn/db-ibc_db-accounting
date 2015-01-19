ALTER PROCEDURE [dbo].[Lrf_LicenseeBetSettingUpd] 
	@CustID INT
	,@Sporttype INT
	,@Bettype INT
	,@MinBet MONEY
	,@MaxBet MONEY
	,@MaxPerMatch MONEY
	,@MaxPerBall MONEY = 0
	,@ExistedMember BIT
	,@Enable BIT = 0
	,@EnableDownline BIT = 0
	,@UserID INT = 0
	,@Language varchar(2) = 'E'
	,@IP varchar(15)=''
	,@ErrCode INT = 0 OUTPUT
    ,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
BEGIN
 SET NOCOUNT ON
	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = getdate()

	EXEC DBAGE.bodb02.dbo.Lrf_CustomerSelCheckAllowedDownlines
		@custid = @CustID
		,@Sporttype = @Sporttype
		,@Language = 'E'
		,@ErrMsg = @ErrMsg OUTPUT
		,@ErrCode=@ErrCode OUTPUT

	IF @ErrCode <> 0 
		RETURN 

	EXEC Acc_CustSetting3rd_11 @srecommend = @CustID, @Sporttype = @Sporttype, @Bettype = @Bettype, @MinBet = @MinBet, @MaxBet = @MaxBet, @MaxPerMatch = @MaxPerMatch, @MaxPerBall = @MaxPerBall, @ExistedMember = @ExistedMember, @Enable = @Enable, @EnableDownline = @EnableDownline

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