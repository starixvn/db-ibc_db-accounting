-- This is a script to update Commission for All Masters & Agents under a specific Super.
-- We should consider to put ExecRep for this update with BIG SUPER
--Update Commission at Master Level
declare @groupa decimal(9,8),
	@groupb decimal(9,8),
	@groupc decimal(9,8),
	@groupd decimal(9,8),
	@discountcs decimal(9,8),
	@discount1x2 decimal(9,8),
	@srecommend int

select @srecommend = 1567557

Select 
	@groupa = groupa, 
	@groupb = groupb, 
	@groupc = groupc, 
	@groupd = groupd
from custsetting as cs with (nolock) 
where custid = @srecommend and bettype=1 and sporttype=1

--Get m3=s4 if m3>s4
Select @discountcs = sdiscount
from custsetting as cs with (nolock) 
where custid = @srecommend and bettype = 4 and sporttype = 1
---------------------------------------
--Get m3=s4 if m3>s4 --1x2 
Select @discount1x2 = sdiscount
from custsetting as cs with (nolock) 
where custid = @srecommend and bettype = 5 and sporttype = 1

update custsetting with (ROWLOCK, UPDLOCK)
set
	groupa = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupa else groupa end ,
	groupb = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupb else groupb end ,
	groupc = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupc else groupc end ,
	groupd = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupd else groupd end ,
	adiscount = case when bettype in (4,6,9,10,20,21,22) then @discountcs when bettype = 5 then @discount1x2 else adiscount end
where custid in (select custid 
                    from custinfo with (nolock)
                    where srecommend = @srecommend and roleid = 3)

--Update g3 @ member level
UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	
	adiscount = case when c.ugroup in ('a','hka') then @groupa 
					 when c.ugroup in ('b','hkb') then @groupb 
					 when c.ugroup in ('c','hkc') then @groupc 
					 when c.ugroup in ('d','hkd') then @groupd else @groupa end 
From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
WHERE c.srecommend = @srecommend
    AND c.roleid = 1
    and custsetting.bettype in (1,2,3,7,8) and sporttype <> 201

---------------------------------------
--Update m3 @ member level
UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	
	adiscount = @discountcs
From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
WHERE c.srecommend = @srecommend AND c.roleid = 1 and custsetting.bettype in (4,6,9,10,20,21,22)

---------------------------------------
--Update m3 @ member level --1x2 
UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	
	adiscount = @discount1x2
From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
WHERE c.srecommend = @srecommend AND c.roleid = 1 and custsetting.bettype = 5

 --Update Commission for Agent Level -- ======
--Update @Master: g2, a2
update custsetting with (ROWLOCK, UPDLOCK)
set
	groupa = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupa else groupa end,
	groupb = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupb else groupb end,
	groupc = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupc else groupc end,
	groupd = case when bettype in (1,2,3,7,8)  and sporttype <> 201 then @groupd else groupd end,
	discount = case when bettype in (4,6,9,10,20,21,22) then @discountcs when bettype =5 then @discount1x2 else discount end
where custid in (select custid from custinfo (nolock) where srecommend = @srecommend and roleid = 2)

--Update g2, a2 at Member level
UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	custsetting.discount = case when customer.ugroup in ('a','hka') then @groupa 
									when customer.ugroup in ('b','hkb') then @groupb 
									when customer.ugroup in ('c','hkc') then @groupc 
									when customer.ugroup in ('d','hkd') then @groupd 
									else @groupa 
								end  
From custsetting inner join customer with (NOLOCK) on custsetting.custid = customer.custid
WHERE srecommend = @srecommend AND customer.roleid = 1 and bettype in (1,2,3,7,8) and sporttype <> 201
	
--Update g2, a2 at Member level
UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET custsetting.discount = @discountcs
From custsetting inner join custinfo with (NOLOCK) on custsetting.custid = custinfo.custid
WHERE srecommend = @srecommend AND custinfo.roleid = 1 and bettype in (4,6,9,10,20,21,22)

--Update g2, a2 at Member level for 1x2 
UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	custsetting.discount = @discount1x2
From custsetting inner join custinfo with (NOLOCK) on custsetting.custid = custinfo.custid
WHERE srecommend = @srecommend AND custinfo.roleid = 1 and bettype = 5