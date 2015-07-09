-- =============================================
-- Script Template
-- =============================================
Declare @matchid int
select @matchid = 363822

Update bettrans set ruben = 0, status = 'running',
	winlost = 0, awinlost = 0, mwinlost = 0, swinlost = 0,
	playercomm = 0, comm = 0, acomm = 0, scomm = 0
where matchid = @matchid and status in ('WON', 'DRAW', 'LOSE')

Update match set eventstatus = 'closed'
where matchid = @matchid
					
--------------
select transid, status, username, betteam, odds, hdp2-hdp1,stake from
bettrans (nolock)
where matchid = 363822 and liveindicator = 1
and 
 (
(transdate > '2008-09-15 12:03:05.017' and transid <= 629959868)
or (transid between 629947494 and 629949448)
or (transdate > '2008-09-15 12:34:07.283' and transid <= 629993576)
or (transdate > '2008-09-15 12:42:01.550' and transid <= 630001969)
or (transdate > '2008-09-15 12:53:15.923' and transid <= 630011879)
or (transdate > '2008-09-15 13:00:06.127' and transid <= 630018184)
or (transdate > '2008-09-15 13:17:39.580' and transid <= 630039020)
)

order by transid

-------------
CREATE TABLE #ul (logid int, userid int, doing nvarchar(300), logdate datetime) 
	INSERT INTO #ul
SELECT logid, userid, doing, logdate 
from userlog (nolock) where logdate between '2008-09-15 11:55' and '2008-09-15 13:30'
and doing like '%363822%'
order by 1 

select * from #ul 
where doing like '%delete%' or doing like '%update accept%'

order by logdate

2008-09-15 12:03:05.017
629959868

delete bet for matchid 363822 from 629947494 to 629949448

2008-09-15 12:34:07.283
629993576

2008-09-15 12:42:01.550
until 630001969

2008-09-15 12:53:15.923
630011879

2008-09-15 13:00:06.127
630018184
	
2008-09-15 13:17:39.580
 630039020
-