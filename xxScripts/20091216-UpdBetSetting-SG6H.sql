-- 20091216 - Update Min Bet, Max Bet, Max Per Match of super SG6H to 0

Declare @CustID int, @RoleID tinyint, @UserName varchar(50)
select @UserName = 'SG6H'
select @CustID = CustID, @RoleID = RoleID from custinfo with (nolock) where username = @UserName

if @RoleID = 4
BEGIN
	Update custsetting set MinBet = 0, MaxBet = 0
	where custid in (select custid from custinfo with (nolock) where srecommend = @CustID and roleid <4)
	and sporttype=99

	
	Update custinfo set maxpermatch99 = 0
	where custid in (select custid from custinfo with (nolock) where srecommend = @CustID and roleid <4)
	RETURN
END


