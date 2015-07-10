select matchid, sum(case status when 'running' then 1 when'won' then 2 when 'lose' then 3 else 4 end)
from bettrans (nolock)
where winlostdate >= '10 mar 2009' and bettype < 99
and transid <= 823100537
group by matchid
order by matchid