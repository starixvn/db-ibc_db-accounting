USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminGroupUpd]    Script Date: 12/20/2012 02:15:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminGroupUpd_xpre    Script Date: 12/25/2010 7:01:55 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_AdminGroupUpd    Script Date: 12/16/2010 1:55:00 PM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_AdminGroupUpd    Script Date: 7/11/2009 1:17:56 PM ******/
ALTER PROCEDURE  [dbo].[Aff_Con_AdminGroupUpd]
	@CustID int,
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*called by sp Aff_Con_AdminUpd */
/*DB03.bodb02*/--->/*DB052.Affiliate_12BET*/

/*
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
*/

SET NOCOUNT ON
Begin
IF EXISTS(SELECT 1 FROM AffGroupInfo with(nolock) where groupid=@groupid)
	BEGIN 
		IF EXISTS(SELECT 1 FROM affiliate_user ac with(nolock) WHERE custid=@custid and groupid <> @groupID) 
		BEGIN
			BEGIN TRANSACTION
				UPDATE affiliate_user with (ROWLOCK, UPDLOCK) SET groupid=@groupid WHERE custid = @custid							
			COMMIT TRANSACTION
			
			DECLARE @SPName varchar(50), @LogData nvarchar(200)
			select @SPName = OBJECT_NAME(@@ProcID)

			SELECT @LogData = 'Update Group for Admin custid:' + dbo.Aff_ToString(@custid) + ' GroupID:' + dbo.Aff_ToString(@GroupID)
			
			EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
					@Creator=@UserID,	
					@AffID=@CustID,
					@Typename= 'UserControl',	
					@SPName=@SPName ,		
					@IP =@IP,
					@Details=@LogData	
		
		END
	END
	ELSE
	BEGIN
		SELECT @ErrMsg =  case @Language
							when 'E' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							when 'CS' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							when 'J' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							else N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
						end, @ErrCode = 103
		return 
	END


End