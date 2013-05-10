USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_PaymentRequestApprove]    Script Date: 12/20/2012 02:04:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_PaymentRequestApprove]	
    @TransID bigint,	
	@AdminDesc nvarchar(300) = null,
    @AffDesc nvarchar(300) = null,
    @PreferredLanguage varchar(5)='E' OUTPUT,
    @MailOption bit = 0 OUTPUT,
	@UserID int,	
	@IP varchar(15) = '',
	@language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
-- DB: DBTRANS.BODB02
/*
Creator : Peter@20090910
Task : Update Payment status ('Approved','Rejected','Cancelled')
 
When AffAdmin approve payment, update payment status into completed and insert 2 transactions into bettrans table(IBC Database) 						
						
CustId	TransID	Actual_Stake	Winlost	Currency	ExchangeRate	Bettype
memHK$	111	0	750	5	2.3	107
DummyHK$	112	750	0	5	2.3	107


Input 
    1) @AffId (For Double check) 
    2) @TransID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )    
    3) @AdminDesc Description for this payment from Admin
    4) @AffDesc Description visible for Affiliate
    5) @userid ID of Admin update this payment
    6) @IP IP update payment
   
Revisions:
	- 20100209@Johnny: Check the correction of IBCCustId in AffPayout with Player_Username in AffDetail table. If they donot match, Payment will not be done
	- 20100413@Peter : Update ExRate for MemberCurrency is the exchange rate of table DB02.bodb02.dbo.Exchange for the aprroved date (not from AffPayout data)
	                   to avoid the bug on balance up procedure
	- 20100413@Peter : Update StatusID (new column) in bettrans table
	                   Approved have StatusId=132  
	- 20101102@Henry: Change column transid from INT to BIGINT                   
	- 20101228@Henry: change bettype to new range           
	- 20111020@Sophia: update balance for customer          
	- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	

• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC DBAFF12BET.Affiliate_12BET.[dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[Payment]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN


--Check whether this is pending payment request 

Declare @AffID int, @Status nvarchar(50),@BetType int,@Player_IBCCustID int,@AffPayout money
       , @Player_Currency int,@Player_ExRate float,@BallanceUserName varchar(50)
      , @BallanceCustID int,@Player_CurrencyName varchar(50), @bal_varname varchar(50)
      ,@Player_UserName varchar(50),@Player_Recommend int, @Player_MRecommend int, @Player_SRecommend int
     ,@Ballance_Recommend int, @Ballance_MRecommend int, @Ballance_SRecommend int,@RefID bigint, @StatusID tinyint, @balance money
     

Select @Status = 'Approved',@BetType=21006,@StatusID=132

select @RefID=RefID
from DBAFF12BET.Affiliate_12BET.dbo.AffTrans with (nolock)
where TransID=@TransID

Select @AffID=AffID,@Player_IBCCustID=IBCCustID,@AffPayout=AffPayout, @Player_Currency=MemberCurrency
from DBAFF12BET.Affiliate_12BET.dbo.AffPayout with (nolock)
where RefID=@RefID and Status='pending'

--check consistency 12betusername in Affdetail table and AffPayout table
Declare @Player_IBCCustIDTmp int, @AffUserName varchar(50)

Select @Player_IBCCustIDTmp = CustId, @AffUserName=a.UserName
From DBAFF12BET.Affiliate_12BET.dbo.AffDetail a with(nolock)
	inner join Customer c with(nolock) on '12BET$' + a.player_username = c.username2
where a.AffId = @AffId

If(@Player_IBCCustID is null or @Player_IBCCustIDTmp is null or @Player_IBCCustID <> @Player_IBCCustIDTmp)
BEGIN
   Select @ErrMsg = case @language 
						when 'en-US' then 'This Payment is belonging Affilite. But 12Bet Username is different.'
						when 'zh-TW' then N'This Payment is belonging Affilite. But 12Bet Username is different.'		
						when 'zh-CN' then N'This Payment is belonging Affilite. But 12Bet Username is different.'		
						when 'es-ES' then 'This Payment is belonging Affilite. But 12Bet Username is different.'
						when 'vi-VN' then 'This Payment is belonging Affilite. But 12Bet Username is different.'
						when 'id-ID' then 'This Payment is belonging Affilite. But 12Bet Username is different.'
						else  N'This Payment is belonging Affilite. But 12Bet Username is different.'		
					end, 
		@ErrCode = 4000
	return
END


if(@RefID is null or @AffID is null)
BEGIN
           Select @ErrMsg = case @language 
								when 'en-US' then 'Invalid payment request transaction.'
								when 'zh-TW' then N'Invalid payment request transaction.'
								when 'zh-CN' then N'Invalid payment request transaction.'
								when 'es-ES' then 'Invalid payment request transaction.'
								when 'vi-VN' then 'Invalid payment request transaction.'
								when 'id-ID' then 'Invalid payment request transaction.'
								else  N'Invalid payment request transaction.'			
							end, 
			@ErrCode = 4001
	return
END

select @Player_CurrencyName=Currency,@Player_ExRate=actualrate
from Exchange (nolock)
Where ExchangeID=@Player_Currency

select @bal_varname = 'AFF_BalPlayer'+  @Player_CurrencyName

select @BallanceUserName = SValue
from DBAFF12BET.Affiliate_12BET.dbo.SystemSettings with (nolock)
where SName = @bal_varname

select @BallanceCustID=custid,@Ballance_Recommend=recommend, @Ballance_MRecommend=mrecommend, @Ballance_SRecommend=srecommend
from CustInfo (nolock)
where username=@BallanceUserName

select @Player_UserName=username,@Player_Recommend=recommend, @Player_MRecommend=mrecommend, @Player_SRecommend=srecommend
from CustInfo (nolock)
where CustID=@Player_IBCCustID

IF (@BallanceCustID is null)
BEGIN
           Select @ErrMsg = case @language 
								when 'E' then 'Invalid Balance Account.'
								when 'CT' then N'Invalid Balance Account.'
								when 'CS' then N'Invalid Balance Account.'
								else  N'Invalid Balance Account.'			
							end, 
			@ErrCode = 4001
	return
END

BEGIN TRY
    declare @TransDate datetime, @TransID1 bigint, @TransID2 bigint
    Select @TransDate=current_timestamp
    --Add money to player
    INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, winlostdate, 
	 creator,recommend,mrecommend,srecommend,currency, actualrate, currencyName, ruben, status,ip,StatusID)
    VALUES 
    (@Player_IBCCustID, @Player_UserName, @RefID,@TransDate, 0, @BetType, 'Approve payout Request from affiliate ' + @AffUserName + ' to his player account: ' + @Player_UserName, abs(@AffPayout), 0, convert(nvarchar(10), @TransDate, 120), 
     @UserID, @Player_Recommend, @Player_MRecommend, @Player_SRecommend, @Player_Currency, @Player_ExRate, @Player_CurrencyName, 1, @Status,@ip,@StatusID)
     
    Select @TransID1=SCOPE_IDENTITY()
     --Deduct balance account
     INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, winlostdate, 
	 creator,recommend,mrecommend,srecommend,currency, actualrate, currencyName, ruben, status,ip,StatusID)
    VALUES 
    (@BallanceCustID, @BallanceUserName, @RefID,@TransDate, 0, @BetType, 'Approve payout Request from affiliate ' + @AffUserName + ' to his player account: ' + @Player_UserName, 0, abs(@AffPayout), convert(nvarchar(10), @TransDate, 120), 
     @UserID, @Ballance_Recommend, @Ballance_MRecommend, @Ballance_SRecommend, @Player_Currency, @Player_ExRate, @Player_CurrencyName, 1, @Status,@ip,@StatusID)
    Select @TransID2=SCOPE_IDENTITY() 
    
     ----UPDATE BALANCE
   SELECT @balance = abs(@AffPayout)
   EXEC Dot_BalanceUpdCredit @CustID = @Player_IBCCustID , @balance = @balance
   
   EXEC Dot_BalanceUpdDebit @CustID = @BallanceCustID , @balance = @balance
   
      
   declare @SPName varchar(50), @LogData nvarchar(4000),@RefNo bigint
   select @SPName = OBJECT_NAME(@@ProcID) 

   Select @LogData =  'Approve a payout Request.TransID = ' 
                      + dbo.Aff_ToString(@TransID1) 
                      + ',' 
                      + dbo.Aff_ToString(@TransID2)                       
                      + '. RefID = ' + dbo.Aff_ToString(@RefID)

	EXEC [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@AffID,
		@Typename= 'Payout',	
		@SPName=@SPName ,
		@RefNo=@RefNo OUTPUT,
		@IP =@IP,
		@Details=@LogData	
    --Update Status 
        exec [DBAFF12BET].[Affiliate_12BET].[dbo].[Aff_PaymentRequestUpd]	
		@TransID=@TransID,
		@Status  = @Status,
		@AdminDesc = @AdminDesc,
		@AffDesc = @AffDesc,
		@PreferredLanguage=@PreferredLanguage OUTPUT,
		@MailOption = @MailOption OUTPUT,
		@UserID=@UserID,	
		@RefNo=@RefNo,
		@IP = @IP,
		@language = @language,
		@ErrCode  = @ErrCode OUTPUT,
		@ErrMsg  = @ErrMsg OUTPUT
    if(@ErrCode<>0)
       delete bettrans
       where transid in (@TransID1,@TransID2)

      
END TRY

BEGIN CATCH
	delete bettrans
    where transid in (@TransID1,@TransID2)

    Select @ErrMsg = case @language 
							when 'E' then 'Update transaction failed.'
							when 'CT' then N'Update transaction failed.'
							when 'CS' then N'Update transaction failed.'
							when 'TH' then N'Update transaction failed.'
							when 'ES' then N'Update transaction failed.'
							else  N'Update transaction failed.'		
						end,
		@ErrCode = 4003
	return
    RETURN
END CATCH





