ALTER PROCEDURE NAP_SMATurnoverGlobalSettingUpd
	@CustID INT,
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	Created: 20141006@Dom
	Task: Insert new CustId to Gobal setting [Feature #21804:]
	DB: DBAGE/bodb02
	
	Revisions:
		

*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[GlobalSetting]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	DECLARE @MaxTurnover_Old MONEY, @AffectedMatch VARCHAR(1000)=''
	SELECT @MaxTurnover_Old=MaxTurnover FROM DownlineTurnOver_GlobalSetting WITH(NOLOCK) WHERE CustID=@CustID
	SELECT @AffectedMatch = @AffectedMatch + CAST(st.MatchID AS VARCHAR(20)) +',' 
	FROM DownlineTurnOver_Setting st WITH(NOLOCK) 
	INNER JOIN Match m WITH(NOLOCK) ON m.matchid = st.matchid
	WHERE CustID=@CustID
		AND m.eventstatus <> 'completed'

	IF(LEN(ISNULL(@AffectedMatch,'')) > 0)
	BEGIN
		SELECT @AffectedMatch = LEFT(@AffectedMatch,LEN(@AffectedMatch)-1)
	END

	IF @CustID <= 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
		RETURN
	END

	IF @MaxTurnover <= 0
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid MaxTurnover.'
		RETURN
	END

	UPDATE DownlineTurnOver_GlobalSetting WITH(ROWLOCK,UPDLOCK) SET MaxTurnOver = @MaxTurnover WHERE CustID=@CustID
	UPDATE st
	SET MaxTurnover = @MaxTurnover,
		IsNotified = CASE WHEN @MaxTurnover <> 0 AND @MaxTurnover > MaxTurnover THEN   --- reset isNotified only in case of increasing maxturnover
								CASE	WHEN (HouseTurnOver/@MaxTurnover)*100 < 80 THEN 0
										WHEN (HouseTurnOver/@MaxTurnover)*100 < 95 THEN 80
										ELSE IsNotified
								END 
							ELSE IsNotified 
					END
	FROM DownlineTurnover_Setting st WITH(ROWLOCK,UPDLOCK)
	INNER JOIN Match m WITH(NOLOCK) ON m.matchid = st.matchid
	WHERE CustID = @CustID
		AND m.eventstatus <> 'completed'

	DECLARE @LogData NVARCHAR(4000), @TrackingValue2 NVARCHAR(4000)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

	SELECT @LogData = '<Acc_SMATurnoverGlobalSettingUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'AffectedMatch="' + COALESCE(@AffectedMatch,space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'

	SELECT @TrackingValue2 = '<Acc_SMATurnoverGlobalSettingUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'AffectedMatch="' + COALESCE(@AffectedMatch,space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 657,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnoverGlobalSettingUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnoverGlobalSettingUpd] TO [vnteam]