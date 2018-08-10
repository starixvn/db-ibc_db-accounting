/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceCrossTransferMulUpd]
    @UserID INT,    
    @FileName VARCHAR(100),
    @FileSize INT,
	@ForexUsername	NVARCHAR(50),
    --@Index INT,
    @Ip varchar(15) = '',
    @ErrCode INT = 0 OUTPUT ,
    @ErrMsg NVARCHAR(200) = '' OUTPUT
AS 
/*
	Created: 
	Task : Update new multi cross transfer transactions for username
	DB: DBTXN/BODB02
	Original: 
	Revisions:	
		- 20130201@Elodie: Change link server DB03 to DBPOLICY, DB06 to DBACC
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20130224@Lukas: move Acc_CustFinanceTransfer to new database bodb_acc
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo by link database)
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/
BEGIN
    SET NOCOUNT ON		

--Check permission for account site
    EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission 
				@custid		= @UserID,
				@funcname	= '[AutomateFinanceTransfer]', 
				@ErrCode	= @ErrCode OUTPUT,
				@ErrMsg		= @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
	
	DECLARE @tmpTransfer TABLE --this table is suitable to SP [Acc_FinanceCrossTransferBettransIns]
    (
		FromCustID		INT,
		FromUsername	NVARCHAR(50),
		ToCustID		INT,
		ToUsername		NVARCHAR(50),
		FromAmount		MONEY,
		ToAmount		MONEY,
		Remark			NVARCHAR(200)
    )
        
    --Declare Table temp to store succeed trans and failed trans
    DECLARE @Fail TABLE 
	(
		FromUserName NVARCHAR(50), 
		ToUserName NVARCHAR(50), 
		FromAmount MONEY, 
		ToAmount MONEY, 		
		Description NVARCHAR(200), 
		Reason NVARCHAR(200)
	)    

    DECLARE @Success TABLE
	(
		FromUserName NVARCHAR(50),
		ToUserName NVARCHAR(50),
		FromAmount MONEY,
		ToAmount   MONEY,
		Description NVARCHAR(200)
	)
    

    INSERT  INTO @tmpTransfer(FromCustID, FromUsername, ToCustID, ToUsername, FromAmount, ToAmount, Remark)
    SELECT  c1.CustID,
			c1.Username,
            c2.CustID,
			c2.Username,
            a.Amount,
			a.ToAmount,            
            a.Description
    FROM DBACC.bodb_acc.dbo.Acc_CustFinanceTransfer a WITH(NOLOCK)
		INNER JOIN CustDB.dbo.custinfo c1 WITH(NOLOCK) ON a.FromCust = c1.Username
		INNER JOIN CustDB.dbo.custinfo c2 WITH(NOLOCK) ON a.ToCust = c2.Username
    WHERE UserId = @UserId
    
    
    --Transfer Code
    DECLARE cur_FinanceTransfer CURSOR FOR
    SELECT FromCustID, FromUsername, ToCustID, ToUsername, FromAmount, ToAmount, Remark
    FROM @tmpTransfer
    
    DECLARE @FromCustID INT, @ToCustID INT, @FromAmount MONEY, @ToAmount MONEY, @Remark NVARCHAR(200),
			@FromUsername NVARCHAR(50), @ToUsername NVARCHAR(50)
    
	OPEN cur_FinanceTransfer 
    
	FETCH NEXT FROM cur_FinanceTransfer INTO @FromCustID, @FromUsername, @ToCustID, @ToUsername, @FromAmount, @ToAmount, @Remark
	While @@FETCH_STATUS = 0
	BEGIN		
		--Call transfer SP here
		EXEC dbo.[Acc_FinanceCrossTransferBettransIns] 
			 @FromCustID	= @FromCustID,  
			 @ToCustID		= @ToCustID,   
			 @FromAmount	= @FromAmount,  
			 @ToAmount		= @ToAmount,  
			 @ForexUsername = @ForexUsername,
			 @Remark		= @Remark,  
			 @UserID		= @UserID, --custid of Admin  
			 @IP			= @IP,  
			 @ErrCode		= @ErrCode OUTPUT,  
			 @ErrMsg		= @ErrMsg OUTPUT	

		IF @ErrCode = 0--Success transaction		
		BEGIN
			INSERT INTO @Success(FromUserName, ToUserName, FromAmount, ToAmount, Description)
			VALUES(@FromUserName, @ToUserName, @FromAmount, @ToAmount, @Remark)
		END
		ELSE
		BEGIN
			INSERT INTO @Fail(FromUserName, ToUserName, FromAmount, ToAmount, Description, Reason)
			VALUES(@FromUserName, @ToUserName, @FromAmount, @ToAmount, @Remark, '; <b>' + @ErrMsg + '</b>')
		END
		
		FETCH NEXT FROM cur_FinanceTransfer INTO @FromCustID, @FromUsername, @ToCustID, @ToUsername, @FromAmount, @ToAmount, @Remark
		SELECT @ErrCode = 0, @ErrMsg = ''
	END
    
    CLOSE cur_FinanceTransfer
	DEALLOCATE cur_FinanceTransfer
	--End Transfer Code
	
	
	--Return failed table and success table	
	SELECT * FROM @Fail
	SELECT * FROM @Success
	
	
-- Write Log Row
    DECLARE @TotalUsers INT
    SELECT  @TotalUsers = COUNT(*)
    FROM    @Success
    
    select @TotalUsers = -@TotalUsers
    
	declare @Doing nvarchar(500)
	
	select @Doing ='<Acc_FinanceCrossTransferMulUpd TotalUser="'
            + CONVERT(VARCHAR(20), @TotalUsers) + '" FileName="' + @FileName
            + '" Size="' + CONVERT(VARCHAR(20), @FileSize) + '" />'
            
    BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @TotalUsers, @ToCustID = 0, @IP = @IP, @Doing = @Doing
	END TRY
	BEGIN CATCH
		select @Doing = '<Acc_FinanceCrossTransferMulUpd TotalUser="' + CONVERT(VARCHAR(20), @TotalUsers) + 
						'" FileName="' + @FileName + 
						'" Size="' + CONVERT(VARCHAR(20), @FileSize) + 
						'" ErrMsg="' + error_message() + '" />'
						
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @TotalUsers, @ToCustID = 0, @IP = @IP, @Doing = @Doing
	END CATCH
END			


GO
GRANT EXECUTE ON [dbo].[Acc_FinanceCrossTransferMulUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceCrossTransferMulUpd] TO [vnteam] AS [dbo]