INSERT INTO tempLogins (CustID, LoginDate, IsWap)

select  userID custid, convert(varchar(10),logdate, 120) LoginDate,
case when doing like '%WAP:%' then 1 else 0 end IsWap
 from userlog (nolock) where
	(doing like '%Success SID:%' 
	or doing like '%Result:Success ServerID:%')
	and logdate between '2008-10-13' and '2008-10-14'


select max(logdate), min(logdate) from userlog (nolock)

-----------

Update tempLogins set Site = ag.Site
from tempLogins T
	inner join custinfo c (nolock) on T.Custid = c.custid
	inner join customer ag (nolock) on Ag.custid = c.recommend
where c.RoleID = 1

----------------

select  LoginDate, 
case when site NOT in ('12Bet', 'asiabet88') then 'IBC' else site end + 
case  isWap when 1 then '-WAP' else '' end  Site, IsWap
, count(*) NoOfLogin
from tempLogins (nolock)
group by LoginDate, 
case when site NOT in ('12Bet', 'asiabet88') then 'IBC' else site end
, IsWap
order by logindate, 
2, isWap