/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_Settle_MatchSelByID]
	@matchid INT
AS
/*
Created: Daniel
Date: 2009-12-25
Task : View match Log for settlement.	
DB: DBLog.bodb_CustomerLog
Original:

Revisions:
	- 20190405@Patrick: Support archive date range [Redmine: #111476]
*/

SET NOCOUNT ON

DECLARE @__archiveDate DATETIME
SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

SELECT 
	l.logid,
	l.logdate,	
	o.username,
	la.ActionNameEN,
	l.finalhomescore,
	l.finalawayscore,  
	l.hthomescore,
	l.htawayscore,
	l.GoalRecord,
	l.betstatus,
	l.Remark,
	l.IP
FROM Userlog_Settle l WITH(NOLOCK)	
	LEFT JOIN LogAction la WITH (NOLOCK) ON l.ActionID = la.ActionID
	LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
WHERE l.matchid = @matchid
	AND l.LogDate >= @__archiveDate

UNION ALL
SELECT 
	l.logid,
	l.logdate,	
	o.username,
	la.ActionNameEN,
	l.finalhomescore,
	l.finalawayscore,  
	l.hthomescore,
	l.htawayscore,
	l.GoalRecord,
	l.betstatus,
	l.Remark,
	l.IP
FROM bodb_CustomerLog_Archive.dbo.Userlog_Settle l WITH(NOLOCK)	
	LEFT JOIN LogAction la WITH (NOLOCK) ON l.ActionID = la.ActionID
	LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
WHERE l.matchid = @matchid
	AND l.LogDate < @__archiveDate
ORDER BY logdate ASC

GO
