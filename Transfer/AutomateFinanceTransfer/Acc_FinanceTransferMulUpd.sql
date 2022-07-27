/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceTransferMulUpd]
    @UserID			INT,    
    @FileName		VARCHAR(100),
    @FileSize		INT,
    @Ip				VARCHAR(45) = '',
    @ErrCode		INT = 0 OUTPUT ,
    @ErrMsg			NVARCHAR(200) = '' OUTPUT
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
	- 20181112@Sophia: Add @IsCollection [redmine: #98621]
	- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
	- 20211115@Danny: Change @Ip datatype to support IPv6 [Redmine: #164196]
	- 20220802@Danny: change code to support SiteDB [Redmine: #175253]

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
		  ToCustid INT,
          ToUserName varchar(30),
          Amount money,
          ExchangeRate float,
          Description nvarchar(200),
		  seq INT,
		  IsCollection BIT
        )
        
    --Declare Table temp to store succeed trans and failed trans
    DECLARE @Fail table(Seq INT, FromUserName VARCHAR(30), ToUserName VARCHAR(30), Amount MONEY, ExchangeRate FLOAT, Description NVARCHAR(200), Reason NVARCHAR(100), IsCollection BIT)    
    DECLARE @Success table(Seq INT, FromUserName VARCHAR(30), ToUserName VARCHAR(30), Amount MONEY, ExchangeRate FLOAT, Description NVARCHAR(200), IsCollection BIT)
    
    INSERT INTO @tmpTransfer(FromCustid, FromUserName, ToCustid, ToUserName, Amount, ExchangeRate, Description, seq, IsCollection)
    SELECT  c.custid,--Get custId by From Cust Username
			FromCust,
			c1.custid, -- Get custId by To Cust Username
            ToCust,--To Username
            Amount,
            ExRate,
            a.Description,
			seq,
			IsCollection
    FROM DBCUST.CustDB.dbo.Acc_CustFinanceTransfer a WITH(NOLOCK)
		LEFT JOIN CustDB.dbo.CustInfo c WITH(NOLOCK) on a.FromCust = c.Username
		LEFT JOIN CustDB.dbo.CustInfo c1 WITH(NOLOCK) on a.ToCust = c1.Username
    WHERE UserId = @UserId    

	-- Return param dataset here
	-- Process Call transfer SP move outsite (handle by web)
	SELECT FromCustid, ToCustid ,ToUserName, Amount, ExchangeRate, Description, @UserID AS UserId, @Ip AS Ip, IsCollection , 'Acc_FinanceTransferBettransIns' AS SP_name
	FROM @tmpTransfer

END	
	

GO
GRANT EXECUTE ON [dbo].[Acc_FinanceTransferMulUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceTransferMulUpd] TO [vnteam] AS [dbo]