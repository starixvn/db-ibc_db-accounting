USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoUpd]    Script Date: 12/20/2012 02:37:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoUpd_xpre    Script Date: 12/25/2010 7:02:00 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoUpd    Script Date: 12/16/2010 1:55:01 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_FuncInfoUpd]
	@FuncId int,
	@FuncName nvarchar(50),
	@FuncNote nvarchar(2000) = null,
	@FuncDesc nvarchar(50) = '',
	@FileNames nvarchar(2000),	
	@Language varchar(2)= 'E',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserId int
AS
/*DB03.BODB02-->DB052.Affiliate_12BET */
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	

SET NOCOUNT ON
	--Check permission
		EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
	If @ErrCode <> 0
		RETURN
	IF exists (select 1 from AffFunctionInfo with (NOLOCK) where system ='AFFILIATE' and FuncName = @FuncName and FuncId <> @FuncId)
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then N'This function name is already used.'
							when 'CS' then N'This function name is already used.'
							else N'This function name is already used.'
					end, @ErrCode = 101	
		return
	END 
		
	update AffFunctionInfo with (rowlock)
	set FuncName = @FuncName, FuncNote = @FuncNote, FuncDesc = @FuncDesc, ModifyDate = getdate(), FileNames = @FileNames
	where FuncID = @FuncId
	
	--Write log
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] Update functioninfo:' + dbo.Aff_ToString(@FuncId)	
	
	
	EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=0,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData