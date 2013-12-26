ALTER PROCEDURE [dbo].[Acc_AccAdminSelOnline]
	@ServerID int
AS
/*
	DB: DBONUSER/ON_USER
*/
if @ServerID = 200001
BEGIN
	select DISTINCT null as roleid, c.custid
	from 
		bodb02.dbo.accCustomer_1 c with (nolock)
		INNER JOIN on_user o with (nolock) ON c.custid=o.custid
	where ServerID = @ServerID
	order by roleid desc
END
else
BEGIN
	select 0 as roleid, on_user.custid
	from on_user with (nolock)
	where ServerID = @ServerID
END

GO
GRANT EXECUTE ON [dbo].[Acc_AccAdminSelOnline] TO [bodbAdminNet]