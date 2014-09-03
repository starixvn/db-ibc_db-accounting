ALTER PROCEDURE [dbo].[NAP_UserLog_Settle_OutrightSelByLeagueID]
	@LeagueID	INT = 0 
	,@MatchID	INT	= 0 
	,@FromDate	DATETIME
	,@ToDate	DATETIME 
AS
/*
	Created: Jamie
	Date: 20140812
	Task : View Outright LOG 
	DB: DBLog/bodb_CustomerLog
	Original:

	Revisions: 
		@FromDate & @ToDate: Event Date 
		@MatchID: = ORID of Outright 
*/
BEGIN
	SET NOCOUNT ON

	SELECT	 l.logid
			,l.logdate
			,o.username
			,la.ActionNameEN
			,l.LeagueID
			,l.MatchID
			,l.EventDate
			,l.Result
			,l.Remark
	FROM	Userlog_SettleOutright l WITH (NOLOCK)
			LEFT JOIN LogAction la WITH (NOLOCK) ON l.ActionID = la.ActionID
			LEFT JOIN bodb02.dbo.CustInfo o WITH (NOLOCK) ON o.custid = l.userid
	WHERE	l.LeagueID = CASE WHEN @LeagueID = 0 THEN l.LeagueID ELSE @LeagueID END 
			AND l.MatchID = CASE WHEN @MatchID = 0 THEN l.MatchID ELSE @MatchID END 
			AND L.EventDate BETWEEN @FromDate AND @ToDate 
	ORDER BY l.LogID ASC

END

GO
GRANT EXECUTE ON [dbo].[NAP_UserLog_Settle_OutrightSelByLeagueID] TO [bodbAdminNet]
GO

 