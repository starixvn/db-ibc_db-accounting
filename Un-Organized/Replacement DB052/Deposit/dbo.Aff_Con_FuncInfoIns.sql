USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoIns]    Script Date: 12/20/2012 02:35:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoIns_xpre    Script Date: 12/25/2010 7:01:59 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoIns    Script Date: 12/16/2010 1:55:00 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_FuncInfoIns]
	@FuncId int output,
	@FuncName nvarchar(50),
	@FuncNote nvarchar(2000) = null,
	@FuncDesc nvarchar(50) = '',
	@DisplayOrder int = 1,
	@ParentId int = null,
	@FileNames nvarchar(2000),
	@IP varchar(15) = '',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int 
AS
/*DB03.BODB02-->DB052.Affiliate_12BET*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	

SET NOCOUNT ON
	--Check permission for account site
		EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
	If @ErrCode <> 0
		RETURN
	--end
	--Check funcname
	if exists (select 1 from AffFunctionInfo with (nolock) where System = 'AFFILIATE' and FuncName = @FuncName)
		begin
			Select @ErrMsg = 	case @Language 
					when 'E' then N'This function name is already used.'
					when 'CS' then N'This function name is already used.'
					else N'This function name is already used.'
			end, @ErrCode = 102
			return
		end
	if @ParentId is not null
		begin
			if not exists (select 1 from AffFunctionInfo with (nolock) where FuncId = @ParentId and FuncId = ParentId)
			begin
				Select @ErrMsg = 	case @Language 
					when 'E' then N'Parent function does not exist or is invalid.'
					when 'CS' then N'Parent function does not exist or is invalid.'
					else N'Parent function does not exist or is invalid.'
				end, @ErrCode = 102
				return
			end
		end
		
	BEGIN TRANSACTION
		if @ParentId is not null
			select @DisplayOrder = max(DisplayOrder)+1 from AffFunctionInfo with (nolock) where ParentID = @ParentId
		else
			select @DisplayOrder = 1

		insert into AffFunctionInfo(FuncName, FuncNote, FuncDesc, FuncRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentId, FileNames, System)
		values (@FuncName, @FuncNote, @FuncDesc, 3, getdate(), getdate(), @DisplayOrder, @UserId, isnull(@ParentId, ident_current('AffFunctionInfo')), @FileNames,'AFFILIATE')	


		
		select @FuncId = @@IDENTITY
		--Insert data to acc_grouppolicy table
		if @ParentId is not null
			begin			
				--Insert into AffGroupPolicy and AccCustomer
				insert into AffGroupPolicy(FuncId, GroupId, Policy, CreateDate, ModifyDate, Creator)
				select @FuncId, GroupId, Policy, getdate(), getdate(), @UserId
				from AffGroupPolicy with (nolock)
				where FuncId = @ParentId
				--add list custid is used on parentid
				insert into AffMemberPolicy(CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
				select custid, @FuncId, policy, getdate(), getdate(), @UserID
				from AffMemberPolicy with (nolock)
				where funcId = @ParentId
			end
		else
			begin
				insert into AffGroupPolicy(FuncId, GroupId, Policy, CreateDate, ModifyDate, Creator)
				Select @FuncId, GroupId, 0, getdate(), getdate(), @UserId
				from AffGroupInfo grp with (nolock)
				where System = 'AFFILIATE'			
				
				insert into AffMemberPolicy(CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
							select custid, @FuncId, 0, getdate(), getdate(), @UserID
							from Affiliate_User with (nolock)
				

			end
		
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
							when 'E' then 'Add function failed.'
							when 'CS' then N'Add function failed.'
							when 'J' then N'Add function failed.'
							else N'Add function failed.'
						end, @ErrCode = 103
		return
	END
	COMMIT TRANSACTION
	
	--Write log data
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] add functioninfo:' + dbo.Aff_ToString(@FuncId)	
	
	
	EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=0,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData