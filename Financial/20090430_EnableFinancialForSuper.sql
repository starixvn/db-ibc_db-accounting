
ALTER PROCEDURE [dbo].[ExecRep_07]
	@username varchar(50)
AS
----------------
---IT"S WRONG WITH DB SERVER WHICH GOT CUSTINFO BUT NOT CUSTSETTING
----------------

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

Declare @custid int, @currency int, @roleid tinyint, @maxbet money, @maxpermatch money, @disableFinancial bit

select @custid = custid, @currency = currency, @roleid = roleid, @disableFinancial = disableFinancial from custinfo with (nolock) where username = @username

if (@roleid not in (4,3,2,1)) --or @disableFinancial = 0
    RETURN

declare @tempExchange table (exchangeID int, maxbet money, maxpermatch money) 
insert into @tempExchange
Select 35, 300, 12000 UNION ALL
Select 9, 500, 20000 UNION ALL
Select 21, 200, 8000 UNION ALL
Select 41, 400, 16000 UNION ALL
Select 6, 300, 12000 UNION ALL
Select 12, 200, 8000 UNION ALL
Select 5, 2400, 96000 UNION ALL
Select 33, 4700, 188000 UNION ALL
Select 34, 5200, 208000 UNION ALL
Select 15, 3500, 140000 UNION ALL
Select 22, 4400, 176000 UNION ALL
Select 40, 300, 12000 UNION ALL
Select 32, 31000, 1240000 UNION ALL
Select 30, 10100, 404000 UNION ALL
Select 17, 300, 12000 UNION ALL
Select 37, 300, 12000 UNION ALL
Select 42, 14400, 576000 UNION ALL
Select 31, 30400, 1216000 UNION ALL
Select 2, 1100, 44000 UNION ALL
Select 13, 2100, 84000 UNION ALL
Select 1, 500, 20000 UNION ALL
Select 4, 10700, 428000 UNION ALL
Select 3, 300, 12000 UNION ALL
Select 36, 300, 12000 UNION ALL
Select 16, 300, 12000 UNION ALL
Select 20, 1000, 40000

select @maxbet = maxbet, @maxpermatch = maxpermatch
from @tempExchange
where exchangeID = @currency

if @currency not in (select exchangeID from @tempExchange)
BEGIN
    select @maxbet = 1, @maxpermatch = 100
END	

if @roleid = 4
BEGIN
    update custsetting set	
        minbet=1,
        maxbet=@maxbet,
        sdiscount = 0.0025,
        apositiontaking=0,mpositiontaking=0,spositiontaking=0,alivepositiontaking=0,mlivepositiontaking=0,slivepositiontaking=0,autopositiontaking=0,autolivepositiontaking=0,isautopositiontaking=0,isautolivepositiontaking=0,playerdiscount = 0,discount =0,adiscount=0,groupa = 0,groupb = 0,groupc = 0,groupd = 0,groupe = 0,groupf = 0
     where sporttype = 201 and bettype in (2,3)
	    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)
    	
    update custoverride set 
	    minpositiontaking = 0, 
	    maxpositiontaking = 0.5, 
	    minlivepositiontaking = 0, 
	    maxlivepositiontaking = 0
    where sporttype = 201 and bettype in (2,3)
	    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)

    update custsetting set    
        apositiontaking=0.5, mpositiontaking=0.5, spositiontaking=0.5,sdiscount = 0.0025
     where sporttype = 201 and bettype in (2,3)
	    and custid = @custid

    update custinfo set maxpermatch201 = @maxpermatch
    where srecommend = @custid

    update custinfo set disableFinancial = 0
    where custid = @custid
END

if @roleid = 3
BEGIN
    update custsetting set        
        adiscount=0.0025       
     where sporttype = 201 and bettype in (2,3)
	    and custid IN (select custid from custinfo with (nolock) where mrecommend = @custid)   	
    

    update custsetting set    
        apositiontaking=0, mpositiontaking=0.5, spositiontaking=0
     where sporttype = 201 and bettype in (2,3)
	    and custid = @custid
    

    update custinfo set disableFinancial = 0
    where custid = @custid 
END

if @roleid = 2
BEGIN
    update custsetting set        
        discount=0.0025       
     where sporttype = 201 and bettype in (2,3)
	    and custid IN (select custid from custinfo with (nolock) where recommend = @custid)   	
    

    update custsetting set    
        apositiontaking=0.5, mpositiontaking=0, spositiontaking=0
     where sporttype = 201 and bettype in (2,3)
	    and custid = @custid
    

    update custinfo set disableFinancial = 0
    where custid = @custid 
END

if @roleid = 1
BEGIN
    update custsetting set        
        playerdiscount=0.0025       
     where sporttype = 201 and bettype in (2,3)
	    and custid = @custid	
    

    update custsetting set    
        apositiontaking=0, mpositiontaking=0, spositiontaking=0
     where sporttype = 201 and bettype in (2,3)
	    and custid = @custid
    

    update custinfo set disableFinancial = 0
    where custid = @custid 
END



GO
