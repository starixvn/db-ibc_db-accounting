ALTER PROCEDURE [dbo].[Acc_BettransDelTransaction]
	@refno bigint = 0,
	@custid int, --CustId of selected account
	@UserID int, --CustID of Login Admin
	@IP nvarchar(15)='',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS
/*	Created by: [Creator]
	Task:	For Delete Transaction (transfer)
			Account / Lefmenu / Statement / Detail/ Del
			
	Original: Admin_DeleteTransaction
	Revisions:
		- 20090524@Thien: no longer use CustBetCredit, so remove temp table and update section
		- 20090828@HuyNguyen: replace [DeleteBets] --> [DeleteTrans]
		- 20091012@Kiwi: modify written log	
		- 20101225@Lukas: Re-arrange bettype
		- 20110921@Lukas: change the way searching effected transactions.		
		- 20111125@Sophia: Update banlance credit/ debit for customer
		- 20111028@Jamie: Correct UPDATE Credit/Debit Balance & check settled date 
		- 20120411@Sophia: Revise UPDATE Credit/Debit Balance
		- 20120719@Sophia:  . Add new reverse rows to delete transaction, not update transaction to zero anymore
							. Add new parameter @IP
		- 20120720@Thien: Check to not allow to transfer before balance up date
		- 20120723@Sophia: Add column ruben to temp table @Reversal
		- 20120731@Sophia: Update Liveindicator = 1 for marking deleted transactions
		- 20120810@Sophia: Use @transdesc to avoid SQL insert error
		- 20130201@Elodie: Change link server DB03 to DBPOLICY
						   Write more log on DBTXN server in case of DBLOG server failure
*/
SET NOCOUNT ON 
--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteTrans]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN

IF @refno <> 0 
BEGIN
	DECLARE	@winlostdate	DATETIME,
			@liveindicator	BIT,
			@transdesc		NVARCHAR(300)
			

	DECLARE @Reversal TABLE (	TransID BIGINT,
								custid INT,
								transdate DATETIME,
								Username NVARCHAR(50),
								refno BIGINT,
								winlost MONEY,
								actual_stake MONEY,
								winlostdate SMALLDATETIME,
								transdesc NVARCHAR(300),
								creator INT,
								bettype SMALLINT,
								matchid INT,
								actualrate FLOAT,
								recommend INT,
								mrecommend INT,
								srecommend INT,
								currency TINYINT,
								CurrencyName NVARCHAR(50),
								ip NVARCHAR(15) ,
								status NVARCHAR(10),
								statusID TINYINT,
								ruben TINYINT,
								liveindicator BIT
							)

	DECLARE @TransIDs AS TABLE (transID BIGINT)

----insert transfer data into @Reversal
	INSERT INTO @Reversal 
		(	transid, custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
			bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, status, statusID, ruben, liveindicator )
	SELECT	transid, custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
			bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, status, statusID, ruben, liveindicator
	FROM	bettrans WITH (NOLOCK)
	WHERE	refno = @refno AND matchid = 0 AND bettype > 20000 


	SELECT	top 1 @winlostdate = winlostdate, @liveindicator = liveindicator, @transdesc = transdesc
	FROM	@Reversal

--------------------------vvvvv-------------------------------------
--Check to not allow to transfer before balance up date
Declare @BalanceUpDay smalldatetime

SELECT TOP 1 @BalanceUpDay = winlostdate
FROM Bettrans WITH(NOLOCK)
WHERE bettype = 20000 and matchid = 0 and custid = 3

-- at this time, server is processing adding tickets into transfer_fi table. So not allow to transfer.
if datename(weekday, getdate()) in ('Thursday') AND datepart(hour, getdate())>= 12
	AND @BalanceUpDay + 7 < getdate() --this week BU not processed yet
BEGIN
	if @winlostdate < @BalanceUpDay +7 --Last Saturday
	BEGIN
		SELECT @ErrMsg =  case @Language
						when 'E' then 'Not allow to add transaction before balance up date - '+ convert(nvarchar(10), @BalanceUpDay +7 ,120)  +'.'
					end, @ErrCode = 100
		return
	END
END
ELSE IF @winlostdate < @BalanceUpDay --Before last BU date
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'Not allow to add transaction before balance up date - '+ convert(nvarchar(10), @BalanceUpDay ,120)  +'.'
					end, @ErrCode = 101
	return
END
----------------------^^^^^^----------------------------------

-----Check settled Date
	EXEC dbo.Acc_CheckSettledDate @winlostdate = @winlostdate,@UserID = @UserID,@ErrCode = @ErrCode OUTPUT,	@ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode <> 0 RETURN


------ Check transaction had been deleted or not
	IF @liveindicator = 1
	BEGIN 
		SELECT	@ErrMsg ='Unable to delete this transaction due to it is marked as "Deleted"!',
				@ErrCode = 102
		RETURN 		
	END

---*** Update balance
	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)
				
	--Get data before update
	INSERT INTO #BeforeUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN	custInfo c WITH (NOLOCK) 
		ON	b.custid = c.custID
	WHERE	b.refno = @refno AND matchid = 0 AND bettype > 20000
			AND c.roleid = 1
	GROUP BY b.CustID
	


---- Begin reversal
	SET @transdesc = '(Reversal) ' + @transdesc
	
	INSERT INTO bettrans (	custid, transdate, Username, refno, winlost, actual_stake, winlostdate, transdesc, creator,
							bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, ip, status, statusID, ruben, liveindicator)
	OUTPUT  INSERTED.transid into @TransIDs
	SELECT	custid, CURRENT_TIMESTAMP, Username, refno, actual_stake, winlost, winlostdate, @transdesc, @UserID,
			bettype, matchid, actualrate, recommend, mrecommend, srecommend, currency, CurrencyName, @IP, status, statusID, ruben, 1
	FROM	@Reversal

	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
				@ErrCode = 103
		RETURN 
	END

 ---Update Liveindicator = 1 for marking deleted transaction
	UPDATE	bettrans WITH (UPDLOCK, ROWLOCK) 
	SET		liveindicator = 1
	WHERE	transid IN (Select transid from @Reversal)

	IF @@ERROR <> 0
	BEGIN
		DELETE  bettrans WITH (UPDLOCK, ROWLOCK) 
		WHERE	transid IN (SELECT transid FROM @TransIDs)
	
		SELECT	@ErrMsg ='Delete the transaction unsuccessfully!',
				@ErrCode = 104
		RETURN 
	END


--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN	custInfo c WITH (NOLOCK) 
		ON	b.custid = c.custID
	WHERE	b.refno = @refno AND matchid = 0 AND bettype > 20000
			AND c.roleid = 1
	GROUP BY b.CustID

---insert data into pending balance table 
		INSERT INTO BalancePendingCredit (custid,Balance)
		SELECT		a.custid, (a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) > 0

		INSERT INTO BalancePendingDebit (custid,Balance)
		SELECT		a.custid, ABS(a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) < 0



	EXEC DBPOLICY.bodb02.dbo.Acc_ExchangeRateUpdisDeleted @refNo = @refno

	declare @LogData varchar(200)
	Select @LogData = 'Delete transaction for custid :' + convert(varchar(20), @CustID) + ' Ref.NO ' + convert(varchar(20), @RefNo)
	
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
	END TRY
	BEGIN CATCH 
		Select @LogData = @LogData + ' ErrMsg=' + error_message()
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
	END CATCH

END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelTransaction] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelTransaction] TO [vnteam]