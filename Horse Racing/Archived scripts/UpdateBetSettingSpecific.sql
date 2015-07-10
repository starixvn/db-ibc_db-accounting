ALTER PROCEDURE [dbo].[DBA_MinMaxBetUpdHorse]
	@username varchar(50),
	@maxbet money,
	@maxpermatch money
AS


Declare @custid int, @roleid tinyint

select @custid = custid, @roleid = roleid from custinfo with (nolock) where username = @username

if (@roleid not in (4)) 
    RETURN

update custinfo
set maxpermatch151 = @maxpermatch
where srecommend = @custid
    

update custsetting set    
    maxbet = @maxbet
 where sporttype = 151 and bettype in (31,32,41,42)
    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)
GO