USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[_DEL_Is_GetMatchDetails]    Script Date: 12/13/2012 03:56:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[_DEL_Is_GetMatchDetails]
	@matchid int
AS
/*
Created: 24 Dec 2009 @ Ken Hoang
Task : Get detailed information of trouble match
DB:  DB06.bodb02

Revisions:    	
	- 20121213@Dan: Change linked server from DB052-->DBEXT	
              
*/
SET NOCOUNT ON
BEGIN  

select h.teamname home,a.teamname away, m.matchcode, m.eventdate ,l.leaguename, m.eventstatus, m.kickofftime
	from match m with(nolock)
		inner join team h with(nolock) on m.homeid = h.teamid
		inner join team a with(nolock) on m.awayid = a.teamid
		inner join league l with(nolock) on m.leagueid = l.leagueid
	where m.matchid = @matchid

select logid, userid, username, logdate, doing
from userlog l with(nolock) 
	inner join custinfo c with(nolock) on l.userid = c.custid
where extend = @matchid and
	(doing like 'Cal%' or doing like 'GoalRecord:%' or doing like 'Undo settle%')
order by logid

select 'db02' as db,
	isnull(sum(case when status='running' then 1 else 0 end),0) as running,
	isnull(sum(case when status='won' then 1 else 0 end),0) as won,
	isnull(sum(case when status='lose' then 1 else 0 end),0) as lose,
	isnull(sum(case when status not in ('running', 'won', 'lose') then 1 else 0 end),0) as other
from DB02.bodb02.dbo.bettrans b with(nolock)
where bettype < 99
	and matchid = @matchid
UNION ALL
select 'db052',
	isnull(sum(case when status='running' then 1 else 0 end),0),
	isnull(sum(case when status='won' then 1 else 0 end),0),
	isnull(sum(case when status='lose' then 1 else 0 end),0),
	isnull(sum(case when status not in ('running', 'won', 'lose') then 1 else 0 end),0)
from DBEXT.bodb02.dbo.bettrans b with(nolock)
where bettype < 99
	and matchid = @matchid
UNION ALL
select 'db06',
	isnull(sum(case when status='running' then 1 else 0 end),0),
	isnull(sum(case when status='won' then 1 else 0 end),0),
	isnull(sum(case when status='lose' then 1 else 0 end),0),
	isnull(sum(case when status not in ('running', 'won', 'lose') then 1 else 0 end),0)
from bettrans b with(nolock)
where bettype < 99
	and matchid = @matchid
	
END

