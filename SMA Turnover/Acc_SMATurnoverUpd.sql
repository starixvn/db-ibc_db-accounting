

ALTER PROCEDURE [dbo].[Acc_SMATurnoverUpd]
	@CustID INT,
	@MatchID INT,
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Update max turnover for SMA
	DB: DBAGE/bodb02

	Revisions:
		-- 20140630@Lukas: add 1 more specific level for notification - 95% [Redmine:#18384]

	Parameter's explaination: 
	
*/
SET NOCOUNT ON
BEGIN
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SMATurnoverManagement]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'completed')
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'You are not allowed to update max turnover of a settled match.'
		RETURN
	END

	UPDATE DownlineTurnover_Setting WITH(ROWLOCK,UPDLOCK)
	SET MaxTurnover = @MaxTurnover,
		IsNotified = CASE	WHEN @MaxTurnover <> 0 AND @MaxTurnover > MaxTurnover THEN   --- reset isNotified only in case of increasing maxturnover
								CASE	WHEN (totalTurnover/@MaxTurnover)*100 < 80 THEN 0
										WHEN (totalTurnover/@MaxTurnover)*100 < 95 THEN 80
										ELSE IsNotified
								END 
							ELSE IsNotified 
					END
	WHERE CustID = @CustID AND matchid = @MatchID
	
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_SMATurnoverUpd MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" '
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
							
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @UserID,
		@Custid = @CustID,
		@ActionID = 637,
		@TrackingValue = @LogData,
		@Duration = @duration				
						
END

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverUpd] TO [vnteam] AS [dbo]
