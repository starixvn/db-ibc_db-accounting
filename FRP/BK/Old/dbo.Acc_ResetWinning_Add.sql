ALTER PROCEDURE [dbo].[Acc_ResetWinning_Add]
	@winlostdate	DATETIME,
	@userid		INT,
	@custid		INT = 44621,
	@username	VARCHAR(50) = 'IBC 0506',	
	@amount		MONEY,
	@transdesc  VARCHAR(200)='Adjustment Balance',	
	@IP			VARCHAR(15)='',
	@ErrCode	INT = 0 output,
	@ErrMsg		NVARCHAR(500) ='' output 
AS
/*	
	Creator: Johnson
	Date:	2011-01-12
	Task:	Reset Winning- Add Adjust Transaction after Reset Winning but balance not be zero
	DB:		DBTRANS.BODB02, DB06.BODB02	
	Revision:
		- 20130910@Elodie: Use alias server DBPOLICY instead of DB03
	
	Explanation's Param:
*/	
BEGIN
	SET NOCOUNT ON
	
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @userID, @funcname = '[AddFinanceTrans]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		IF @ErrCode <> 0 
			RETURN
	
	DECLARE	@bettype INT, @winlost MONEY, @actual_stake MONEY, @RefNo BIGINT, @gRefno INT ,
			@recommend INT, @MRecommend INT, @SRecommend INT, @currency	INT, 
			@currencyName VARCHAR(10), @actualrate FLOAT, @transID BIGINT 
	
	SELECT	@recommend = ci.recommend, @mrecommend = ci.mrecommend , @srecommend = ci.srecommend 
			, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate 
	FROM	Custinfo ci WITH (NOLOCK)
			INNER JOIN Exchange e WITH (NOLOCK) ON ci.currency = e.exchangeid 
	WHERE	ci.custid = @custid
	
	EXEC dbo.Acc_SelRefNo @refNo = @gRefno OUTPUT
	
	SELECT @RefNo = @gRefno + 100000000000
	
	IF @amount > 0 
		 SELECT @bettype = 21001, @winlost = @amount, @actual_stake = 0 
	ELSE 
		 SELECT @bettype = 21002, @winlost = 0, @actual_stake = abs(@amount)
			
	INSERT INTO bettrans( custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						  winlostdate, creator,recommend,mrecommend,srecommend,currency, currencyName,
						  actualrate,ruben, status,ip,statusID)
	VALUES (@CustID, @username, @RefNo, current_timestamp, 0, @bettype, @transdesc, @winlost, @actual_stake, 
			@winlostdate, @UserID, @Recommend, @MRecommend, @SRecommend, @currency, @currencyName,
			@actualrate,1, 'Completed',@ip,131)
			
	SELECT @TransID = SCOPE_IDENTITY()

	IF @@ERROR <> 0
	BEGIN
		delete bettrans where refno = @refno and matchid = 0
		Select @ErrMsg = 'Insert trans failed. Please try again.', @ErrCode = 103		
		return
	END

	DECLARE @LogData NVARCHAR(200)
	SELECT	@LogData = 'Delete Finance Transaction : ' + convert(varchar(20), @CustID) + ' with amount ' + convert(varchar(20), @amount) + ' Ref.NO ' + convert(varchar(20), @RefNo) + ' TransID ' + convert(varchar(20), @TransID)  

	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
					
END


GO
GRANT EXECUTE ON [dbo].[Acc_ResetWinning_Add] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ResetWinning_Add] TO [vnteam]
GO
