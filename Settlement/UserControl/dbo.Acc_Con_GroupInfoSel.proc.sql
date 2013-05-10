ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoSel]
	@GroupID int=null,
	@System nvarchar(50) = 'ACCOUNTING'
AS 
SET NOCOUNT ON  
IF @groupid is null
BEGIN
	
	if(@System='ACCOUNTING')
	BEGIN
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from acc_groupinfo_1  gi with(nolock)
			LEFT JOIN AccCustomer_1 ac with(nolock) on ac.groupid=gi.groupid
		where system = @System
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.displayorder ,gi.groupname 
	END
	Else if (@System='AFFILIATE')
	Begin
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from acc_groupinfo_1  gi with(nolock)
			LEFT JOIN Affiliate_User ac with(nolock) on ac.groupid=gi.groupid
		where system = @System
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.displayorder ,gi.groupname 
	End
	
END
ELSE
BEGIN
	If(@system='ACCOUNTING')
	BEGIN
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from acc_groupinfo_1  gi with(nolock)
			LEFT JOIN AccCustomer_1 ac with(nolock) on gi.groupid=ac.groupid	
   		WHERE gi.groupid=@groupid 
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.displayorder ,gi.groupname
	END
	ELSE if (@System='AFFILIATE')
	BEGIN
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from acc_groupinfo_1  gi with(nolock)
			LEFT JOIN Affiliate_User ac with(nolock) on gi.groupid=ac.groupid	
   		WHERE gi.groupid=@groupid 
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.displayorder ,gi.groupname
	END
END



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoSel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].Acc_Con_GroupInfoSel TO [bodbAdminNet]