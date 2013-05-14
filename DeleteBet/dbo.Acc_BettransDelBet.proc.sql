ALTER PROCEDURE [dbo].[Acc_BettransDelBet]
	@transid bigint = 0,
	@custid int = 0,
	@username varchar(50),
	@password varchar(50),
	@UserID int = 0, --custid of Admin,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
-- Admin : for Delete ticket
-- Call via Account/deletebet.asp
-- submit from Account/betslip.asp
 --test
/*	Created by: [Creator]
	Task:  Delete bet
		   left menu (member)/Belist/Button Delete bet
	DB: DBTXN/bodb02
	Original: Admin_DeleteBet
	
	Revisions:
		- 20090828@HuyNguyen: replace [DeleteBets] --> [DeleteTrans]
		- 20091012@Kiwi: Remove custBetCredit and WriteLog_UserLog_RunSP
		- 20091125@Kiwi: Remove comstatus because it's no used.			
		- 20091209@Daniel: Change back [DeleteBTrans] --> [DeleteBets]
		- 20100424@Henry:  UPDATE statusID of bettrans14 (StatusID = 102 for status VOID)
		- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20101007@Henry: Change column transid from INT to BIGINT
		- 20111125@Sophia:  .Update banlance credit/ debit for customer
							.Check settled Date
		- 20111519@Lukas: force userid & username are the same admin
		- 20120411@Sophia: Revise update balance credit/debit
		- 20130201@Elodie: Change link server DB03 to DBPOLICY
						   Add table TempVariableNumber to check and not to allow attempt to delete same game while it's still not finish
						   Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   
						   Write more log on DBTXN server in case of DBLOG server failure
						   
*/

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteBets]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

DECLARE @LogData NVARCHAR(500), @balance MONEY , @winlostdate datetime, @bettype int, @matchid int, @Remark VARCHAR(500)

If NOT EXISTS (select 1 from customer c with (nolock) where userpwd = @password and custid = @userid and roleid >= 5)
BEGIN
	Select @ErrMsg = 'Wrong username/password or You do not have permission to delete this bet!!', @ErrCode = 101	
	SELECT @LogData = 'Try to delete transaction for custid: ' + cast(@UserID as varchar(10)) + ' betlist: ' + cast(@transid as varchar(20)) + ' - Username: ' + @username
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData	
	Return
END

If @userid in (	8		-- sa
				,25520  -- Joe
				,1274   -- Steven
				,360418 -- dbaThien
				,633916 --twTim
			   )
BEGIN
	if not exists (select * from bettrans with (nolock) where transid = @transid and custid = @custid)
	BEGIN
		Select @ErrMsg = 'Invalid bet transaction!!', @ErrCode = 102
		Return
	END
END
ELSE
BEGIN
	if not exists (select * from bettrans with (nolock) where transid = @transid and custid = @custid and 
					--status in ('running','waiting','')
					statusID in (0,1)
				)
	BEGIN
		Select @ErrMsg = 'Invalid bet transaction!!', @ErrCode = 103
		Return
	END
END

SELECT	@winlostdate = b.winlostdate, @bettype = bettype, @matchid = matchid
FROM	bettrans b with (nolock)
WHERE	b.transid = @transid

--Check settled Date
EXEC dbo.Acc_CheckSettledDate @winlostdate = @winlostdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
If @ErrCode <> 0
	RETURN
	
---- check and not allow attempt to delete same game while it's still not finish
DECLARE @KeyID INT

IF @bettype = 10
BEGIN 	
	SET @KeyID = 2
END
ELSE
BEGIN 	
	SET @KeyID = 1
END

IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = @KeyID AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (@KeyID, @matchid)
IF (@@Error = 0)
BEGIN TRY
	SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelBet TransID=' + + cast(@transid as varchar(20))
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
		@UserID = @UserID, 
		@Matchid = @matchid, 
		@KeyID = @KeyID,
		@ActionID = 0, 
		@Remark = @Remark
END TRY
BEGIN CATCH
	SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelBet TransID=' + + cast(@transid as varchar(20)) + ' ErrMsg='+ left(error_message(), 400)
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
		@UserID = @UserID, 
		@Matchid = @matchid, 
		@KeyID = @KeyID,
		@ActionID = 0, 
		@Remark = @Remark
END CATCH
ELSE 
BEGIN
	SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

update odds set 
	hometotal=hometotal-(case when b.betteam='h' then case when abs(b.odds)>1 then b.stake*e.actualrate*abs(b.odds)*(1-b.tpositiontaking) else b.stake*e.actualrate*(1-b.tpositiontaking) end  else 0 end ),
	awaytotal=awaytotal-(case when b.betteam='a' then case when abs(b.odds)>1 then b.stake*e.actualrate*abs(b.odds)*(1-b.tpositiontaking) else b.stake*e.actualrate*(1-b.tpositiontaking) end  else 0 end ) 
from odds o with (rowlock), bettrans b with (nolock), customer c with (nolock), exchange e with (nolock) 
where c.custid=b.custid 
	and o.oddsid=b.oddsid
	and c.currency=e.exchangeid
	and b.transid = @transid


IF EXISTS (SELECT transid FROM bettrans (nolock) WHERE custid = @custid AND transid = @transid)
	IF EXISTS (SELECT custid FROM customer (nolock) WHERE custid = @UserID)
	BEGIN
		SELECT	@balance = (winlost - actual_stake + playercomm)
		FROM	bettrans with (nolock)
		WHERE	transid = @transid
	
			
		INSERT INTO zzzbettrans
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
		FROM
			bettrans with (nolock)
		WHERE
			transid = @transid
	
		--update balance debit
		IF @balance > 0
		BEGIN			
			EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
		END
	
		--update bettrans
		UPDATE bettrans with (rowlock)
		SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,statusID = 102
		WHERE transid = @transid
		
		--update balance debit	
		IF @balance < 0
		BEGIN
			SELECT @balance = ABS(@balance)
			EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
		END		
			
		SELECT @LogData = 'delete transaction for custid:' +cast(@custid as varchar(10))+' transid:' + cast(@transid as varchar(20))+ ' by_login:' + @username + 'IP:' + cast(@IP as varchar(15))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
		
	END
-----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = @KeyID AND KeyValue = @matchid	
IF (@@Error = 0)
	BEGIN TRY
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelBet TransID=' + + cast(@transid as varchar(20))
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = @Remark
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelBet TransID=' + + cast(@transid as varchar(20)) + ' ErrMsg='+ left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE
	BEGIN
		BEGIN TRY
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelBet TransID=' + + cast(@transid as varchar(20))
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = @Remark
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelBet TransID=' + + cast(@transid as varchar(20)) + ' ErrMsg='+ left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
	END
	
GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelBet] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelBet] TO [vnteam]