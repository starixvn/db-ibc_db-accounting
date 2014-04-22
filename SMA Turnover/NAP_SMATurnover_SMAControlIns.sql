ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlIns]
	@SMAName VARCHAR(30),
	@Offset INT,

	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Add configure TO setting by SMA
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlIns @SMAName = 'SuperTest1', @Value = -5, @UserID = 8, @IP ='10.10.8.56'
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = '[ConfigureTOBySMA]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	DECLARE @SMAID INT, @roleID INT, @srecommend INT, @mrecommend INT, @recommend INT
	SELECT @SMAID = NULL
	SELECT @SMAID = CustID, @roleID = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM bodb02.dbo.Customer WITH (NOLOCK)
	WHERE username = @SMAName
		AND CustID NOT IN (SELECT CustID FROM bodb02.dbo.Dep_CustSuper WITH (NOLOCK))
	
	IF @SMAID IS NULL OR @roleID > 4
	BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Username!'
			RETURN
	END
	ELSE
	BEGIN
		IF (@roleID = 4 AND EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @SMAID))
			OR (@roleID = 3 AND NOT EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @srecommend))
			OR (@roleID = 2 AND NOT EXISTS (SELECT 1 FROM DBACC.bodb_ACC.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @mrecommend))
			OR @roleID = 1
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Username!'
			RETURN
		END		
	END

	IF EXISTS (SELECT 1 FROM DownlineTo_SMAControl WHERE SMAID = @SMAID)
	BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'The setting of this customer already existed!'
			RETURN
	END

	INSERT INTO DownlineTo_SMAControl (SMAID, Offset)
	VALUES (@SMAID, @Offset)	

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnover_SMAControlIns SMAName="' + COALESCE(@SMAName, SPACE(1)) + '" ' 					
					+ 'Offset="' + COALESCE(CAST(@Offset AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
														
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30004,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<NAP_SMATurnover_SMAControlIns SMAName="' + COALESCE(@SMAName, SPACE(1)) + '" ' 					
					+ 'Offset="' + COALESCE(CAST(@Offset AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ ERROR_MESSAGE() + '" />'		

		EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 30004,
				@TrackingValue = @LogData,
				@Duration = @duration		
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlIns] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlIns] TO [vnteam]