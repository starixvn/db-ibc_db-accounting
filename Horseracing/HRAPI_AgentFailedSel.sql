Alter PROCEDURE [dbo].[HRAPI_AgentFailedSel]
AS
--DB06.bodb02

select AgentId 
from HRTurnover with (nolock) 
where IsDone = 0 and datediff(day, current_timestamp, [Date]) = 0
order by AgentId

Go
GRANT EXECUTE ON [dbo].[HRAPI_AgentFailedSel] TO [bodbAdminNet]