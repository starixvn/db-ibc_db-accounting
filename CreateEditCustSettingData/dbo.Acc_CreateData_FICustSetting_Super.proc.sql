ALTER PROCEDURE [dbo].[ExecRep_07]	
AS

--Pay attention to deploy Aff_CustomerInsAffiliate_1 and Dot_Dep_CustomerInsMember_Ag

if NOT exists (select * from dbo.sysobjects where name = 'CustSetting3rd')
BEGIN
	RETURN
END

declare @temp table (custid int, roleid tinyint)

insert into @temp (custid, roleid)
select custid, roleid 
from custinfo with (nolock) where srecommend = 20

delete CustSetting3rd where sporttype = 201 and bettype = 3 and custid in (select custid from @temp)

delete CustOverride3rd where sporttype = 201 and bettype = 3 and custid in (select custid from @temp)


Update custinfo set maxpermatch201 = maxpermatch2 where srecommend = 20

------------------------------------------------------------------------------
--Financial (201) have only Over/Under(3) are added above
------------------------------------------------------------------------------


INSERT INTO CustSetting3rd
                      (bettype, sporttype, custid, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, 
                      adiscount, sdiscount, groupa, groupb, groupc, groupd, minbet, maxbet, autopositiontaking, isautopositiontaking)
select 3, 201, cs.custid, apositiontaking, mpositiontaking, spositiontaking,
					
					playerdiscount,					
					discount,                     
                    adiscount,					
                    sdiscount,                    
                    groupa,                   
                    groupb,
                    groupc,                     
                    groupd,                    
                    minbet, maxbet, autopositiontaking, isautopositiontaking                    
from custsetting cs with(nolock)
where  sporttype = 2 and bettype = 1 and custid in (select custid from @temp)



--Cust Override
insert into CustOverride3rd
(custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
select custid, 3, 201, minpositiontaking, maxpositiontaking
from CustOverride with(nolock)
where  sporttype = 2 and bettype = 1 and custid in (select custid from @temp)

Declare @temp_comm smallmoney

update cs set
	@temp_comm = groupa,
	sdiscount = @temp_comm,
	playerdiscount = 0, 
	discount =0 ,
	adiscount =0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0
from CustSetting3rd cs 
where cs.sporttype = 201 and cs.bettype = 3	and custid in (select custid from @temp where roleid = 4)

update cs set
	@temp_comm = groupa,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount =@temp_comm,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0
from CustSetting3rd cs 
where cs.sporttype = 201 and cs.bettype = 3	and custid in (select custid from @temp where roleid = 3)

update cs set
	@temp_comm = groupa,
	sdiscount = 0,
	playerdiscount = 0, 
	discount = @temp_comm ,
	adiscount = 0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0
from CustSetting3rd cs 
where cs.sporttype = 201 and cs.bettype = 3	and custid in (select custid from @temp where roleid = 2)

GO




