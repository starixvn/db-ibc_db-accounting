
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@username varchar(50),
	@SiteType varchar(50) = '',
	@Action varchar(50) = ''
AS

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

Declare @custid int, @currency int, @roleid tinyint,
    @minbet money, @maxbet money, @maxpermatch money,
    @maxPT smallmoney, @Comm smallmoney

select @custid = custid, @currency = currency, @roleid = roleid from custinfo with (nolock) where username = @username

if (@roleid not in (4,3,2,1)) 
    RETURN

CREATE TABLE #tempExchange (SiteFlag bit, exchangeID int,
                minbet money, maxbet money, maxpermatch money)
                
CREATE UNIQUE CLUSTERED INDEX IX_1 on #tempExchange (SiteFlag, exchangeID)

insert into #tempExchange

SELECT 0,6,10,2999,10000 UNION ALL --EURO
SELECT 0,5,10,50000,300000 UNION ALL --HK$
SELECT 0,2,10,30000,200000 UNION ALL --RM
SELECT 0,13,10,50000,300000 UNION ALL --RMB
SELECT 0,1,10,30000,100000 UNION ALL --SD$

SELECT 0,4,100,99999,500000 UNION ALL--TB
SELECT 0,43,100,99999,500000 UNION ALL --THB

SELECT 0,3,10,4999,20000 UNION ALL --US$ and other currencies with the same Rate.
SELECT 0,16,10,4999,20000 UNION ALL --YEN
SELECT 0,17,10,4999,20000 UNION ALL --NTD
SELECT 0,35,10,4999,20000 UNION ALL --$US
SELECT 0,40,10,4999,20000 UNION ALL --IRR
SELECT 0,36,10,4999,20000 UNION ALL --Y$US

SELECT 0,15,10,29999,150000 UNION ALL --IN
SELECT 0,22,10,29999,150000 UNION ALL --IND
SELECT 0,33,10,29999,150000 UNION ALL --IDD
SELECT 0,34,10,29999,150000 UNION ALL --IDR
SELECT 0,47,10,29999,150000 UNION ALL --DDD

SELECT 0,20,10,499,1500 UNION ALL --UUS, testing currency
----------------------------------------------
--DEPOSIT SITES
----------------------------------------------
SELECT 1,6,10,499,2000 UNION ALL --EURO
SELECT 1,5,10,3999,10000 UNION ALL --HK$
SELECT 1,2,10,2999,5000 UNION ALL --RM
SELECT 1,13,10,3999,10000 UNION ALL --RMB
SELECT 1,1,10,1999,5000 UNION ALL --SD$

SELECT 1,4,100,29999,50000 UNION ALL--TB
SELECT 1,43,100,29999,50000 UNION ALL --THB

SELECT 1,3,10,499,2000 UNION ALL --US$ and other currencies with the same Rate.
SELECT 1,16,10,499,2000 UNION ALL --YEN
SELECT 1,17,10,499,2000 UNION ALL --NTD
SELECT 1,35,10,499,2000 UNION ALL --$US
SELECT 1,40,10,499,2000 UNION ALL --IRR
SELECT 1,36,10,499,2000 UNION ALL --Y$US

SELECT 1,15,10,9999,30000 UNION ALL --IN
SELECT 1,22,10,9999,30000 UNION ALL --IND
SELECT 1,33,10,9999,30000 UNION ALL --IDD
SELECT 1,34,10,9999,30000 UNION ALL --IDR
SELECT 1,47,10,9999,30000 UNION ALL --DDD

SELECT 1,20,10,499,1500 --UUS, testing currency


select @minbet = minbet, @maxbet = maxbet, @maxpermatch = maxpermatch
from #tempExchange
where exchangeID = @currency
    and SiteFlag = case when @SiteType in ('12Bet-1','12Bet-2', 'Mansion88', 'AsiaBet88') then 1 else 0 end

if @SiteType in ('Mansion88', 'AsiaBet88')
BEGIN
    select @maxPT = 0, @Comm = 0.04
END
ELSE
BEGIN
    select @maxPT = 0.5, @Comm = 0.01
END


if @currency not in (select exchangeID from #tempExchange)
BEGIN
    PRINT 'ERROR ACCOUNT: ' + @username
    RETURN
END

DROP TABLE #tempExchange

if @roleid = 4
BEGIN
    update custinfo
    set maxpermatch151 = @maxpermatch,
        disableHorseracing = case @Action
                                when 'disable' then 1
                                when 'enable' then 0                                    
                                else disableHorseracing
                             end
    where srecommend = @custid
        
    Update custSuper
    set
        AutoIBCPositiontaking_Tote = CASE
                                        WHEN @SiteType='' and @currency in (16, 17, 35, 40, 43, 36, 15, 22, 33, 34, 47)  THEN 0.1
                                        WHEN @SiteType in ('Mansion88', 'AsiaBet88') THEN 0.5
                                        ELSE 0
                                     END,
        AutoIBCPositiontaking_Fixed = CASE
                                        WHEN @SiteType='' and @currency in (16, 17, 35, 40, 43, 36, 15, 22, 33, 34, 47) THEN 0.1
                                        WHEN @SiteType in ('Mansion88', 'AsiaBet88') THEN 0.5
                                        ELSE 0
                                      END
    where custid = @custid
END

if NOT exists (select * from dbo.sysobjects where name = 'custsetting3rd')
BEGIN
	RETURN
END
    
if @roleid = 4
BEGIN
    update custsetting3rd set	
        minbet = @minbet,
        maxbet = @maxbet,         
        sdiscount = @Comm,
        apositiontaking=0,mpositiontaking=0,spositiontaking=0,autopositiontaking=0,isautopositiontaking=0,playerdiscount = 0,discount =0,adiscount=0
     where sporttype = 151 and bettype in (31,32,41,42)
	    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)

    update custsetting3rd set
        apositiontaking=@maxPT, mpositiontaking=@maxPT, spositiontaking=@maxPT,sdiscount = @Comm
     where sporttype = 151 and bettype in (31,32,41,42)
	    and custid = @custid
	    
	update custoverride set 
	    minpositiontaking = 0, 
	    maxpositiontaking = @maxPT, 
	    minlivepositiontaking = 0, 
	    maxlivepositiontaking = 0
    where sporttype = 151 and bettype in (31,32,41,42)
	    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)
END

if @roleid = 3
BEGIN
    update custsetting3rd set        
        adiscount=@Comm       
     where sporttype = 151 and bettype in (31,32,41,42)
	    and custid IN (select custid from custinfo with (nolock) where mrecommend = @custid)   	
    
    update custsetting3rd set    
        apositiontaking=0, mpositiontaking=@maxPT, spositiontaking=0
     where sporttype = 151 and bettype in (31,32,41,42)
	    and custid = @custid 
END

if @roleid = 2 and @SiteType in ('12Bet-1', 'Mansion88', 'AsiaBet88')
BEGIN	
	update custsetting3rd set
	    apositiontaking=@maxPT, mpositiontaking=0, spositiontaking=0, 
        discount=@Comm       
     where sporttype = 151 and bettype in (31,32,41,42)
	    and custid IN (select custid from custinfo with (nolock) where recommend = @custid)    
		
END

if @roleid = 2 and @SiteType = '12Bet-2'
BEGIN
    update custsetting3rd set
	    apositiontaking=0, mpositiontaking=@maxPT, spositiontaking=0,          
        adiscount = @Comm
     where sporttype = 151 and bettype in (31,32,41,42)
	    and custid IN (select custid from custinfo with (nolock) where recommend = @custid)    
	    
END
