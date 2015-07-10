USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminIns]    Script Date: 12/20/2012 02:17:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminIns_xpre    Script Date: 12/25/2010 7:01:55 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_AdminIns    Script Date: 12/16/2010 1:55:00 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_AdminIns] 
	@FirstName nvarchar(50),
	@LastName nvarchar(50),	
	@UserName nvarchar(50),
	@UserPwd nvarchar(50) = '',
	@CustID int OUTPUT,
	@UserID int,
	@GroupID int,	
	@IP varchar(15) = '',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
--Used to create AccAdmin
--In DB02.bodb02 --> DB052.Affiliate_12BET
SET NOCOUNT ON

/*
Created: 
Task : Add account in User control 
DB: DB02.bodb02
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20090218@PhuongDao: Check username2 
	- 20100713@Peter : Remove Write Log on IBC DB
	- 20101112@Henry: add Maxperball161
	- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET	
	- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@userid,@funcname='[UserControl]',@System = 'AFFILIATE', @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end


Declare @pwdexpiry datetime, @roleid int, @closed bit

Select @RoleID = 6,
	@pwdexpiry =  DATEADD(month,1,CURRENT_TIMESTAMP),
	@closed = 0
	
if exists(select 1 from Affiliate_User with (NOLOCK) where username=@username) 
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'This username is not available. '
						when 'CS' then N'This username is not available. '
						when 'J' then N'This username is not available. '
						else N'This username is not available. '
					end, @ErrCode = 102
	return
END

BEGIN TRANSACTION

	INSERT INTO Affiliate_User (username, UserPwd, roleid, firstname, lastname, creator, pwdexpiry,closed,GroupId,createdate) 
	VALUES (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry,@closed,@GroupID,getdate()) 

	Select @CustID = @@IDENTITY

	
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

EXEC dbo.Aff_Con_AdminPolicyIns @CustID=@Custid,@Userid=@UserID,@GroupID=@GroupID,@IP=@IP


DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'NEW AFFILIATE Admin custid:' + dbo.Aff_ToString(@custid) + ' username:' + @UserName + ' GroupID:' + dbo.Aff_ToString(@GroupID)


EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@CustID,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData