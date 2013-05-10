Declare @custid int, @groupd float, @playerdiscount float
select @custid = ,
		@groupd = ,
		@playerdiscount = 

UPDATE customer WITH (ROWLOCK, UPDLOCK)
SET
	ugroup = 'd'
WHERE custid in (select custid from customer where customer.recommend = @custid AND customer.roleid = 1)

update custsetting with (ROWLOCK, UPDLOCK)	 SET
	groupd = case when bettype in (1,2,3,7,8) then @groupd else 0 end
	--,discount =  case when bettype in (4,5,6,9,10,20,21,22) then @discountcs else 0 end	
where custid=@custid

UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	custsetting.discount = case when custsetting.bettype in (1,2,3,7,8) then @groupd else custsetting.discount end 
From custsetting inner join customer with (NOLOCK) on custsetting.custid = customer.custid
WHERE customer.recommend = @custid AND customer.roleid = 1

UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
SET	
	playerdiscount = CASE WHEN bettype IN (1,2,3,7,8) THEN @playerdiscount ELSE playerdiscount END
WHERE custid in (select custid from customer where customer.recommend = @custid AND customer.roleid = 1)

-------------------------------------

Declare @custid int, @discountcs float, @playerdiscountcs float
select @custid = ,
		@discountcs = ,
		@playerdiscountcs = 


update custsetting with (ROWLOCK, UPDLOCK) SET	
	discount =  case when bettype in (4,5,6,9,10,20,21,22) then @discountcs else discount end	
where custid=@custid

UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	custsetting.discount = case when custsetting.bettype NOT in (1,2,3,7,8) then @discountcs else custsetting.discount end 
From custsetting inner join customer with (NOLOCK) on custsetting.custid = customer.custid
WHERE customer.recommend = @custid AND customer.roleid = 1

UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
SET	
	playerdiscount = CASE WHEN bettype NOT IN (1,2,3,7,8) THEN @playerdiscountcs ELSE playerdiscount END
WHERE custid in (select custid from customer where customer.recommend = @custid AND customer.roleid = 1)

--------------------------------
--TROEU
--Change to group HKD all members
--Shift to IBCBET
--Pre-create 50 member, start from troeu101 to troeu150
Declare @custid int, @groupd float, @playerdiscount float
select @custid = 64810,
		@groupd = 0.01 

Update customer WITH (ROWLOCK, UPDLOCK)
SET site = 'BEST-ODDS'
WHERE custid = @custid

UPDATE customer WITH (ROWLOCK, UPDLOCK)
SET
	ugroup = 'hkd'
WHERE custid in (select custid from customer where customer.recommend = @custid AND customer.roleid = 1)

update custsetting with (ROWLOCK, UPDLOCK)	 SET
	groupd = case when bettype in (1,2,3,7,8) then @groupd else 0 end	
where custid=@custid

UPDATE custsetting with (ROWLOCK, UPDLOCK) 
SET 	custsetting.discount = case when custsetting.bettype in (1,2,3,7,8) then @groupd else custsetting.discount end 
From custsetting inner join customer with (NOLOCK) on custsetting.custid = customer.custid
WHERE customer.recommend = @custid AND customer.roleid = 1