USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoDel]    Script Date: 12/20/2012 02:34:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoDel_xpre    Script Date: 12/25/2010 7:01:59 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoDel    Script Date: 12/16/2010 1:55:00 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_FuncInfoDel]
	@FuncID int,
	@Language VARCHAR(2)= 'E', 
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int
AS
/*DB03.BODB02 --> DB052.Affiliate_12BET*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	

SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

if exists (select 1 from AffFunctionInfo with (nolock) where ParentId = @FuncId and ParentId <> FuncId)
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Error occurs. This function has sub function belong to, so you can not delete!'
					when 'CS' then N'Error occurs. This function has sub function belong to, so you can not delete!'
					else N'Error occurs. This function has sub function belong to, so you can not delete!'
			end, @ErrCode = 102
	return
END
BEGIN TRANSACTION
	DELETE FROM AffGroupPolicy where FuncId=@FuncId
	DELETE FROM AffMemberPolicy where FuncId=@FuncId
	DELETE FROM AffFunctionInfo where FuncId=@FuncId
	IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			select @ErrMsg = case @Language 
						when 'E' then 'Delete function failed.'
						when 'CS' then N'Delete function failed.'
						when 'J' then N'Delete function failed.'
						else N'Delete function failed.'
					end, @ErrCode = 103
			return
		END
COMMIT TRANSACTION
	
DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = '[AFFILIATE] Delete FunctionID:' + dbo.Aff_ToString(@FuncId)


EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=0,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData