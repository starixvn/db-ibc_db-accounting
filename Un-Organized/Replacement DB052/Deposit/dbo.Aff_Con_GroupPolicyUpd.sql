USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupPolicyUpd]    Script Date: 12/20/2012 02:42:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupPolicyUpd_xpre    Script Date: 12/25/2010 7:02:02 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_GroupPolicyUpd    Script Date: 12/16/2010 1:55:01 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_GroupPolicyUpd]
	@GroupPolicys NVARCHAR(4000),
	@UserID int, 
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15) = ''
AS
/*DB03.BODB02 --> DB052.Affiliate_12BET*/
-- Update Acc_GroupPolicy
-- Format of @GroupPolicys: @GroupID,@FuncID,@Policy;@GroupID,@FuncID,@Policy; ...;
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
SET NOCOUNT ON
	
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
	
	
	DECLARE @GroupPolicy nvarchar(4000)
	DECLARE @GroupID INT
	DECLARE @FuncID INT
	DECLARE @Policy int
	DECLARE @GroupPolicyCount int 
	DECLARE GroupPolicysCur CURSOR FOR 
		SELECT val as row_index 
		  FROM dbo.strSplit(@GroupPolicys, ';')
		 ORDER BY row_index
	
	OPEN GroupPolicysCur
	FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @GroupID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 1)
		SET @FuncID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 2)
		SET	@Policy = dbo.Aff_SplitIndex(@GroupPolicy, ',', 3)
		SET @GroupPolicyCount = (SELECT COUNT(1) FROM AffGroupPolicy with (nolock) WHERE GroupID = @GroupID AND funcid = @FuncID)

		IF(@GroupPolicyCount = 0)
			BEGIN
				INSERT INTO AffGroupPolicy 
					(GroupID, Funcid, Policy, Createdate, Modifydate, Creator)
				Values
					(@GroupID, @Funcid, @Policy, CURRENT_TIMESTAMP,CURRENT_TIMESTAMP, @UserID)
			END
		ELSE
			BEGIN
				UPDATE AffGroupPolicy
				   SET policy = @Policy,
					 modifydate = CURRENT_TIMESTAMP
				 WHERE GroupID = @GroupID
				   AND funcid = @FuncID
			END
		
		DECLARE @SPName varchar(50), @LogData nvarchar(200)
		select @SPName = OBJECT_NAME(@@ProcID)

		SELECT @LogData = '[AFFILIATE] UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy) + ' of Function ' + dbo.Aff_ToString(@Funcid) +  ' for Group ' + dbo.Aff_ToString(@GroupID)
		
		--EXEC LOG.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
				@Creator=@UserID,	
				@AffID=0,
				@Typename= 'UserControl',	
				@SPName=@SPName ,		
				@IP =@IP,
				@Details=@LogData	

		FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	END 
	CLOSE GroupPolicysCur
	DEALLOCATE GroupPolicysCur