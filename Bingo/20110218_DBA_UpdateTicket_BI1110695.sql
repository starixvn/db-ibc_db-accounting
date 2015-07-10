  --ALTER PROCEDURE [dbo].[Dot_Bingo_BetIns] 
 
 	DECLARE @custid	int, @BI_Turnover money, @BI_Winlost money,	@BI_swinlost money,	@BI_mwinlost money,	@BI_awinlost money
	DECLARE @BI_scomm money, @BI_mcomm money ,@BI_acomm money,@BI_playercomm money 
	DECLARE @BI_pendingAmount money ,@BI_sposition smallmoney ,	@BI_mposition smallmoney,@BI_aposition smallmoney
	
	DECLARE @refno bigint, @sessionId bigint,@transdesc	nvarchar(300),@ip nvarchar(15)
	DECLARE @ErrCode int ,	@ErrMsg nvarchar(200)
	
	SET @custid=1375282	
------------------------bingo
	SET @BI_Turnover = 200
	SET @BI_Winlost	 = 0
	SET @BI_swinlost = 20
	SET @BI_mwinlost = 10
	SET @BI_awinlost = 130
	SET @BI_scomm	 = 0
	SET @BI_mcomm	 = 0
	SET @BI_acomm	 = 0
	SET @BI_playercomm = 0
	SET @BI_pendingAmount = 0
	SET @BI_sposition  = 0
	SET @BI_mposition  = 0
	SET @BI_aposition  = 0
	
	SET @refno=100110186364	
	SET @sessionId = 1375
	SET @transdesc=''	
	SET @ip	=''
	SET @ErrCode=0
	SET @ErrMsg= ''
--AS
/*
Creator : Jamie
Date : 2010-09-11
Task : Insert Bingo Bet tickets
DB: DB02.bodb02

Revisions:

Param's Explanation:

• Full structure of Dummy accounts:
		--ACC Super		3rdSuperUUS		3rdSuperEURO    other currencies...
		--ACC Master	BIUS$			BIEURO
		--ACC Agent		BIUS$01			BIEURO01
		--ACC Member	BIBetUS$		BIBetEURO

• @bingoTurnover: always positive 
• @bingoWinlost: bingoWinlost = bingoTurnover + member's winlost 
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
	
• @ErrMsg: Error description.

*/

SET NOCOUNT ON

DECLARE	@roleid				tinyint,
		@username			varchar(30),
		@recommend			int, 
		@mrecommend			int, 
		@srecommend			int, 
		@actualrate			float, 
		@BI_mem_status		nvarchar(10),
		@BI_mem_statusID	int,
		@currency			tinyint, 
		@currencyName		nvarchar(5), 
		@transdate			datetime, 
		@winlostdate		datetime,
		@dummy_username		nvarchar(15),
		@dummy_custid		int,
		@dummy_recommend	int,
		@dummy_mrecommend	int,
		@dummy_srecommend	int

SELECT  @ErrCode = 0, @ErrMsg = '' 

IF @BI_Turnover < 0 OR @BI_Winlost < 0 
BEGIN
	SELECT @ErrMsg = 'Sorry, amount is invalid.', @ErrCode = 101	
	RETURN		
END

SELECT	@username= ci.username,
		@roleid = isnull(ci.roleid,0), 
		@recommend = ci.recommend,
		@mrecommend = ci.mrecommend, 
		@srecommend = ci.srecommend,
		@currency = ci.currency, 
		@currencyName = e.currency, 
		@actualrate = e.actualrate

FROM	custinfo ci WITH (NOLOCK) 
		INNER JOIN exchange e WITH (NOLOCK) on ci.currency = e.exchangeid
WHERE   ci.custid = @custid 

IF @roleid <> 1
BEGIN
	SELECT @ErrMsg = 'Invalid Role ID.', @ErrCode = 102		
	RETURN
END
--check if srecommend < 100 and scomm <> mcomm and swinlost <>0
--member of direct master can not have supercomm<>scomm or swinlost <>0
if @srecommend<100 and (@BI_scomm <> @BI_mcomm or @BI_swinlost <>0 )
begin
	SELECT @ErrMsg = 'Invalid super/master comm or super winloss for member of direct master!', @ErrCode = 103		
	RETURN
