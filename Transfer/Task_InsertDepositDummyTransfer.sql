/*<info serverAlias="DBTXN-bodb02" executers="Svc_Tig,Dot_Bonus" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_InsertDepositDummyTransfer]
	(
		@CustID		INT,
		@Bal_CustID INT,
		@Refno		BIGINT
	)
/*
	DB: DBTXN.BODB02
	Original: DBA_InsertDepositDummyTransfer
	Revision:
		- 20220927@Evan: Create new [Redmine: #178188]
		- 20240304@Eddie: Change "Dot_Member" to "Svc_Tig" account [Redmine: #201841]
	Param explaination:
		- @CustID		: CustID of transaction to correct
		- @Bal_CustID	: CustID of pairing dummy account
		- @Refno		: Transaction refno to be corrected
	Note: @CustID & @Bal_CustID is the same SitegroupDB and exec sp on the right server (central & sitedb)
*/	
AS
BEGIN	
	SET NOCOUNT ON
	
   /*
		Checking valid account / transaction
   */ 
	
   	IF (SELECT COUNT(*) FROM dbo.Transfer WITH(NOLOCK) WHERE Refno = @Refno AND CustID = @CustID) = 0
		BEGIN
			PRINT 'There is no transaction.'
			RETURN
		END
	 
	IF (SELECT COUNT(*) FROM dbo.Transfer WITH(NOLOCK) WHERE Refno = @Refno AND CustID = @Bal_CustID) > 0
		BEGIN
			PRINT 'Transaction for dummy account existed.'
			RETURN
		END  

	IF NOT EXISTS(SELECT 1 FROM CustDB.dbo.Customer WITH(NOLOCK) WHERE CustID = @CustID)
		BEGIN
			PRINT 'Invalid customer account.'
			RETURN
		END
	 
	IF NOT EXISTS(SELECT 1 FROM CustDB.dbo.Customer WITH(NOLOCK) WHERE CustID = @Bal_CustID)
		BEGIN
			PRINT 'Invalid balance account.'
			RETURN
		END
	 
	IF NOT EXISTS(SELECT 1 FROM dbo.Transfer WITH(NOLOCK) WHERE Refno = @Refno)
		BEGIN
			PRINT 'Invalid Refno number.'
			RETURN
		END

	DECLARE @Cust_SiteDBGroupID SMALLINT, @Server_SiteDBGroupID SMALLINT;
	DECLARE @SiteGroupInfo TABLE
	(	
		CustID INT,
		SiteDBGroupID SMALLINT,
		LinkedServerName  VARCHAR(512),
		ClientAccessName VARCHAR(512),
		AGIP VARCHAR (50)
	)
	INSERT INTO @SiteGroupInfo (SiteDBGroupID, LinkedServerName, ClientAccessName, AGIP)
	EXEC CustDB.dbo.Acc_SiteDBConfigSel @CustID = @CustID

	SELECT @Cust_SiteDBGroupID = SiteDBGroupID FROM @SiteGroupInfo
	SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	--Check the SiteDBGroupID of CustID and Server is match
	IF ISNULL(@Cust_SiteDBGroupID,-1) <> @Server_SiteDBGroupID
	BEGIN
		PRINT 'Executing on invalid server. Please check SiteDBGroupID information.'
		RETURN		
	END 

   /*** INSERT TRANSACTION ***/
    DECLARE @Transdate          DATETIME
            ,@WinlostDate       DATETIME
            ,@Transdesc         NVARCHAR(300)
            ,@Bettype           SMALLINT
            ,@Actual_Stake      MONEY
            ,@Winlost           MONEY
            ,@IP                VARCHAR(45)
     
    DECLARE
            @Bal_mrecommend         INT
            ,@Bal_recommend         INT
            ,@Bal_srecommend        INT
            ,@Bal_username          VARCHAR(50)
            ,@Bal_currency          TINYINT
            ,@Bal_actualrate        FLOAT
            ,@Bal_currencyname      NVARCHAR(50)
			,@Bal_TransID			BIGINT
			,@TransID				BIGINT
     
    SELECT
        @Transdate          = transdate
        ,@WinlostDate       = WinlostDate
        ,@Transdesc         = transdesc
        ,@Bettype           = bettype
        ,@Actual_Stake      = actual_stake
        ,@Winlost           = winlost
        ,@IP                = ip
        ,@Bal_actualrate    = actualrate
        ,@TransID		= TransId
    FROM dbo.Transfer WITH(NOLOCK)
    WHERE custid = @CustID AND refno = @Refno  
     
    SELECT     
        @Bal_username = c.username
        ,@Bal_mrecommend = c.mrecommend, @Bal_recommend = c.recommend, @Bal_srecommend = c.srecommend
        ,@Bal_currency = c.currency, @Bal_currencyname = e.currency
    FROM CustDB.dbo.Customer c WITH(NOLOCK)
        INNER JOIN CustDB.dbo.Exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
    WHERE c.custid = @Bal_CustID
    
	-----------------------
    --Get new transid 

	EXEC Get_Bettrans_TransID @TransID = @Bal_TransID OUTPUT

    INSERT INTO dbo.Transfer (
        TransId, CustId, Username, RefNo, TransDate, Bettype, TransDesc, Winlost, Actual_Stake, WinlostDate, 
        Creator, Recommend, MRecommend, SRecommend, Currency, ActualRate, CurrencyName, StatusId, IP, RepUpdateTime
        )
        VALUES (
            @Bal_TransID, @Bal_CustID, @Bal_username, @Refno, @Transdate, @Bettype, @Transdesc, @Actual_Stake, @Winlost, @WinlostDate, 
            @CustID, @Bal_recommend, @Bal_mrecommend, @Bal_srecommend, @Bal_currency, @Bal_actualrate, @Bal_currencyname, 131, @IP, SYSDATETIME()
            )
	
	IF EXISTS(SELECT 1 FROM TransferInfo WITH (NOLOCK) WHERE TransId = @TransID)
	BEGIN
		INSERT INTO TransferInfo (TransId,WalletType,BonusID,Amount,IsDel,RepUpdateTime)
		SELECT @Bal_TransID,WalletType,BonusID,Amount,IsDel,SYSDATETIME()
		FROM TransferInfo WITH (NOLOCK) 
		WHERE TransId = @TransID
	END

END
