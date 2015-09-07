ALTER PROCEDURE [dbo].[WriteLog_UserLog_SettleMetricGaming]
	@userid		INT
	,@matchid	INT
	,@actionid	INT
	,@VendorID	INT = 5
	,@ResultID	INT = 0
	,@Remark	VARCHAR(4000) = ''
	,@ip		VARCHAR(30)= ''
AS
	/*
		Created: Johnson
		Date: 2015-07-13
		Task: write log settlement for Metric Gaming
		DB: DBLOG & DBTXN/bodb_CustomerLog
		
		Revisions:
		
		Parameter's Explanation:
		
	*/
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO dbo.UserLog_Settle3rd
	(	
		LogDate,
		UserID,
		MatchID,
		ActionID,
		ResultID,
		VendorID,		
		Detail,
		IP
	) 
	VALUES
	(	
		GETDATE(),
		@userid,
		@matchid,
		@actionID,
		@ResultID,
		@VendorID,
		@Remark,
		@IP
	)
END
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_SettleMetricGaming] TO [bodbAdminNet]
 