end

--check not allow to update when there is no RUNNING transfer transaction
/*if NOT exists (select 1 from bettrans with (nolock)
            where matchid=0 and custid = @custid and bettype = 117 and ruben = 0 and refno=@refno 
            )
BEGIN
    SELECT @ErrMsg = 'There is NO running Bingo transfer transaction (match with the session/refno)!', @ErrCode = 104		
	RETURN
END*/


SELECT @BI_mem_status = CASE WHEN @BI_Winlost > @BI_Turnover THEN 'WON'
						  WHEN @BI_Winlost < @BI_Turnover THEN 'LOSE'
						  ELSE 'DRAW' END 
						  
SELECT @BI_mem_statusID = CASE WHEN @BI_Winlost > @BI_Turnover THEN 112
						  WHEN @BI_Winlost < @BI_Turnover THEN 113
						  ELSE 111 END 

SELECT	@dummy_custid = c.custid,
		@dummy_username = c.username,
		@dummy_recommend = c.recommend,
		@dummy_mrecommend = c.mrecommend,
		@dummy_srecommend = c.srecommend
FROM	custinfo c WITH (NOLOCK) 
WHERE	c.username = 'BIBet' + @currencyName AND c.roleid = 1 

IF isnull(@dummy_custid, 0) = 0
BEGIN
	SELECT @ErrMsg = 'Invalid Dummy account or Account is not existed!', @ErrCode = 106		
	RETURN
END

------------------Insert trans into DB---------------------------------------------------------------
SELECT	@transdesc = 'Bingo Betting' + CASE WHEN @transdesc <> '' THEN ' - ' + @transdesc ELSE '' END

SELECT @transdate = '2011-02-16' , @winlostdate = '2011-02-16'

IF (@BI_Turnover > 0 or @BI_Winlost > 0)
BEGIN
---INSERT bingo BET TICKET 
	INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, stake, actual_stake, 
	 awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, winlostdate, creator, 
	 recommend, mrecommend, srecommend, playerdiscount, discount, adiscount, sdiscount, 
	 apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, currency, actualrate, currencyName, 
	 ruben, status,statusID,ip,betid)
	VALUES 
	(@CustID, @username, @refno, @transdate, 0, 73, @transdesc, @BI_Winlost, @BI_Turnover, @BI_Turnover,
	 @BI_awinlost, @BI_mwinlost, @BI_swinlost, @BI_playercomm, @BI_acomm, @BI_mcomm, @BI_scomm, @winlostdate, 
	 @CustID, @Recommend, @MRecommend, @SRecommend, 0, 0, 0, 0, @BI_aposition, @BI_mposition, @BI_sposition, @BI_aposition +@BI_mposition + @BI_sposition, 
	 @Currency, @actualrate, @currencyName, 1, @BI_mem_status,@BI_mem_statusID, @ip,@sessionId)

	IF @@ERROR <> 0
	BEGIN			
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 107	
		RETURN
	END	
END

---INSERT bingo PENDING BET TICKET 
IF @BI_pendingAmount > 0
BEGIN
	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, stake,
		 awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, winlostdate, creator, 
		 recommend, mrecommend, srecommend, playerdiscount, discount, adiscount, sdiscount, 
		 apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, currency, actualrate, currencyName, 
		 ruben, status,statusID,ip,betid)
	VALUES 
		(@CustID, @username, @refno, @transdate, 0, 118, @transdesc, 0, @BI_pendingAmount, @BI_pendingAmount,
		 0, 0, 0, 0, 0, 0, 0, @winlostdate, 
		 @CustID, @Recommend, @MRecommend, @SRecommend, 0, 0, 0, 0, 0, 0, 0, 0, 
		 @Currency, @actualrate, @currencyName, 0, 'running',0, @ip,@sessionId)

	IF @@ERROR <> 0
	BEGIN			
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 107	
		DELETE FROM bettrans WHERE custid = @custid and refNo = @refno AND bettype =73 and matchid = 0
		RETURN
	END	
