/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_UserControlSelTotalRecords]    
	@FromDate DATETIME,
	@ToDate DATETIME,
	@CustID INT
AS 
/*	Created:20120606@Sophia
    Task: Calculate total records for view log user control
	DB: DBLOG.bodb_CustomerLog
 
	Revisions:
		- 20230825@Tacy: Implement archiving data for UserLog_UserControl [redmineID: #192258]

    Param's Explaination:    
		- @TypeID:
				0: used for Group
				1: used for Admin
		- @Name: for Group name and Admin name	
		- @PageIndex: from 0
		- @PageSize: total record per request
	
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @__archiveDate DATETIME , @cnt INT
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	IF (@FromDate >= @__archiveDate)
	BEGIN
		SELECT	@cnt=COUNT(U.LogID)      
		FROM	UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		WHERE	U.LogDate BETWEEN @FromDate AND @ToDate
				AND U.ActionID BETWEEN 1700 AND 1799
 				AND U.CustID = @CustID  
	END
	ELSE IF (@Todate < @__archiveDate)
	BEGIN
		SELECT	@cnt=COUNT(U.LogID)      
		FROM	bodb_CustomerLog_Archive.dbo.UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		WHERE	U.LogDate BETWEEN @FromDate AND @ToDate
				AND U.ActionID BETWEEN 1700 AND 1799
 				AND U.CustID = @CustID
	END
	ELSE
	BEGIN
		SELECT	@cnt=COUNT(U.LogID)      
		FROM	UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		WHERE	U.LogDate BETWEEN @__archiveDate AND @ToDate
				AND U.ActionID BETWEEN 1700 AND 1799
 				AND U.CustID = @CustID  
		
		SELECT	@cnt+=COUNT(U.LogID)      
		FROM	bodb_CustomerLog_Archive.dbo.UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		WHERE	U.logdate >= @FromDate AND U.logdate < @__archiveDate
				AND U.ActionID BETWEEN 1700 AND 1799
 				AND U.CustID = @CustID 
	END

	SELECT @cnt
END
GO
