USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter PROCEDURE [dbo].[Acc_ExchangeUpdateOpenToteRate]

	@GBPRate FLOAT = NULL,
	@AUDRate FLOAT = NULL,
	@ZARRate FLOAT = NULL,	
	@EURORate FLOAT = NULL,
	@US$Rate  FLOAT = NULL,
	@currency NVARCHAR(50),
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = ''
AS

/*
Created: @HuyNguyen
Task : Exchange Rate Update Open Tote
DB: DBTRANS.bodb02
Original: Acc_ExchangeUpd

Revisions: 

Param's Explanation:
*/

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UpdateExchangeRateOpenTote]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

declare 
	@LogData nvarchar(400),
	@old_GBPRate FLOAT ,
	@old_AUDRate FLOAT ,
	@old_ZARRate FLOAT ,	
	@old_EURORate FLOAT ,
	@old_US$Rate FLOAT ,	
	@old_currency NVARCHAR(50),
	@actualrate float,
    @exchangeid int

select 
	@old_GBPRate = GBPRate,
	@old_AUDRate = AUDRate,
	@old_ZARRate = ZARRate,	
	@old_EURORate = EURORate,
	@old_US$Rate = US$Rate,	
	@exchangeid = exchangeid,
	@actualrate=actualrate
from exchange with (nolock) where currency=@currency

UPDATE exchange SET 
	GBPRate = CASE WHEN ISNULL(@GBPRate,-1) > -1 THEN @GBPRate ELSE GBPRate END,
	AUDRate = CASE WHEN ISNULL(@AUDRate,-1) > -1 THEN @AUDRate ELSE AUDRate END,
	ZARRate = CASE WHEN ISNULL(@ZARRate,-1) > -1 THEN @ZARRate ELSE ZARRate END,
	EURORate = CASE WHEN ISNULL(@EURORate,-1) > -1 THEN @EURORate ELSE EURORate END,
	US$Rate = CASE WHEN ISNULL(@US$Rate,-1) > -1 THEN @US$Rate ELSE US$Rate END
WHERE currency=@currency


Select @LogData = 'Update exchange rate:'
		+  ' currencyName=' + @currency 
		+  ' ,newGBPRate='+ ISNULL(convert(VARCHAR(100), @GBPRate),'') 
		+  ' ,oldGBPRate='+ ISNULL(convert(VARCHAR(100), @old_GBPRate),'') 
		+  ' ,newAUDRate='+ ISNULL(convert(VARCHAR(100), @AUDRate),'') 
		+  ' ,oldAUDRate='+ ISNULL(convert(VARCHAR(100), @old_AUDRate),'') 
		+  ' ,newZARRate='+ ISNULL(convert(VARCHAR(100), @ZARRate),'') 
		+  ' ,oldZARRate='+ ISNULL(convert(VARCHAR(100), @old_ZARRate),'') 
		+  ' ,newEURORate='+ ISNULL(convert(VARCHAR(100), @EURORate),'') 
		+  ' ,oldEURORate='+ ISNULL(convert(VARCHAR(100), @old_EURORate),'') 
		+  ' ,newUS$Rate='+ ISNULL(convert(VARCHAR(100), @US$Rate),'') 
		+  ' ,oldUS$Rate='+ ISNULL(convert(VARCHAR(100), @old_US$Rate),'')  

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
	@UserID = @UserID, 
	@ExchangeID = @exchangeid, 
	@actualrate = @actualrate, 
	@IP = @IP, 
	@Doing = @LogData
GO

GRANT EXECUTE ON [dbo].[Acc_ExchangeUpdateOpenToteRate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeUpdateOpenToteRate] TO [vnteam] 