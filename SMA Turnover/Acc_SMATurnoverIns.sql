ALTER PROCEDURE [dbo].[Acc_SMATurnoverIns]
	@UserName NVARCHAR(100),
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
	Task : Add SMA turnover
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	Example: DECLARE @ErrCode int, @ErrMsg nvarchar(200)
			 EXEC Acc_SMATurnoverIns @UserName = 'FBH', @MatchID = 4496769, @MaxTurnover = 10000, @UserID = 8, @IP = '120.125.220.20', @ErrMsg = @ErrMsg OUTPUT, @ErrCode = @ErrCode OUTPUT
			 SELECT @ErrCode, @ErrMsg
			
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
		
	IF NOT EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE username = @UserName)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid Username!'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE username = @UserName and roleid <> 4)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Username!'
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Match ID doesn''t exist.'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'completed')
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'You are not allowed to add super into a settled match.'
		RETURN
	END		
	
	DECLARE @CustID INT

	SELECT @CustID = custid FROM custInfo WITH (NOLOCK) WHERE username = @UserName
	
	IF EXISTS (SELECT 1 FROM DownlineTurnover_Setting WITH (NOLOCK) WHERE matchid = @MatchID AND CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'This account is already added.'
		RETURN
	END

	DECLARE @LogData NVARCHAR(4000), @TotalTurnover MONEY	
	-- It has bet ticket for this match
	IF EXISTS (SELECT 1 FROM bettrans WITH (NOLOCK) WHERE matchid = @MatchID and srecommend = @CustID and statusID = 0)
	BEGIN
		SELECT @TotalTurnover = sum(actual_stake) FROM DBTXN.bodb02.dbo.bettrans WITH (NOLOCK) WHERE matchid = @MatchID and srecommend = @CustID and statusID = 0
		SELECT @TotalTurnover = isnull(@TotalTurnover,0)
		
		INSERT INTO DownlineTurnover_Setting (CustID, MatchID, MaxTurnover, TotalTurnover)
		VALUES (@CustID, @MatchID, @MaxTurnover, @TotalTurnover)
									
	END
	-- It has not bet ticket for this match
	ELSE 
	BEGIN
		SELECT @TotalTurnover = 0
		INSERT INTO DownlineTurnover_Setting (CustID, MatchID, MaxTurnover, TotalTurnover)
		VALUES (@CustID, @MatchID, @MaxTurnover, @TotalTurnover)				
	END		
	
	SELECT @LogData = '<Acc_SMATurnoverIns Username="' + COALESCE(@username, SPACE(1)) + '" ' 
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'TotalTurnover="' + COALESCE(CAST(@TotalTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" '
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'																
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @UserID,
			@Custid = @CustID,
			@ActionID = 636,
			@TrackingValue = @LogData,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_SMATurnoverIns Username="' + COALESCE(@username, SPACE(1)) + '" ' 
						+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
						+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
						+ 'TotalTurnover="' + COALESCE(CAST(@TotalTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
						+ 'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" '
						+ 'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(4000)),space(1))+ '" '
						+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
							
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @UserID,
			@Custid = @CustID,
			@ActionID = 636,
			@TrackingValue = @LogData,
			@Duration = @duration
	END CATCH
	
	-- Syn data temporary
	exec Acc_SMATurnoverSyn
END

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverIns] TO [vnteam]

