/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet,bodbLicenseeNet,Dot_Admin,Dot_Member" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[WriteLog_UserLog_ExternalAPI_UpdResponse]
	 @LogID			BIGINT  
    ,@ReturnValue	NVARCHAR(MAX)= ''
	,@ReturnCode	INT = 0 
AS
/*
	Creator: 20160809@Jamie 
	Task: Insert API calling statistic
	DB: DBLOG.BODB_CUSTOMERLOG

	Revisions:
		20190411@Lukas: archive a part of old log records to new database [Redmine: #111476]
	Param's Explanation:
		@ReturnValue: Returned value of API
		@ReturnCode: Returned code of API: <>0 failed, 0 succeeded.
*/

BEGIN 
	SET NOCOUNT ON
	SET ANSI_NULLS ON

	DECLARE @__archiveDate DATETIME 
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	UPDATE [UserLog_ExternalAPI] WITH (UPDLOCK,ROWLOCK)
	SET	StatusID		= 1		-- Repond 
		,ModifiedDate	= CURRENT_TIMESTAMP
		,ReturnCode		= @ReturnCode
		,ReturnValue	= @ReturnValue
	WHERE	LogID = @LogID 
		AND LogDate >= @__archiveDate

	IF @@ROWCOUNT = 0
	BEGIN
		UPDATE bodb_CustomerLog_Archive.dbo.[UserLog_ExternalAPI] WITH (UPDLOCK,ROWLOCK)
		SET	StatusID		= 1		-- Repond 
			,ModifiedDate	= CURRENT_TIMESTAMP
			,ReturnCode		= @ReturnCode
			,ReturnValue	= @ReturnValue
		WHERE	LogID = @LogID 
			AND LogDate < @__archiveDate
	END
END
GO
