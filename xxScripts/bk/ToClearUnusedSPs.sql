select sysobjects.name,
 case sysprotects.action
  when 224 then 'EXECUTE'
  else 'UNKNOWN'
 end,
 case sysprotects.protecttype
  when 205 then 'Grant Execute'
  when 206 then 'Deny Execute'
 end,
 sysUsers.name as username
from sysprotects 
 inner join sysUsers on sysprotects.uid = sysUsers.uid
 inner join sysobjects on sysobjects.id = sysprotects.id 
where 
sysUsers.name in ('bodbDownlineNEt', 'bodbDownlineNetView', 'bodbAdminNet', 'bodbSuperNet', 'bodbMemberNet')
and sysobjects.name NOT like 'Age[_]%'
AND  sysobjects.name NOT like 'Aff[_]%'
AND  sysobjects.name NOT like 'Acc[_]%'
AND  sysobjects.name NOT like 'DBA[_]%'
AND  sysobjects.name NOT like 'Admin_Settlement%'
AND  sysobjects.name NOT like 'DOT[_]%'
AND  sysobjects.name NOT like 'updateMatch%'
AND  sysobjects.name NOT like 'WriteLog%'
AND  sysobjects.name NOT like 'Task[_]%'
AND  sysobjects.name NOT like 'ExecRep%'
AND  sysobjects.name NOT like 'userlog%'
AND  sysobjects.name NOT like 'refund%'
AND  sysobjects.name NOT LIKE 'LoadBalance%'
AND  sysobjects.name NOT LIKE 'Agw[_]%'

and xtype = 'P'

order by sysobjects.name
