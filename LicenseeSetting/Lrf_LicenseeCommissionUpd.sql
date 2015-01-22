ALTER PROCEDURE Lrf_LicenseeCommissionUpd 
	@CustID INT
	,@Sporttype INT
	,@Bettype INT
	,@Discount MONEY
	,@UserID INT = 0
	,@Language varchar(2) = 'E'
	,@IP varchar(15)=''
	,@ErrCode INT = 0 OUTPUT
    ,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20150121
	Task : Licensee Setting Configuration - Update Position taking [#6304]
	DB: DBCUST/CustDB
	Original:

	Revisions:

	Param's Explanation:
		
*/ 
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

			EXEC Acc_CustSetting3rd_13 @ids = @ids, @Sporttype = @Sporttype, @Bettype = @Bettype, @Discount = @Discount

			IF @rowcnt < 10000 RETURN

			WAITFOR DELAY '00:00:01'
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = 'Sorry. Update process unsucessful. Please check data again'
			,@ErrCode  = 101   
					
		RETURN
	END CATCH	

	DECLARE @LogSPData VARCHAR(8000)

	SELECT  @LogSPData ='<Lrf_LicenseeCommissionUpd custid="'+ coalesce(cast(@CustID AS VARCHAR(20)),space(1))+ '" ' +
						'Sporttype="'+ coalesce(cast(@Sporttype AS VARCHAR(20)),space(1))+ '" ' +
						'Bettype="'+ coalesce(cast(@Bettype AS VARCHAR(20)),space(1))+ '" ' +
						'Discount="'+ coalesce(cast(@Discount AS VARCHAR(50)),space(1))+ '" ' +
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
			@ActionID = 2613, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT  @LogSPData ='<Lrf_LicenseeCommissionUpd custid="'+ coalesce(cast(@CustID AS VARCHAR(20)),space(1))+ '" ' +
						'Sporttype="'+ coalesce(cast(@Sporttype AS VARCHAR(20)),space(1))+ '" ' +
						'Bettype="'+ coalesce(cast(@Bettype AS VARCHAR(20)),space(1))+ '" ' +
						'Discount="'+ coalesce(cast(@Discount AS VARCHAR(50)),space(1))+ '" ' +
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
						'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
						'ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + 
						'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1)) + '" />'
					
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 2613, 
			@TrackingValue = @LogSPData,
			@duration = @duration	
	END CATCH		
END

GO
GRANT EXECUTE ON [dbo].[Lrf_LicenseeCommissionUpd] TO [bodbadminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Lrf_LicenseeCommissionUpd] TO [vnteam] AS [dbo]
