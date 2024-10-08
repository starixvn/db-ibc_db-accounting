/*<info serverAlias="DBTXN-bodb02" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceCrossTransferMulUpd]
    @UserID			INT,    
    @FileName		VARCHAR(100),
    @FileSize		INT,
	@ForexUsername	NVARCHAR(50),
    --@Index INT,
    @Ip				VARCHAR(45) = '',
    @ErrCode		INT = 0 OUTPUT ,
    @ErrMsg			NVARCHAR(200) = '' OUTPUT
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
		- 20181112@Sophia: Add Transfer Collection [redmine: #98621]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20211115@Danny: Change @Ip datatype to support IPv6 [Redmine: #164196]
		- 20220802@Danny: change code to support SiteDB [Redmine: #175253]
		- 20240729@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895]
*/
BEGIN
    SET NOCOUNT ON		
	
	DECLARE @tmpTransfer TABLE --this table is suitable to SP [Acc_FinanceCrossTransferBettransIns]
    (
		FromCustID		INT,
		FromUsername	NVARCHAR(50),
		ToCustID		INT,
		ToUsername		NVARCHAR(50),
		FromAmount		MONEY,
		ToAmount		MONEY,
		Remark			NVARCHAR(200),
		IsCollection    BIT
    )
        
    --Declare Table temp to store succeed trans and failed trans
    DECLARE @Fail TABLE 
	(
		FromUserName NVARCHAR(50), 
		ToUserName NVARCHAR(50), 
		FromAmount MONEY, 
		ToAmount MONEY, 		
		Description NVARCHAR(200), 
		Reason NVARCHAR(200),
		IsCollection    BIT
	)    

    DECLARE @Success TABLE
	(
		FromUserName NVARCHAR(50),
		ToUserName NVARCHAR(50),
		FromAmount MONEY,
		ToAmount   MONEY,
		Description NVARCHAR(200),
		IsCollection    BIT
	)
    

    INSERT  INTO @tmpTransfer(FromCustID, FromUsername, ToCustID, ToUsername, FromAmount, ToAmount, Remark, IsCollection)
    SELECT  c1.CustID,
			c1.Username,
            c2.CustID,
			c2.Username,
            a.Amount,
			a.ToAmount,            
            a.Description,
			a.IsCollection
    FROM DBCUST.CustDB.dbo.Acc_CustFinanceTransfer a WITH(NOLOCK)
		INNER JOIN CustDB.dbo.custinfo c1 WITH(NOLOCK) ON a.FromCust = c1.Username
		INNER JOIN CustDB.dbo.custinfo c2 WITH(NOLOCK) ON a.ToCust = c2.Username
    WHERE UserId = @UserId
    
    
	-- Return param dataset here
	-- Process Call transfer SP move outsite (handle by web)

	 SELECT FromCustID, 
			FromUsername, 
			ToCustID, 
			ToUsername, 
			FromAmount, 
			ToAmount, 
			Remark, 
			IsCollection, 
			@UserID AS UserID, 
			@ForexUsername AS ForexUsername,
			@IP AS IP,
			'Acc_FinanceCrossTransferBettransIns' AS SP_name
    FROM @tmpTransfer
END			

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceCrossTransferMulUpd] TO [vnteam] AS [dbo]