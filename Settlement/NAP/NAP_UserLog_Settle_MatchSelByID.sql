USE bodb_CustomerLog
GO
ALTER PROCEDURE [dbo].[NAP_UserLog_Settle_MatchSelByID]
	@matchid INT
AS
/*
Created: Dan
Date: 2012-10-03
Task : View match Log for settlement.	
DB: DB052.bodb_CustomerLog
Original: Acc_UserLog_Settle_MatchSelByID

Revisions: 
	- 20160428@Patrick: Fast market integration [Redmine: #56367]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @DataTmp TABLE (logid BIGINT, logdate DATETIME, username VARCHAR(50), ActionNameEN NVARCHAR(100)
		, finalhomescore INT, finalawayscore INT, hthomescore INT, htawayscore INT, GoalRecord VARCHAR(50)
		, betstatus NVARCHAR(50), Remark VARCHAR(MAX), IP VARCHAR(20), ActionId INT, UserID INT)
		INSERT INTO @DataTmp(logid, logdate, username, ActionNameEN, finalhomescore, finalawayscore, hthomescore
			, htawayscore, GoalRecord, betstatus, Remark, IP, ActionId, UserID)
		SELECT l.logid, l.logdate,	o.username, la.ActionNameEN, l.finalhomescore, l.finalawayscore, l.hthomescore
			, l.htawayscore, l.GoalRecord, l.betstatus, l.Remark, l.IP, l.ActionID, l.UserID
		FROM Userlog_Settle l WITH(NOLOCK)	
			LEFT JOIN LogAction la WITH (NOLOCK) ON l.ActionID = la.ActionID
			LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
		WHERE l.matchid = @matchid
	
	SELECT a.logid, a.logdate, a.username, a.ActionNameEN, a.finalhomescore, a.finalawayscore, a.hthomescore
		, a.htawayscore, a.GoalRecord, a.betstatus, a.IP
		, STUFF((
				SELECT '' + ISNULL(CAST(aaa.Remark AS VARCHAR(MAX)), '')
				FROM @DataTmp aaa
				WHERE a.LogDate = aaa.LogDate
				FOR XML PATH (''))
			  , 1, 1, '') AS Remark
	FROM ( 
		SELECT MIN(a.logid) AS logid, ActionId, logdate, UserID
		FROM @DataTmp a
		GROUP BY ActionId, logdate, UserID
	)aa INNER JOIN @DataTmp a ON aa.logid = a.logid
	ORDER BY logdate ASC
END


GO
GRANT EXECUTE ON [dbo].[NAP_UserLog_Settle_MatchSelByID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_UserLog_Settle_MatchSelByID] TO [vnteam]


