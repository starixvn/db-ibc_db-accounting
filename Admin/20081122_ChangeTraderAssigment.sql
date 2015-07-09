select aa.id, m.matchid, m.matchcode, eventdate, h.teamname, a.teamname, 
		case	when operatortype = 1 and bettype = 1 then 1 
				when operatortype = 1 and bettype = 2 then 3 
				when operatortype = 2 and bettype = 1 then 7
				when operatortype = 2 and bettype = 2 then 8
		end bettype , c.username, operatorID, operatorType, bettype
from bodb_archive.dbo.match_bk m (nolock)
	join team h (nolock) on m.homeid =h.teamid
	join team a (nolock) on m.awayid = a. teamid
	join Dot_admin_Assignment_Operator aa (nolock) on m.matchid = aa.matchid
	join customer c (nolock) on aa.OperatorID = c.custid
where eventdate = '2008-11-15' and homeid in (450, 4479, 7751, 10201, 10317, 16558, 16559, 19181, 21568, 25704, 25705, 26563, 27715, 27806, 29038)
and operatorType <3
order by matchid,operatorType, ID

select custid, username from customer (nolock) where username = 'vvJulie'
--------------
--DB02

32967	VVJULIE

update Dot_admin_Assignment_Operator set  OperatorID = 32967 where
ID in (267174, 267177, 267175, 267178, 267180, 267183, 267181, 267184, 267186, 267189, 267187, 267190)