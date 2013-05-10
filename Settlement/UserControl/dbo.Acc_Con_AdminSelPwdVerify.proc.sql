ALTER PROCEDURE [dbo].[Acc_Con_AdminSelPwdVerify]
	@Username varchar(30),
	@UserPwd nvarchar(50),
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
SET NOCOUNT ON

select @ErrCode = 0

if NOT exists (select 1 from customer c with (nolock) 
					inner join db03.bodb02.dbo.accCustomer_1 ac with (nolock) on c.custid = ac.custid
				where c.custid = @userID and username = @username and userpwd = @userpwd)
BEGIN
	select @ErrMsg = 'Wrong username or password',
		@ErrCode = 101
	return
END



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelPwdVerify] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminSelPwdVerify] TO [bodbAdminNet]
