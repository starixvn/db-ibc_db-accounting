/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceTransferMulUpd]
    @UserID INT,    
    @FileName VARCHAR(100),
    @FileSize INT,
    @Ip varchar(15) = '',
    @ErrCode INT = 0 OUTPUT ,
    @ErrMsg NVARCHAR(200) = '' OUTPUT
AS 
/*
Created: 
Task : Update new multi transactions for username
DB: DBTXN/BODB02
Original: 
Revisions:	
	- 20090812@Johnny: insert transfer transaction.
	- 20101021@Henry: Record execution time
	- 20111012@Lukas: Expand @filename length
	- 20111019@Lukas: force do transfer right the order in Acc_CustFinanceTransfer
	- 20111130@Lukas: Expand transfer description
	- 20121224@Elodie: Get the order of transfer transaction 
	- 20130201@Elodie: Change link server DB03 to DBPOLICY, DB06 to DBACC
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20130224@Lukas: move Acc_CustFinanceTransfer to new database bodb_acc
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo by link database)
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	
*/
BEGIN
    SET NOCOUNT ON		

--Check permission for account site
    EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid = @UserID,
        @funcname = '[AutomateFinanceTransfer]', @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
	
    DECLARE @tmpTransfer TABLE--this table is suitable to SP "Acc_BettransInsTransfer"
        (
          FromCustid INT,
          FromUserName varchar(30),
          ToUserName varchar(30),
          Amount money,
          ExchangeRate float,
          Description nvarchar(200),
		  seq INT
        )
        
    --Declare Table temp to store succeed trans and failed trans
    Declare @Fail table(Seq int, FromUserName varchar(30), ToUserName varchar(30), Amount money, ExchangeRate float, Description nvarchar(200), Reason nvarchar(100))    
    Declare @Success table(Seq int, FromUserName varchar(30), ToUserName varchar(30), Amount money, ExchangeRate float, Description nvarchar(200))
    
    INSERT  INTO @tmpTransfer(FromCustid, FromUserName, ToUserName, Amount, ExchangeRate, Description, seq)
    SELECT  c.custid,--Get custId by From Cust Username
			FromCust,
            ToCust,--To Username
            Amount,
            ExRate,
            a.Description,
			seq
    FROM DBACC.bodb_acc.dbo.Acc_CustFinanceTransfer a with(nolock)
		left join CustDB.dbo.CustInfo c with(nolock) on a.FromCust = c.Username
    WHERE UserId = @UserId    

    --Transfer Code    
    Declare cur_FinanceTransfer Cursor for
    Select FromCustid, FromUserName, ToUserName, Amount, ExchangeRate, Description, seq    
    From @tmpTransfer
	ORDER BY seq ASC
    
    Declare @FromCustId int, @FromUserName varchar(30), @ToUserName varchar(30), @Amount money, @ExchangeRate float, @Description nvarchar(200), @Seq int
    
	open cur_FinanceTransfer 
    
	Fetch Next From cur_FinanceTransfer Into @FromCustId, @FromUserName, @ToUserName, @Amount, @ExchangeRate, @Description, @Seq
	While @@Fetch_Status = 0
	Begin		
		--Call transfer SP here
		Exec dbo.[Acc_FinanceTransferBettransIns] 
			 @FromCustID = @FromCustId,  
			 @ToUserName = @ToUserName,   
			 @Amount = @Amount,  
			 @ExchangeRate = @ExchangeRate,  
			 @Remark = @Description,  
			 @UserID = @UserId, --custid of Admin  
			 @IP = @Ip,  
			 @ErrCode = @ErrCode OUTPUT,  
			 @ErrMsg = @ErrMsg OUTPUT
		
	
		If @ErrCode = 0--Success transaction		
		Begin
			insert into @Success(Seq, FromUserName, ToUserName, Amount, ExchangeRate, Description)
			values(@Seq, @FromUserName, @ToUserName, @Amount, @ExchangeRate, @Description)
		End
		Else
		Begin
			insert into @Fail(Seq, FromUserName, ToUserName, Amount, ExchangeRate, Description, Reason)
			values(@Seq, @FromUserName, @ToUserName, @Amount, @ExchangeRate, @Description, '; <b>' + @ErrMsg + '</b>')
		End
		
		Fetch Next From cur_FinanceTransfer Into @FromCustId, @FromUserName, @ToUserName, @Amount, @ExchangeRate, @Description, @Seq
		select @ErrCode = 0, @ErrMsg = ''
	End
    
    Close cur_FinanceTransfer
	Deallocate cur_FinanceTransfer
	--End Transfer Code	
	
	--Return failed table and success table	
	Select * from @Fail ORDER BY seq ASC
	Select * from @Success ORDER BY seq ASC
	
-- Write Log Row
    DECLARE @TotalUsers INT
    SELECT  @TotalUsers = COUNT(*)
    FROM    @Success
    
    select @TotalUsers = -@TotalUsers
    
	declare @Doing nvarchar(500)
	
	select @Doing ='<Acc_FinanceTransferMulUpd TotalUser="'
            + CONVERT(VARCHAR(20), @TotalUsers) + '" FileName="' + @FileName
            + '" Size="' + CONVERT(VARCHAR(10), @FileSize) + '" />'
             
	BEGIN TRY                
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @TotalUsers, @ToCustID = 0, @IP = @IP, @Doing = @Doing
    END TRY
    BEGIN CATCH
		select @Doing = '<Acc_FinanceTransferMulUpd TotalUser="' + CONVERT(VARCHAR(20), @TotalUsers) + 
						'" FileName="' + @FileName + 
						'" Size="' + CONVERT(VARCHAR(10), @FileSize) + 
						'" ErrMsg="' + error_message() + '" />'
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @TotalUsers, @ToCustID = 0, @IP = @IP, @Doing = @Doing
    END CATCH
END	
	

GO
GRANT EXECUTE ON [dbo].[Acc_FinanceTransferMulUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceTransferMulUpd] TO [vnteam] AS [dbo]