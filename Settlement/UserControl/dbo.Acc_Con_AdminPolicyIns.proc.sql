ALTER PROCEDURE [dbo].[Acc_Con_AdminPolicyIns]
	@CustID int, 
	@UserID int,
	@GroupID int,
	@System varchar(50) = 'ACCOUNTING'
AS

if @System = 'ACCOUNTING'
	INSERT INTO accCustomer_1 (custid, createdate, creator,groupid)
	VALUES (@custid, getdate(), @UserID,@GroupID) 
else if @System = 'AFFILIATE'
	INSERT INTO Affiliate_User (custid, createdate, creator,groupid)
	VALUES (@custid, getdate(), @UserID,@GroupID) 

INSERT INTO Acc_MemberPolicy_1(CustID,FuncID,Policy,CreateDate,ModifyDate,Creator) 
	SELECT @Custid as custid,FuncID,
		-- 0 is default value of the member policy  when create new admin
		0 as Policy, getdate() as Createdate, getdate() as ModifyDate,@UserID as Creator 
	FROM Acc_GroupPolicy_1 with(nolock)
	WHERE GroupId=@GroupID



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminPolicyIns] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminPolicyIns] TO [bodbAdminNet]