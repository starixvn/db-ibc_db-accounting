
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
*/

SET NOCOUNT ON
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
ORDER BY logdate ASC


GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_Settle_MatchSelByID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_Settle_MatchSelByID] TO [vnteam]


