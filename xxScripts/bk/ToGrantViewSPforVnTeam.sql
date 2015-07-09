 select 'GRANT VIEW DEFINITION ON '+name+' TO vnTeam'
from sysobjects 
where sysobjects.name like 'Age[_]%'
OR  sysobjects.name like 'Aff[_]%'
OR  sysobjects.name like 'Acc[_]%'
OR  sysobjects.name like 'Agw[_]%'
OR  sysobjects.name like 'DBA[_]%'
OR  sysobjects.name like 'DOT[_]%'
order by name