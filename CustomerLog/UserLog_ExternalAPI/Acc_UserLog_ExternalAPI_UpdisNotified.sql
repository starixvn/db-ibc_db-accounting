/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_ExternalAPI_UpdisNotified]
@LogIDs		VARCHAR(MAX)= ''
AS
/*
Created: 20160823@Jamie
Task : Get currency information by Currency Name [RedmineID:#65873]
DB: DBLOG.bodb_CustomerLog 
Original:

Revisions:

Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON 

	--//active range
	UPDATE	UserLog_ExternalAPI WITH (UPDLOCK,ROWLOCK)
	SET		isNotified = 1
	WHERE	LogID IN (SELECT CAST(RTRIM(LTRIM(Val)) AS BIGINT) FROM strSplit(@LogIDs,','))

	--//archive range
	UPDATE	bodb_CustomerLog_Archive.dbo.UserLog_ExternalAPI WITH (UPDLOCK,ROWLOCK)
	SET		isNotified = 1
	WHERE	LogID IN (SELECT CAST(RTRIM(LTRIM(Val)) AS BIGINT) FROM strSplit(@LogIDs,','))
END

GO