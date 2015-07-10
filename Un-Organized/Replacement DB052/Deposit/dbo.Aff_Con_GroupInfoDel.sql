USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupInfoDel]    Script Date: 12/20/2012 02:39:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupInfoDel_xpre    Script Date: 12/25/2010 7:02:00 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_GroupInfoDel    Script Date: 12/16/2010 1:55:01 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_GroupInfoDel]
	@GroupID int,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int,
	@IP varchar(15) = ''
AS
/*DB03.BODB02 --> DB052.Affiliate_12BET*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	

SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
If @ErrCode <> 0
	RETURN
--end

IF exists (select 1 from affiliate_user with (NOLOCK) where GroupID = @GroupID) 
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N' This group has customer belong to, so you cannot delete!'
					when 'CS' then N' This group has customer belong to, so you cannot delete!'
					else N' This group has customer belong to, so you can not delete!'
			end, @ErrCode = 102
	return
END	
	
DELETE FROM AffGroupPolicy where GroupID=@GroupID
DELETE FROM AffGroupInfo where GroupID=@GroupID


	--Write log
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] Delete GroupID:' + dbo.Aff_ToString(@groupid)

	
	EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=0,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData