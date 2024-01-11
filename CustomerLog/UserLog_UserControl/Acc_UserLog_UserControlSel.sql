/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER  PROCEDURE [dbo].[Acc_UserLog_UserControlSel]
	@FromDate DATETIME,
	@ToDate DATETIME,
	@Name nvarchar(50),
	@CustID INT,
	@PageIndex INT = 0,
    @PageSize INT = 5
AS
/*
	Created by: 20120605@Sophia
	Task: View lof of User Control 
	DB: DBLOG.bodb_CustomerLog
 
	Revisions:
		- 20230825@Tacy: Implement archiving data for UserLog_UserControl [redmineID: #192258]
	
	Param's Explanation:
	- @TypeID:
			0: used for Group
			1: used for Admin
	- @Name: for Group name and Admin name	
	- @PageIndex: from 0
	- @PageSize: total record per request
				
*/
BEGIN
	SET NOCOUNT ON;

	SET @PageIndex = ABS(@PageIndex)
	SET @PageSize = ABS(@PageSize)  

	DECLARE @lbound INT 
	DECLARE @ubound INT
	DECLARE @__archiveDate DATETIME
	
	DECLARE @tempLog AS TABLE (
			RowNum			INT IDENTITY(1,1),
			LogID			BIGINT,
			LogDate			DATETIME,
			TypeID			TINYINT,
			CustID			INT,
			CustName		NVARCHAR(50),
			UserID			INT,
			Username		NVARCHAR(50),
			ActionID		INT,
			ActionName		NVARCHAR(256),
			Doing			NVARCHAR(MAX)
	)

	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
	
	SET @lbound = @PageIndex * @PageSize       
	SET @ubound = @lbound + @PageSize 

	IF (@PageIndex > 0) 
		SET @lbound = @lbound + 1

	IF (@FromDate >= @__archiveDate)
	BEGIN
		INSERT INTO @tempLog (LogID, LogDate, TypeID, CustID, CustName,  
							  UserID, Username , ActionID, ActionName, Doing)
		SELECT  U.LogID, U.LogDate, U.TypeID, U.CustID, @Name,  
				U.UserID, D.Username, U.ActionID, A.ActionNameEN, U.Doing 
		FROM	UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		LEFT JOIN BODB02.dbo.Custinfo D WITH (NOLOCK) ON U.UserID = D.CustID
		WHERE U.LogDate BETWEEN @FromDate AND @ToDate
			AND U.ActionID BETWEEN 1700 AND 1799
 			AND U.CustID = @CustID 
		ORDER BY U.LogDate DESC
	END
	ELSE IF (@Todate < @__archiveDate)
	BEGIN
		INSERT INTO @tempLog (LogID, LogDate, TypeID, CustID, CustName,  
							  UserID, Username , ActionID, ActionName, Doing)
		SELECT  U.LogID, U.LogDate, U.TypeID, U.CustID, @Name,  
				U.UserID, D.Username, U.ActionID, A.ActionNameEN, U.Doing 
		FROM bodb_CustomerLog_Archive.dbo.UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		LEFT JOIN BODB02.dbo.Custinfo D WITH (NOLOCK) ON U.UserID = D.CustID
		WHERE U.LogDate BETWEEN @FromDate AND @ToDate
			AND U.ActionID BETWEEN 1700 AND 1799
 			AND U.CustID = @CustID
		ORDER BY U.LogDate DESC
	END
	ELSE
	BEGIN
		INSERT INTO @tempLog (LogID, LogDate, TypeID, CustID, CustName,  
							  UserID, Username , ActionID, ActionName, Doing)
		SELECT U.LogID, U.LogDate, U.TypeID, U.CustID, @Name,  
			   U.UserID, D.Username, U.ActionID, A.ActionNameEN, U.Doing 
		FROM UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		LEFT JOIN BODB02.dbo.Custinfo D WITH (NOLOCK) ON U.UserID = D.CustID
		WHERE U.LogDate BETWEEN @__archiveDate AND @ToDate
			AND U.ActionID BETWEEN 1700 AND 1799
 			AND U.CustID = @CustID 
		ORDER BY U.LogDate DESC

		INSERT INTO @tempLog (LogID, LogDate, TypeID, CustID, CustName,  
							  UserID, Username , ActionID, ActionName, Doing)
		SELECT  U.LogID, U.LogDate, U.TypeID, U.CustID, @Name,  
				U.UserID, D.Username, U.ActionID, A.ActionNameEN, U.Doing 
		FROM bodb_CustomerLog_Archive.dbo.UserLog_UserControl U WITH (NOLOCK)
		INNER JOIN LogAction A WITH (NOLOCK) ON A.ActionID = U.ActionID 
		LEFT JOIN BODB02.dbo.Custinfo D WITH (NOLOCK) ON U.UserID = D.CustID
		WHERE U.logdate >= @FromDate AND U.logdate < @__archiveDate
			AND U.ActionID BETWEEN 1700 AND 1799
 			AND U.CustID = @CustID
		ORDER BY U.LogDate DESC
	END

	SELECT	LogID, LogDate, TypeID, CustID, CustName,  
			UserID, Username , ActionID, ActionName, Doing
	FROM @tempLog
	WHERE RowNum BETWEEN @lbound AND @ubound
END
GO