END


IF (@BI_Turnover > 0 or @BI_Winlost > 0)
BEGIN
	--INSERT bingo DUMMY TICKET
	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, stake, actual_stake, 
		 awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, winlostdate, creator, 
		 recommend, mrecommend, srecommend, playerdiscount, discount, adiscount, sdiscount, 
		 apositiontaking, mpositiontaking, spositiontaking, tpositiontaking,
		 currency, actualrate, currencyName, ruben, status,statusID,ip,betid)
	VALUES 
		(@dummy_custID, @dummy_username, @refno, @transdate, 0, 73, @transdesc, @BI_Turnover, @BI_Winlost,@BI_Winlost,
		 -@BI_awinlost, -@BI_mwinlost, -@BI_swinlost, -@BI_playercomm, -@BI_acomm, -@BI_mcomm, -@BI_scomm, @winlostdate, @dummy_custID, 
		 @dummy_recommend, @dummy_mrecommend, @dummy_srecommend, 0, 0, 0, 0, 0, 0, 0, 0, 
		 @Currency, @actualrate, @currencyName, 1, 'DONE',121, @ip,@sessionId)

	IF @@ERROR <> 0
	BEGIN			
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 107	
		DELETE FROM bettrans WHERE refNo = @refno AND bettype in (73,118) and matchid = 0
		RETURN
	END
END

--UPDATE MEMBER TRANS 
UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
    SET status = 'Completed',statusID=131, ruben = 1, winlost = actual_stake
WHERE custid=@custid and refno = @refno and bettype = 117 and matchid = 0

IF @@ERROR <> 0
BEGIN			
	SELECT @ErrMsg = 'Update transaction failed.', @ErrCode = 108	
	--delete all trans of current session
	DELETE FROM bettrans WHERE refNo = @refno AND bettype in (73,118) and matchid = 0
	RETURN
END


--UPDATE MEMBER PENDING BINGO TRANS OF PREVIOUS SESSION
UPDATE bettrans WITH (ROWLOCK, UPDLOCK) SET status = 'Completed',statusID=131, ruben = 1, winlost = actual_stake 
WHERE custid = @custid and bettype = 118 and ruben = 0 and refno <> @refno and matchid = 0
IF @@ERROR <> 0
BEGIN			
	SELECT @ErrMsg = 'Update transaction failed.', @ErrCode = 108	
	--revert transfer trans
	UPDATE bettrans WITH (ROWLOCK, UPDLOCK) SET status = 'running',statusID=0, ruben = 0, winlost = 0 
	WHERE refno = @refno and bettype = 117 and ruben = 1 and matchid = 0 
	--delete all trans of current session
	DELETE FROM bettrans WHERE refNo = @refno AND bettype in (73,118) and matchid = 0
	RETURN
END

---------------------------------------------------------------------------------------------------

DECLARE @LogData nvarchar(300)

SELECT @LogData = 'Bingo Betting custid = ' + convert(nvarchar(20), @custid) + ', bettype = 73'  + ', bingoTurnover = ' + convert(nvarchar(20), @BI_Turnover) 
					 + ', bingoWinlost = ' + convert(nvarchar(20), @BI_Winlost) 
					 + case when @BI_pendingAmount > 0 then ', bingoPendingAmount = '+ convert(nvarchar(30),@BI_pendingAmount) else '' end
					 + ', refNo = ' + convert(nvarchar(20),@refno)  +', currency = ' + convert(nvarchar(10),@currency) 
					 + ', bingoPlayercomm = ' + convert(nvarchar(10),@BI_playercomm) + ', IP = '+ @ip 

BEGIN TRY
	EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData
END TRY
BEGIN CATCH
	-- if write log error: not return error code
END CATCH

/*GO
GRANT EXECUTE ON [dbo].[Dot_Bingo_BetIns] TO [Dot_Member]
GO
GRANT EXECUTE ON [dbo].[Dot_Bingo_BetIns] TO [Dot_Casino]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Bingo_BetIns] TO [vnteam]*/