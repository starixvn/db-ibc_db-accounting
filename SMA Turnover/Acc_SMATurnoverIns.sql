ALTER PROCEDURE [dbo].[Acc_SMATurnoverIns]
	@UserID INT,
	@ListSMA XML,
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
		- 20130712@Elodie: Support multiple insert
		
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
		
	DECLARE @tblCust TABLE (	
		Seq INT, 	
		CustID INT,
		MatchID INT,
		MaxTurnover MONEY		
	)

	INSERT INTO @tblCust(Seq, CustID, MatchID, MaxTurnover)				
	SELECT	T.C.value('./@Seq', 'int'),  
			T.C.value('./@CustID', 'int'),
			T.C.value('./@MatchID', 'int'),
			T.C.value('./@MaxTurnover', 'money')
	FROM @ListSMA.nodes('/ListSMA/SMA') AS T(C)
				
	IF EXISTS (SELECT 1 FROM DownlineTurnOver_Setting ds WITH (NOLOCK) INNER JOIN @tblCust t ON t.CustID = ds.custid and t.MatchID = ds.matchid)				
	BEGIN
		SELECT username, ds.matchid
		FROM DownlineTurnOver_Setting ds WITH (NOLOCK) 
			INNER JOIN @tblCust t ON t.CustID = ds.custid and t.MatchID = ds.matchid
			INNER JOIN custInfo c ON c.custid = t.CustID
		RETURN
	END
	ELSE
	BEGIN
		SELECT '' username, 0 matchid WHERE 0 = 1
	END	
	
	INSERT INTO DownlineTurnover_Setting (CustID, MatchID, MaxTurnover, TotalTurnover)
	SELECT CustID, MatchID, MaxTurnover, 0
	FROM @tblCust
	
	IF @@Error <> 0
	BEGIN
		SELECT	@ErrCode = 100,
				@ErrMsg = 'Insert SMA List unsuccessfully.'
		RETURN
	END
	
	DECLARE @LogData NVARCHAR(4000), @MaxSeq INT, @i INT
	DECLARE @CustID INT, @MatchID INT, @MaxTurnover MONEY
	SELECT @MaxSeq = max(Seq) from @tblCust		
	SELECT @i = 1															
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		while (@i<=@MaxSeq)
		BEGIN			
			SELECT @CustID = CustID, @MatchID = MatchID, @MaxTurnover = MaxTurnover from @tblCust where Seq = @i
			
			SELECT @LogData = '<Acc_SMATurnoverIns MatchID="'+ COALESCE(CAST(@MatchID as varchar(10)),space(1)) + '" '
						+ 'MaxTurnover="'+ COALESCE(CAST(@MaxTurnover as varchar(20)),space(1)) + '" '
						+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
						+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" '
						+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
						
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,			
				@ActionID = 636,
				@CustID = @CustID,
				@TrackingValue = @LogData,
				@Duration = @duration
			SELECT @i = @i + 1 				
		END				
	END TRY
	BEGIN CATCH
		while (@i<=@MaxSeq)
		BEGIN
			SELECT @CustID = CustID, @MatchID = MatchID, @MaxTurnover = MaxTurnover from @tblCust where Seq = @i
			
			SELECT @LogData = '<Acc_SMATurnoverIns MatchID="'+ coalesce(cast(@MatchID as varchar(10)),space(1)) + '" '
							+ 'MaxTurnover="'+ coalesce(cast(@MaxTurnover as varchar(20)),space(1)) + '" '
							+ 'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(4000)),space(1))+ '" '
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
								
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,	
				@ActionID = 636,
				@CustID = @CustID,
				@TrackingValue = @LogData,
				@Duration = @duration
			SELECT @i = @i + 1 				
		END	
	END CATCH
	
END

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverIns] TO [vnteam]

