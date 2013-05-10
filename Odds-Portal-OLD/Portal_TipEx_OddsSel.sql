ALTER PROCEDURE [dbo].[Portal_TipEx_OddsSel]
	@timestamp int = 0
AS
/*	
	Task : Get XML Odds for TipEx
	DB: DB06.bodb02
	Revisions:	
		- 20100216@viet: Remove LIVE odds
*/
SET NOCOUNT ON

DECLARE @m TABLE (matchid int, matchcode nvarchar(50), kickofftime datetime, eventstatus nvarchar(50), showtime nvarchar(50), homeid int, awayid int, leagueid int, LivePeriod tinyint, LiveTimer datetime)
 
INSERT INTO @m
	SELECT m.matchid, UPPER(matchcode) matchcode, kickofftime, eventstatus, showtime, homeid, awayid, leagueid,
		IsNull(LivePeriod, 0) LivePeriod, IsNull(LiveTimer, '01 JAN 2000') LiveTimer
	FROM dbo.match m with (nolock)
		LEFT OUTER JOIN dbo.match_remark r with (nolock) ON m.matchid = r.matchid
	WHERE eventstatus = 'running' AND kickofftime > DATEADD(hour,-4,CURRENT_TIMESTAMP)

SET NOCOUNT OFF
SELECT
	l.leaguenametc as sporttypename,
	l.sporttype,
	eventstatus, dateadd(hh, 12, kickofftime) as kickofftime, matchcode,
	o.matchid,l.leagueid,  
	h.teamname AS Home,h.teamnamec AS Homec,h.teamnamec_uni AS Homec_uni,
	a.teamname AS Away,a.teamnamec AS Awayc,a.teamnamec_uni AS Awayc_uni, l.leaguename AS LeagueName, l.leaguenamec, l.leaguenamec_uni,	
	o.oddsid, o.bettype, oddsstatus,
	CAST(com1 as money) com1, CAST(comx as money) comx, CAST(com2 as money) com2,
	hdp1, hdp2, o.livehomescore, o.liveawayscore, o.liveindicator,
	odds1a  ,odds2a  ,odds1b  ,odds2b  ,odds1c  ,odds2c  ,odds1d  ,odds2d  ,odds1e  ,odds2e  ,odds1f  ,odds2f  ,
	odds1hka,odds2hka,odds1hkb,odds2hkb,odds1hkc,odds2hkc,odds1hkd,odds2hkd,odds1hke,odds2hke,odds1hkf,odds2hkf,
	oddsspreada, oddsspreadb, oddsspreadc, oddsspreadd, oddsspreade, oddsspreadf,
	IsNull(changetime, DATEADD(minute,-10, CURRENT_TIMESTAMP)) changetime,
	dbo.f_DateTime_UnixTime(changetime) as [timestamp],
	newoffersetup, site2,
	LivePeriod, LiveTimer,
	IsNull(o.liveindicator,0) as Live
FROM @m m --(nolock)
	INNER JOIN team h (nolock) on m.homeid = h.teamid
	INNER JOIN team a (nolock) ON m.awayid = a.teamid
	INNER JOIN league l (nolock) ON m.leagueid = l.leagueid
	INNER JOIN odds o (nolock) ON m.matchid = o.matchid
	--INNER JOIN oddsOrder r (nolock) ON o.oddsid = r.oddsid
WHERE
	o.oddsstatus NOT IN ('closed','internal','suspend')
	AND o.bettype IN (1,3,5)
	AND m.kickofftime > CURRENT_TIMESTAMP 
	AND IsNull(o.liveindicator,0) = 0
	and (l.sporttype = 1 or l.leaguename like '%BASKETBALL%')
	and dbo.f_DateTime_UnixTime(changetime) > @timestamp 
ORDER BY m.matchcode, m.matchid, o.bettype

GO
GRANT EXECUTE ON [dbo].[Portal_TipEx_OddsSel] TO [Portal]
GO
GRANT VIEW DEFINITION ON [dbo].[Portal_TipEx_OddsSel] TO [vnteam]