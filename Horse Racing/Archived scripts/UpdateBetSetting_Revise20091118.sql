ALTER PROCEDURE [dbo].[ExecRep_07]
	@username varchar(50)
AS

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

Declare @custid int, @currency int, @roleid tinyint,
    @minbet money, @maxbet money, @maxpermatch money

select @custid = custid, @currency = currency, @roleid = roleid from custinfo with (nolock) where username = @username

if (@roleid not in (4)) 
    RETURN

CREATE TABLE #tempExchange (exchangeID int,
                minbet money, maxbet money, maxpermatch money)
                

insert into #tempExchange
SELECT 5,10,50000,300000 UNION ALL --HK$
SELECT 2,10,30000,200000 UNION ALL --RM
SELECT 13,10,50000,300000 UNION ALL --RMB
SELECT 1,10,30000,100000 UNION ALL --SD$

select @minbet = minbet, @maxbet = maxbet, @maxpermatch = maxpermatch
from #tempExchange
where exchangeID = @currency
   

if @currency not in (select exchangeID from #tempExchange)
BEGIN
    PRINT 'ERROR ACCOUNT: ' + @username
    RETURN
END

DROP TABLE #tempExchange


update custinfo
set maxpermatch151 = @maxpermatch
where custid = @custid and roleid = 4

if @custid < 100
BEGIN
    update custinfo
    set maxpermatch151 = @maxpermatch
    where srecommend = @custid and roleid = 3
END
    

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

update custsetting set	
    minbet = @minbet,
    maxbet = @maxbet
 where sporttype = 151 and bettype in (31,32,41,42)
    and custid = @custID

if @custid < 100
BEGIN
    update custsetting set	
        minbet = @minbet,
        maxbet = @maxbet
     where sporttype = 151 and bettype in (31,32,41,42)
        and custid IN (select custid from custinfo with (nolock) where srecommend = @custid and roleid = 3)
END