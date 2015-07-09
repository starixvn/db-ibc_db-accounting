USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminUpdPwd]    Script Date: 12/20/2012 02:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminUpdPwd_xpre    Script Date: 12/25/2010 7:01:53 AM ******/
/****** Object:  Stored Procedure dbo.Aff_AdminUpdPwd    Script Date: 12/16/2010 1:55:00 PM ******/
ALTER PROCEDURE [dbo].[Aff_AdminUpdPwd]  
	@CustID int,
	@UserID int,  
	@OldPwd nvarchar(50)=null,
	@UserPwd nvarchar(50),    
	@Language varchar(2)= 'en-US', 
	@IP varchar(20), 
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(2000)='' OUTPUT  
AS  
  
SET NOCOUNT ON  
--DB02.bodb02 --> DB052.Affiliate_12BET
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
--Check permission-----------------------------
-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	

if @OldPwd is null
BEGIN
		EXEC [dbo].[Aff_Con_CheckPermission] 
		@custid=@UserID,
		@funcname='[UserControl]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output
		
	If @ErrCode <> 0
		RETURN
END
	
	
if not exists(select 1 from Affiliate_User with (NOLOCK) 
				where CustID = @CustID 
				and (case when (@OldPwd is not null and UserPwd = @OldPwd) or @OldPwd is null then 1 
						else 0 end ) = 1 )
BEGIN
	Select @ErrMsg =  case @Language 
	when 'en-US' then N'Old password is incorrect' 
	when 'zh-TW' then N'舊密碼不正確.' 
	when 'zh-CN' then N'旧密码不正确' 
	when 'th-TH' then N'ใส่พาสเวิดเดิมไม่ถูกต้อง' 
	when 'es-ES' then N'La contraseña antigua es incorrecta' 
	when 'vi-VN' then N'Mật khẩu cũ không đúng'	
	when 'id-ID' then N'Kata sandi lama salah'
	else N'Old password is incorrect'
	end,
	@ErrCode = 1001
	RETURN 
END


	  
declare @PwdExpiry datetime
  
select @PwdExpiry = dateadd(dd, 30, getdate())  
UPDATE Affiliate_User  with (ROWLOCK, UPDLOCK)  
SET userpwd=@UserPwd, pwdexpiry=@PwdExpiry   
where custid=@CustID  
 
 
 --Write log
declare @SPName varchar(50),@LogData nvarchar(200)  
Select @LogData = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)
select @SPName = OBJECT_NAME(@@ProcID)
  
EXEC [DBAFF12BET].[affiliate_12bet].[dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @IP
