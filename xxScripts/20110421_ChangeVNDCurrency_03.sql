--update custsub
UPDATE [dbo].[custsub] WITH (ROWLOCK, UPDLOCK)
set username = replace (username, 'Q', 'INH')
WHERE custid in (select custid 
					from custinfo(nolock) 
					where srecommend IN (51,3167456,3167631,3167992,3287311,3287405,3353831,3353983,3417070,3417217,3651223,3663860) 
							and roleid =2)
							

--Update custSearch db052.bodb02
update custSearch WITH (ROWLOCK, UPDLOCK)
set username = replace (username, 'Q', 'INH')
where username like '%Q%'

--Update crmCustomer db06.bodb_CRM
update crmCustomer WITH (ROWLOCK, UPDLOCK)
set username = replace (username, 'Q', 'INH')
where username like '%Q%'


/*
--Check valid data

select count(1) from custinfo(nolock) 
where srecommend IN (51,3167456,3167631,3167992,3287311,3287405,3353831,3353983,3417070,3417217,3651223,3663860)  
and username like '%Q%'

select count(1) from customer(nolock) 
where srecommend IN (51,3167456,3167631,3167992,3287311,3287405,3353831,3353983,3417070,3417217,3651223,3663860)  
and username like '%Q%'

select COUNT(1) from custsub(nolock) 
WHERE custid in (select custid 
					from custinfo(nolock) 
					where srecommend IN (51,3167456,3167631,3167992,3287311,3287405,3353831,3353983,3417070,3417217,3651223,3663860) 
							and roleid =2)
AND username like '%Q%'
*/


----

WHILE (1=1)
BEGIN
	UPDATE TOP(5000) [dbo].[sum_winloss_old] WITH (ROWLOCK, UPDLOCK)
	set username = replace (username, 'Q', 'INH')
	WHERE srecommend IN (51,3167456,3167631,3167992,3287311,3287405,3353831,3353983,3417070,3417217,3651223,3663860)  
		and username like '%Q%'
		and winlostdate >= '2010-11-03 00:00:00'
	IF @@ROWCOUNT < 5000
		BREAK
	WAITFOR DELAY '000:00:00.200'	
END
----

WHILE (1=1)
BEGIN
	UPDATE TOP(5000) [dbo].[rptLicWinlost] WITH (ROWLOCK, UPDLOCK)
	set username = replace (username, 'Q', 'INH')
	WHERE srecommend IN (51,3167456,3167631,3167992,3287311,3287405,3353831,3353983,3417070,3417217,3651223,3663860)  
		and username like '%Q%'
		and currency = 51
	IF @@ROWCOUNT < 5000
		BREAK
	WAITFOR DELAY '000:00:00.200'	
END