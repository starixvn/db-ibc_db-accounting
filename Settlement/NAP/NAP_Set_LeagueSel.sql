CREATE PROCEDURE [dbo].[NAP_Set_LeagueSel]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0
AS

/*	Creator:Dan
	Date: 20120925
	Task: select league to settle
	DB: DB02.bodb02
	Original: Acc_Set_LeagueSel
	
	Rivision:			
	
	Param's Explanation:
		
		
*/
SET NOCOUNT ON
if @sporttype = 0
begin 
	select DISTINCT league.leagueid, leaguename, match.sporttype
	from match with (nolock)
		inner join league with (nolock) on match.leagueid = league.leagueid
	where match.eventdate between @FromDate and @ToDate and match.sporttype <> 162

	UNION 
	
	SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
	FROM outright o (nolock)
		INNER JOIN league l (nolock) on o.leagueid = l.leagueid 
	WHERE o.eventdate between @FromDate and @ToDate
		and l.sporttype BETWEEN  151 AND 153 
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
GRANT EXECUTE ON [dbo].[NAP_Set_LeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_LeagueSel] TO [VNTeam]