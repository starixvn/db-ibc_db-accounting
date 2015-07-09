ALTER PROCEDURE [dbo].[ExecRep_07]
	@username varchar(50)
AS

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

Declare @custid int, @roleid tinyint

select @custid = custid, @roleid = roleid
from custinfo with (nolock) where username = @username

if @roleid NOT in (4)
    RETURN
---------------------------------
UPDATE cs1
SET cs1.sdiscount = cs2.groupa,
    playerdiscount = 0,
    discount = 0,
    adiscount = 0,   
    groupa = 0,
    groupb = 0,
    groupc = 0,
    groupd = 0,
    groupe = 0,
    groupf = 0
from Custsetting cs1
	inner join custsetting cs2 (nolock) on cs1.custid = cs2.custid and cs2.sporttype = 1 and cs2.bettype = 1
where cs1.sporttype = 1 and cs1.bettype = 5
	and cs1.custid = @custid
	
UPDATE cs1
SET cs1.adiscount = cs2.groupa,
    playerdiscount = 0,
    discount = 0,    
    sdiscount = 0,
    groupa = 0,
    groupb = 0,
    groupc = 0,
    groupd = 0,
    groupe = 0,
    groupf = 0
from Custsetting cs1
    inner join custinfo ci with (nolock) on cs1.custid = ci.custid
	inner join custsetting cs2 (nolock) on cs1.custid = cs2.custid and cs2.sporttype = 1 and cs2.bettype = 1
where cs1.sporttype = 1 and cs1.bettype = 5
	and ci.srecommend = @custid and ci.roleid = 3

UPDATE cs1
SET cs1.discount = cs2.groupa,
    playerdiscount = 0,   
    adiscount = 0,
    sdiscount = 0,
    groupa = 0,
    groupb = 0,
    groupc = 0,
    groupd = 0,
    groupe = 0,
    groupf = 0
from Custsetting cs1
    inner join custinfo ci with (nolock) on cs1.custid = ci.custid
	inner join custsetting cs2 (nolock) on cs1.custid = cs2.custid and cs2.sporttype = 1 and cs2.bettype = 1
where cs1.sporttype = 1 and cs1.bettype = 5
	and ci.srecommend = @custid and ci.roleid = 2

UPDATE cs1
SET cs1.sdiscount = cs4.sdiscount,
    cs1.adiscount = cs3.adiscount,
    cs1.discount = cs2.discount,
    
    -- get the MIN value of (member discount and agent discount)
    cs1.playerdiscount = (cs_hpd.playerdiscount + cs2.discount - ABS(cs_hpd.playerdiscount-cs2.discount))/2 ,
    
    groupa = 0,
    groupb = 0,
    groupc = 0,
    groupd = 0,
    groupe = 0,
    groupf = 0
    

FROM CustSetting cs1
    inner join custinfo ci with (nolock) on cs1.custid = ci.custid
    inner join custsetting cs_hpd (nolock) on cs1.custid = cs_hpd.custid and cs_hpd.sporttype = 1 and cs_hpd.bettype = 1
    inner join custsetting cs2 with (nolock) on ci.recommend = cs2.custid and cs1.bettype = cs2.bettype
    inner join custsetting cs3 with (nolock) on ci.mrecommend = cs3.custid and cs1.bettype = cs3.bettype
    inner join custsetting cs4 with (nolock) on ci.srecommend = cs4.custid and cs1.bettype = cs4.bettype
where cs1.sporttype = 1 and cs1.bettype = 5 and ci.srecommend = @custid and roleid = 1

GO