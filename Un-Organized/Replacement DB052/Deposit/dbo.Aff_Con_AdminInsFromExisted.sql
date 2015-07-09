USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminInsFromExisted]    Script Date: 12/20/2012 02:19:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminInsFromExisted_xpre    Script Date: 12/25/2010 7:01:55 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_AdminInsFromExisted    Script Date: 12/16/2010 1:55:00 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_AdminInsFromExisted]
	@username varchar(30),
	@GroupId int,
	@creator int,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2) = 'E'
AS
/*
create AccAdmin from existed Admin
DB03.bodb02 --> DB052.Affiliate_12BET
Revisions:
	- VinhTrinh@20100507: insert closed field to table affiliate_user
	- 20100713@Peter : Remove Write Log on IBC DB
	- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET	
	- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
*/
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@creator,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

Declare @custid int, @roleid int, @Closed bit,@Password varchar(40),@FirstName nvarchar(50),@LastName nvarchar(50),@pwdexpiry datetime
select @custid = custid, @roleid = roleid,@Password=userpwd,
		@FirstName=FirstName,@LastName=LastName,@pwdexpiry=pwdexpiry
from bodb02.dbo.customer c with (nolock)	
where username = @username and roleid between 5 and 10

select @custid = isnull(@custid, 0)
		, @Closed = 0
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
		if exists (select 1 from affiliate_user with (nolock) where username = @username)
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
				(createdate, creator, groupid, Closed,username,UserPwd,RoleId,PwdExpiry,FirstName,LastName)
			VALUES				
				( getdate(), @creator, @groupid, @Closed,@username,@Password,@RoleId,@PwdExpiry,@FirstName,@LastName)
			Select @custID=@@IDENTITY
				
			select @custID, @GroupId
			
			INSERT INTO AffMemberPolicy(CustID,FuncID,Policy,CreateDate,ModifyDate,Creator) 
			-- 0 is default value of the member policy  when create new admin 
			SELECT @Custid as custid,FuncID,0 as Policy,getdate() as Createdate,getdate() as ModifyDate,@creator as Creator 
			FROM AffGroupPolicy with(nolock)
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
	
END

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'NEW Affiliate Admin from Existed Admin custid:' + convert(varchar(20), @custid) + ' username:' + @UserName + ' GroupID:' + convert(varchar(20),@groupid)


EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
		@Creator=@creator,	
		@AffID=@custid,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData