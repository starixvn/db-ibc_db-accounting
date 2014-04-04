ALTER PROCEDURE [Acc_Set_LeagueSel]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0
AS

/*	Creator: unknown
	Date: unidentify
	Task: select league to settle
	DB: DB02.bodb02
	
	Rivision:	
		- Vinh@20080115: add filter by sporttype
		- PhuongDao@20090114 : HR Meeting
		- 20111004@Viet: sort by leaguename
		- 20111125@Jamie: Include Greyhounds and Harness 
		- 20120208@Lukas: Exclude Live Casino
		- 20130408@Lukas: add virtual horse racing
		- 20131125@Elodie: Add Virtual Greyhounds, Motor Racing
		- 20140403@Kathy: Add Virtual Speedway (183), Virtual Virtual Cycling (185)	[Redmine:#14142]
	Param's Explanation:
		
		
*/
SET NOCOUNT ON
if @sporttype = 0
begin 
	select DISTINCT league.leagueid, leaguename, match.sporttype
	from match with (nolock)
		inner join league with (nolock) on match.leagueid = league.leagueid
	where match.eventdate between @FromDate and @ToDate and match.sporttype <> 162

	UNION ALL
	
	SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
	FROM outright o (nolock)
		INNER JOIN league l (nolock) on o.leagueid = l.leagueid 
	WHERE o.eventdate between @FromDate and @ToDate
		and l.sporttype BETWEEN  151 AND 153 
	
	
	UNION ALL
	--- virtual horse racing
	SELECT DISTINCT r.leagueid, l.leaguename, l.sporttype
	FROM VSoutright o (nolock)
		INNER JOIN VSRaceinfo r WITH(NOLOCK) ON o.eventID = r.eventID
		INNER JOIN league l (nolock) on r.leagueid = l.leagueid 
	WHERE o.eventdate between @FromDate and @ToDate
		and l.sporttype in (181,182,183,184,185)
	order by sporttype, leaguename
	
end 
else if @sporttype IN (151,152,153) 
begin 
	SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
	FROM outright o (nolock)
		INNER JOIN league l (nolock) on o.leagueid = l.leagueid 
	WHERE o.eventdate between @FromDate and @ToDate
		and l.sporttype =  @sporttype 
	order by sporttype, leaguename
end 
else if @sporttype in (181,182,183,184,185)
begin 
	SELECT DISTINCT r.leagueid, l.leaguename, l.sporttype
	FROM VSoutright o (nolock)
		INNER JOIN VSRaceinfo r WITH(NOLOCK) ON o.eventID = r.eventID
		INNER JOIN league l (nolock) on r.leagueid = l.leagueid 
	WHERE o.eventdate between @FromDate and @ToDate
		and l.sporttype = @sporttype
	order by sporttype, leaguename
end 
else 
begin 
	select DISTINCT league.leagueid, leaguename, match.sporttype
	from match with (nolock)
		inner join league with (nolock) on match.leagueid = league.leagueid
	where match.eventdate between @FromDate and @ToDate
		and match.sporttype = @sporttype
	order by leaguename
end
GO
GRANT EXECUTE ON [dbo].[Acc_Set_LeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_LeagueSel] TO [VNTeam]