ALTER PROCEDURE [dbo].[Acc_Con_AdminSelByCustID]
	@CustID int,
	@System varchar(50) = 'ACCOUNTING'
AS
if @System = 'ACCOUNTING'
	SELECT c.custid,c.username,c.firstname,c.lastname,ac.groupid, c.roleid, ci.closed,c.userpwd
	FROM AccCustomer_1 ac with(nolock)
		INNER JOIN Customer c with(nolock) on c.custid=ac.custid
		INNER JOIN Custinfo ci with(nolock) on c.custid=ci.custid
	WHERE	ac.custid=@custid
else if @System = 'AFFILIATE'
	SELECT c.custid,c.username,c.firstname,c.lastname,ac.groupid, c.roleid, ci.closed,c.userpwd
	FROM Affiliate_User ac with(nolock)
		INNER JOIN Customer c with(nolock) on c.custid=ac.custid
		INNER JOIN Custinfo ci with(nolock) on c.custid=ci.custid
	WHERE	ac.custid=@custid




GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelByCustID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].Acc_Con_AdminselbyCustID TO [bodbadminnet]