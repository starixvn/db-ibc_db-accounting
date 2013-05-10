ALTER PROCEDURE [dbo].[Acc_Con_AdminSelByGroupID]
	@Groupid int=null,
	@Username varchar(30)='%',
	@FirstChar nvarchar(6)='%',
	@System varchar(50) = 'ACCOUNTING'	
--Search username: '%username%'
--Search first char:
--A: 'A%'
--B: 'B%'
--0-9: '[0-9]%'

AS 
SET NOCOUNT ON

if @System = 'ACCOUNTING'
BEGIN
	IF @Groupid is null
	BEGIN
		SELECT gi.groupname,ac.groupid,c.custid, c.username, c.firstname, c.lastname,
			ci.closed,ac.createdate,ct.username as creator
		FROM customer c with (nolock)
			INNER JOIN custinfo ci with (nolock) on c.custid = ci.custid
			INNER JOIN acccustomer_1 ac with (nolock) on c.custid = ac.custid
			INNER JOIN acc_groupinfo_1 gi with(nolock) on ac.groupid=gi.groupid
			LEFT JOIN customer ct with(nolock) on ac.creator=ct.custid
		WHERE c.username like @Username and c.username like @FirstChar
		ORDER BY IsNull(ci.closed, 0), c.username,ac.groupid
	END
	ELSE
	BEGIN
		SELECT gi.groupname,ac.groupid,c.custid, c.username, c.firstname, c.lastname,
			ci.closed,ac.createdate,ct.username as creator
		FROM customer c with (nolock)
			INNER JOIN custinfo ci with (nolock) on c.custid = ci.custid
			INNER JOIN (select * from acccustomer_1 with(nolock) where groupid=@groupid) ac on c.custid = ac.custid
			INNER JOIN acc_groupinfo_1 gi with(nolock) on ac.groupid=gi.groupid
			LEFT JOIN customer ct with(nolock) on ac.creator=ct.custid
		WHERE c.username like @Username and c.username like @FirstChar 
		ORDER BY IsNull(ci.closed, 0), c.username,ac.groupid
	END
END
else if @System = 'AFFILIATE'
BEGIN
	IF @Groupid is null
	BEGIN
		SELECT gi.groupname,ac.groupid,c.custid, c.username, c.firstname, c.lastname,
			ci.closed,ac.createdate,ct.username as creator
		FROM customer c with (nolock)
			INNER JOIN custinfo ci with (nolock) on c.custid = ci.custid
			INNER JOIN Affiliate_User ac with (nolock) on c.custid = ac.custid
			INNER JOIN acc_groupinfo_1 gi with(nolock) on ac.groupid=gi.groupid
			LEFT JOIN customer ct with(nolock) on ac.creator=ct.custid
		WHERE c.username like @Username and c.username like @FirstChar
		ORDER BY IsNull(ci.closed, 0), c.username,ac.groupid
	END
	ELSE
	BEGIN
		SELECT gi.groupname,ac.groupid,c.custid, c.username, c.firstname, c.lastname,
			ci.closed,ac.createdate,ct.username as creator
		FROM customer c with (nolock)
			INNER JOIN custinfo ci with (nolock) on c.custid = ci.custid
			INNER JOIN (select * from Affiliate_User with(nolock) where groupid=@groupid) ac on c.custid = ac.custid
			INNER JOIN acc_groupinfo_1 gi with(nolock) on ac.groupid=gi.groupid
			LEFT JOIN customer ct with(nolock) on ac.creator=ct.custid
		WHERE c.username like @Username and c.username like @FirstChar 
		ORDER BY IsNull(ci.closed, 0), c.username,ac.groupid
	END
END


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelByGroupID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].Acc_Con_AdminSelByGroupID TO [bodbAdminNet]