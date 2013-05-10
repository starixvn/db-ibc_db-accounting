Declare @CustID int, @RoleID tinyint, @UserName varchar(50)
select @UserName = 'SSTMR12'
select @CustID = CustID, @RoleID = RoleID from customer with (nolock) where username = @UserName

--if @RoleID = 4
--BEGIN
--	Update custsetting set MinBet = 100, MaxBet = 5000
--	where custid in (select custid from customer with (nolock) where srecommend = @CustID and roleid <4)
--
--	Update custinfo set maxpermatch = 5000, maxpermatchb = 5000
--	where custid in (select custid from customer with (nolock) where srecommend = @CustID and roleid <4)
--	RETURN
--END

if @RoleID = 3
BEGIN
	Update custsetting set MinBet = 100, MaxBet = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)

	Update custinfo set maxpermatch = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch2 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch3 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch5 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch8 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch10 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch11 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch12 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	Update custinfo set maxpermatch99 = 10000
	where custid in (select custid from customer with (nolock) where mrecommend = @CustID and roleid <3)
	RETURN
END

