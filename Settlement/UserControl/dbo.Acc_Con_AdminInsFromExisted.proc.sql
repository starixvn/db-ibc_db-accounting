ALTER PROCEDURE [dbo].[Acc_Con_AdminInsFromExisted]
	@username varchar(30),
	@GroupId int,
	@creator int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2) = 'E',
	@System varchar(50)='ACCOUNTING'
AS
--create AccAdmin from existed Admin
--DB03
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@creator,@funcname='[UserControl]',@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

Declare @custid int, @roleid int
select @custid = custid, @roleid = roleid
from customer c with (nolock)	
where username = @username and roleid between 5 and 10

select @custid = isnull(@custid, 0)

if @custid = 0
BEGIN
	select @ErrMsg = case @Language 
							when 'E' then 'Invalid username.'
							when 'CS' then N'Invalid username.'
							when 'J' then N'Invalid username.'
							else N'Invalid username.'
						end, @ErrCode = 101	
	return	
END
else
BEGIN
	
	IF(@System='ACCOUNTING')
	begin
		--------------------
		if exists (select custid from accCustomer_1 with (nolock) where custid = @custid)
		BEGIN
			select @ErrMsg = case @Language 
								when 'E' then 'This user has been existed as an accounting admin before.'
								when 'CS' then N'This user has been existed as an accounting admin before.'
								when 'J' then N'This user has been existed as an accounting admin before.'
								else N'This user has been existed as an accounting admin before.'
							end, @ErrCode = 102	
			return
		END
		ELSE
		BEGIN
			-- add existed admin
			BEGIN TRANSACTION 
			INSERT INTO accCustomer_1
				(CustID, createdate, creator, groupid)
			VALUES
				(@custid, getdate(), @creator, @groupid)
			INSERT INTO Acc_MemberPolicy_1(CustID,FuncID,Policy,CreateDate,ModifyDate,Creator) 
			-- 0 is default value of the member policy  when create new admin 
			SELECT @Custid as custid,FuncID,0 as Policy,getdate() as Createdate,getdate() as ModifyDate,@creator as Creator 
			FROM Acc_GroupPolicy_1 with(nolock)
			WHERE GroupId=@GroupID
			if @@ERROR <> 0
			BEGIN
				ROLLBACK TRANSACTION
				select @ErrMsg = case @Language 
									when 'E' then 'Add customer failed.'
									when 'CS' then N'Add customer failed.'
									when 'J' then N'Add customer failed.'
									else N'Add customer failed.'
								end, @ErrCode = 103
				return
			END	
			COMMIT TRANSACTION
		END
		-----------------------
	end
	if(@System='AFFILIATE')
	begin
		if exists (select custid from affiliate_user with (nolock) where custid = @custid)
		BEGIN
			select @ErrMsg = case @Language 
								when 'E' then 'This user has been existed as an affiliate admin before.'
								when 'CS' then N'This user has been existed as an affiliate admin before.'
								when 'J' then N'This user has been existed as an affiliate admin before.'
								else N'This user has been existed as an affiliate admin before.'
							end, @ErrCode = 102	
			return
		END
		ELSE
		BEGIN
			-- add existed admin
			BEGIN TRANSACTION 
			INSERT INTO affiliate_user
				(CustID, createdate, creator, groupid)
			VALUES
				(@custid, getdate(), @creator, @groupid)
			
			INSERT INTO Acc_MemberPolicy_1(CustID,FuncID,Policy,CreateDate,ModifyDate,Creator) 
			-- 0 is default value of the member policy  when create new admin 
			SELECT @Custid as custid,FuncID,0 as Policy,getdate() as Createdate,getdate() as ModifyDate,@creator as Creator 
			FROM Acc_GroupPolicy_1 with(nolock)
			WHERE GroupId=@GroupID
			if @@ERROR <> 0
			BEGIN
				ROLLBACK TRANSACTION
				select @ErrMsg = case @Language 
									when 'E' then 'Add customer failed.'
									when 'CS' then N'Add customer failed.'
									when 'J' then N'Add customer failed.'
									else N'Add customer failed.'
								end, @ErrCode = 103
				return
			END	
			COMMIT TRANSACTION
		END
	end
	
	
END

declare @LogData nvarchar(200)
Select @LogData = 'NEW ' + @System + ' Admin from Existed Admin custid:' + convert(varchar(20), @custid) + ' username:' + @UserName + ' GroupID:' + convert(varchar(20),@groupid)

EXEC LOG.bodb02.dbo.WriteLog_UserLog @UserID = @creator, @Doing = @LogData




GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminInsFromExisted] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminInsFromExisted] TO [bodbAdminNet]