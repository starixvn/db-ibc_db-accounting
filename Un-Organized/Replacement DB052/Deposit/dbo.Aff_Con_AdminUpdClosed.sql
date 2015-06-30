USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminUpdClosed]    Script Date: 12/20/2012 02:25:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminUpdClosed_xpre    Script Date: 12/25/2010 7:01:57 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_AdminUpdClosed    Script Date: 12/16/2010 1:55:00 PM ******/
ALTER PROCEDURE [dbo].[Aff_Con_AdminUpdClosed]
	@CustID int,
	@Closed bit,
	@UserID int,
	@Language varchar(2) = 'E',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS
/*
create AccAdmin from existed Admin
DB03.bodb02(Move this SP from DB02.bodb02 to DB03.bodb02) --> DB052.Affiliate_12BET
Revisions:
	- VinhTrinh@20100507: update closed field in table affiliate_user(instead of CustInfo)
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET	
	- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

update Affiliate_User with (ROWLOCK) set Closed = @Closed
where custid = @CustID

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Update AFFILIATE for CustID: ' + dbo.Aff_ToString(@custid) + ' closed: ' + case @closed when 0 then 'open' else 'closed' end


EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@CustID,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData