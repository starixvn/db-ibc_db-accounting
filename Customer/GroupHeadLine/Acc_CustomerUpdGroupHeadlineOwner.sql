ALTER PROCEDURE [dbo].[Acc_CustomerUpdGroupHeadlineOwner]
	@HeadlineID INT,
	@OwnerName VARCHAR(30),
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(500) = '' OUTPUT,
	@Language VARCHAR(2)= 'E',
	@IP VARCHAR(15) = ''
AS
/*	
	Created: Elodie
	Date: 2016-06-10
	Task : Update headline type  
	DB: DBACC/bodb02
	Original:  
	
	Revisions:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
	SET @StartRun = GETDATE()

	Declare @Old_OwnerID INT, @Old_OwnerName VARCHAR(30) = '', @OwnerID INT = 0, @GroupID SMALLINT = 0

	--Check permission for account site 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @CustID=@UserID, @funcname='[SMAManagement]', @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @HeadlineID AND roleid BETWEEN 1 AND 4)
	BEGIN
		SELECT @ErrMsg = 'Customer is not valid.'
			 , @ErrCode = 101
		RETURN
	END

	IF @OwnerName = ''
	BEGIN
		SELECT @OwnerID = NULL
	END
	ELSE
	BEGIN
		SELECT @OwnerID = custid FROM dbo.custInfo WITH (NOLOCK) WHERE username = @OwnerName AND roleid BETWEEN 1 AND 4

		IF @OwnerID = 0
		BEGIN
			SELECT @ErrMsg = 'Invalid username.'
				 , @ErrCode = 102
			RETURN
		END
	END

	EXEC Acc_CustomerSelCheckEnable @CustID = @HeadlineID, @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 
		RETURN

	SELECT @Old_OwnerName = ci.username, @GroupID = GroupID 
	FROM dbo.custInfo ci WITH (NOLOCK) 
		LEFT JOIN dbo.CustGroupHeadline hl WITH (NOLOCK) ON ci.custid = hl.OwnerID AND hl.CustID = @HeadlineID 
	
	IF @Old_OwnerName <> ''
	BEGIN
		UPDATE  CustGroupHeadline WITH (ROWLOCK, UPDLOCK) 
		SET		OwnerID = @OwnerID
		WHERE	CustID = @HeadlineID
	END
	ELSE
	BEGIN
		INSERT INTO dbo.CustGroupHeadline( CustID, GroupID, OwnerID, HeadlineType)
		SELECT @HeadlineID, 0, @OwnerID, NULL
	END
	---Write log 
	DECLARE @LogSPData NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)

	SELECT @LogSPData = '<Acc_CustomerUpdGroupHeadlineType CustID="' + CONVERT (VARCHAR(20), @HeadlineID) + '" ' + 
			'GroupID="' + CONVERT (VARCHAR(20), @GroupID) + '" ' + 
			'Owner="' + CONVERT (VARCHAR(3), @OwnerName) + '" ' +
			'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
			'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
			'ErrMsg="' + @ErrMsg + '" />'

	SELECT @TrackingValue2 = '<Acc_CustomerUpdGroupHeadlineType CustID="' + CONVERT (VARCHAR(20), @HeadlineID) + '" ' + 
			'GroupID="' + CONVERT (VARCHAR(20), @GroupID) + '" ' + 
			'Owner="' + CONVERT (VARCHAR(3), @Old_OwnerName) + '" ' +
			'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
			'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
			'ErrMsg="' + @ErrMsg + '" />'

	SET @EndRun = getdate()
	SET @Duration  = DATEDIFF(millisecond,@StartRun,@EndRun)

	/*623	Acc_CustomerUpdConsolidatedGroup	Update Consolidated Group*/
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @HeadlineID,
		@ActionID = 661,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = NULL,
		@Duration = @Duration
END
		 
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdGroupHeadlineOwner] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdGroupHeadlineOwner] TO [vnteam]