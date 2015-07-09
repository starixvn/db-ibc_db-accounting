ALTER PROCEDURE [dbo].[Acc_ResetWinning_Ins]
	@winlostdate	datetime,
	@userID			int,
	@custid			int = 44621,
	@username		varchar(50) = 'IBC 0506',
	@transdesc1		nvarchar(4000) = NULL,
 	@transdesc2		nvarchar(4000) = NULL,
	@transdesc3		nvarchar(4000) = NULL,
	@transdesc4		nvarchar(4000) = NULL,
	@IP				varchar(15)='',
	@ErrCode		int = 0 output,
	@ErrMsg			nvarchar(500) ='' output 
	
AS

/*	Creator: Jamie
	Date: 2010-09-16
	Task: Reset Winning - Insert transaction
	DB: DBTRANS.BODB02, DB06.BODB02
	
	Revision:
		- 20101231@Lukas: Re-arrange bettype
		- 20130910@Elodie: Use alias server DBPOLICY instead of DB03
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON	
	
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @userID, @funcname = '[ResetWinning]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		IF @ErrCode <> 0 
			RETURN	

	IF EXISTS (SELECT 1 FROM Bettrans WITH (NOLOCK) WHERE bettype IN (21001,21002) AND custid = @custid AND matchID = 0 AND winlostdate = @winlostdate)
	BEGIN
		SELECT @ErrMsg = 'Already reset winning on ' + convert(varchar(15),@winlostdate, 107), @ErrCode = 101		
		RETURN	
	END

	DECLARE	@tmpWinLoss TABLE(
		Place		TINYINT,
		Bettype		AS (CASE WHEN Amount > 0 THEN 21001 ELSE 21002 END ),
		Transdesc	NVARCHAR(1000),
		Amount		MONEY
	)
			

	INSERT INTO @tmpWinLoss(Place, Transdesc, Amount)	

	SELECT  1,
			CASE WHEN -ISNULL(SUM((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*actualrate),0) < 0 THEN 'LOSE' ELSE 'WON' END, 
			-ISNULL(SUM((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*actualrate),0)
	FROM	bettrans WITH (NOLOCK)
    WHERE   winlostdate = @winlostdate AND
            ruben=1 AND               
            bettype < 31 AND bettype NOT IN (9,10) AND
            matchid>=0 AND
			--status not in ('VOID','REJECT','REFUND')
			statusID NOT IN (101,102,103)

	UNION ALL
	------------------------------------------------
	-- Mix Parlay
	------------------------------------------------
	select  case when bettrans.status='LOSE' then 2 else 3 end,
			'Parlay-' + case when bettrans.status='LOSE' THEN 'WON' ELSE 'LOSE' END bettype ,
			-ISNULL(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*bettrans.actualrate),0) 

	from	bettrans bettrans with (nolock)
	where	bettrans.winlostdate = @winlostdate
			and bettrans.ruben=1  
			and bettrans.matchid = 9
			and bettrans.bettype=9 
			--and bettrans.status not in ('VOID','REJECT','REFUND')
			and bettrans.statusID not in (101,102,103,111)
	group by bettrans.status 

	------------------------------------
	--- OUTRIGHT 
	------------------------------------
	union all
	select  4,
			'Outright', 
			-ISNULL(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*bettrans.actualrate),0) as LineTotal
	from bettrans bettrans with (nolock)
	where	bettrans.winlostdate = @winlostdate
			and bettrans.ruben=1  
			and bettrans.bettype=10 
			and bettrans.matchid >0 
			--and bettrans.status not in ('VOID','REJECT','REFUND')
			and bettrans.statusID not in (101,102,103)

	DELETE FROM @tmpWinLoss WHERE	Amount = 0	

	UPDATE	@tmpWinLoss
	SET		Transdesc = CASE Place	WHEN 1 THEN ISNULL(@transdesc1,transdesc) 
									WHEN 2 THEN ISNULL(@transdesc2,transdesc) 
									WHEN 3 THEN ISNULL(@transdesc3,transdesc) 
									WHEN 4 THEN ISNULL(@transdesc4,transdesc)
									ELSE '' END 

	DECLARE	@bettype INT, @transdesc NVARCHAR(4000), @amount MONEY
			, @winlost MONEY, @actual_stake MONEY, @RefNo BIGINT, @gRefno INT 
			, @recommend INT, @MRecommend INT, @SRecommend INT
			, @currency	INT, @currencyName VARCHAR(10), @actualrate FLOAT
			, @transID BIGINT  

	SELECT	@recommend = ci.recommend, @mrecommend = ci.mrecommend , @srecommend = ci.srecommend 
			, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate 
	FROM	Custinfo ci WITH (NOLOCK)
			INNER JOIN Exchange e WITH (NOLOCK) ON ci.currency = e.exchangeid 
	WHERE	ci.custid = @custid 

	DECLARE	CS_Winloss	CURSOR FOR
	SELECT	bettype, transdesc, amount
	FROM	@tmpWinLoss
	
	OPEN	CS_Winloss
	FETCH NEXT FROM CS_Winloss INTO @bettype, @transdesc, @amount 
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @bettype = 21001 
		BEGIN
			SELECT @winlost = @amount, @actual_stake = 0  
		END
		ELSE SELECT	@winlost = 0, @actual_stake = ABS(@amount)
		
		EXEC dbo.Acc_SelRefNo @refNo = @gRefno OUTPUT

		SELECT @RefNo = @gRefno + 100000000000

		INSERT INTO bettrans( custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
							  winlostdate, creator,recommend,mrecommend,srecommend,currency, currencyName,
							  actualrate,ruben, status,ip,statusID)
		VALUES (@CustID, @username, @RefNo, current_timestamp, 0, @bettype, @transdesc, @winlost, @actual_stake, 
				@winlostdate, @UserID, @Recommend, @MRecommend, @SRecommend, @currency, @currencyName,
				@actualrate,1, 'Completed',@ip,131)
		SELECT @TransID = @@IDENTITY

		if @@ERROR <> 0
		BEGIN
			DELETE dbo.bettrans
			WHERE custid = @CustID
				and matchid = 0
				and bettype = @bettype
				and refno = @refno
			
			Select @ErrMsg = 'Insert trans failed. Please try again.', @ErrCode = 103		
			return
		END

		DECLARE @LogData NVARCHAR(200)
		SELECT	@LogData = 'Reset Winning :' + convert(varchar(20), @CustID) + ' with amount ' + convert(varchar(20), @amount) + ' Ref.NO ' + convert(varchar(20), @RefNo) + ' TransID ' + convert(varchar(20), @TransID)  

		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
		
		FETCH NEXT FROM CS_Winloss INTO @bettype, @transdesc, @amount 
	END
	CLOSE CS_Winloss
	DEALLOCATE CS_Winloss 
	
END


GO
GRANT EXECUTE ON [dbo].[Acc_ResetWinning_Ins] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ResetWinning_Ins] TO [vnteam]
GO