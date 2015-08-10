USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_BettransDelBet]    Script Date: 08/10/2015 13:55:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_BettransDelBet]
	@transid bigint = 0,
	@custid int = 0,
	@username varchar(50),
	@password varchar(50),
	@UserID int = 0, --custid of Admin,
	@IP varchar(15) = '',
	@reason nvarchar(500)= '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
-- Admin : for Delete ticket
-- Call via Account/deletebet.asp
-- submit from Account/betslip.asp
 
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
		- 20130526@Johnson: Add param @reason to log the reason delete bets				   
		- 20130603@Johnson: get additional information for mailing
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, Customer, Dep_CustSuper, Exchange by link database)						   
		- 20140421@Kathy: Allow more accounts to void settled ticket
		- 20150805@Kathy: Using new balance table (BalCreditSports,BalDebitSports) [Redmine:#40125]
*/

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteBets]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

DECLARE @LogData NVARCHAR(500), @balance MONEY , @winlostdate datetime, @bettype int, @refno bigint, @matchid int, @Remark VARCHAR(500),
		-- check customer for mailing live cs
		@isDepositCust BIT, @is12EUCust BIT, @isRealCust BIT, @srecommend INT,@bet_username NVARCHAR(50), @currency INT, @betfrom NVARCHAR(1)
		,@balance_type TINYINT

If NOT EXISTS (select 1 from CustDB.dbo.customer c with (nolock) where userpwd = @password and custid = @userid and roleid >= 5)
BEGIN
	Select @ErrMsg = 'Wrong username/password or You do not have permission to delete this bet!!', @ErrCode = 101	
	SELECT @LogData = 'Try to delete transaction for custid: ' + cast(@UserID as varchar(10)) + ' betlist: ' + cast(@transid as varchar(20)) + ' - Username: ' + @username + ' - reason: ' + @reason
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData	
	Return
END

If @userid in (	352361		-- Erica
				,661969		-- Erica1
				,352362		-- Jane
				,1070340	-- pgmKiwi
				,360418		-- dbaThien
				,862400		-- pgmViet
				,8			-- sa
				,1274		-- Steven				
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

SELECT	@winlostdate = b.winlostdate, @bettype = bettype, @matchid = matchid, @refno = refno, @betfrom = betfrom
FROM	bettrans b with (nolock)
WHERE	b.transid = @transid

SELECT  @balance_type = CASE WHEN sporttype = 161 THEN 4 -- NG --> others
							 WHEN sporttype = 162 THEN 3 -- LC --> Casino
							 ELSE 1 -- SB --> Sports
						END
FROM	match WITH(NOLOCK)
WHERE	matchid = @matchid

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
from odds o with (rowlock)
	INNER JOIN bettrans b with (nolock) ON o.oddsid=b.oddsid
	INNER JOIN CustDB.dbo.customer c with (nolock) ON c.custid=b.custid
	INNER JOIN CustDB.dbo.exchange e with (nolock) ON c.currency=e.exchangeid
where b.transid = @transid


IF EXISTS (SELECT transid FROM bettrans (nolock) WHERE custid = @custid AND transid = @transid)
	IF EXISTS (SELECT custid FROM  CustDB.dbo.customer (nolock) WHERE custid = @UserID)
	BEGIN
		-- calculate balance of customer
		DECLARE @isNegativeBalance BIT, @totalbalance MONEY
		
		SELECT	@balance = (winlost - actual_stake + playercomm)
		FROM	bettrans with (nolock)
		WHERE	transid = @transid
		
		
		SELECT	@totalbalance = SUM(winlost - actual_stake + playercomm)
		FROM	bettrans with (nolock)
		WHERE	custid = @custid
		
		SELECT @isNegativeBalance = CASE WHEN @balance > 0 AND (credit + @totalbalance - @balance) < 0 THEN 1 ELSE 0 END,
			@bet_username = username,
			@srecommend = srecommend,
			@currency = currency
		FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK)
		WHERE custid = @custid 
		
		--return all additional information for mailing
		IF @keyID = 2 --outright bettype
		BEGIN 
			SELECT
			MATCH.teamid AS homeid,
			0 AS awayid,
			MATCH.matchcode,
			MATCH.eventdate,
			MATCH.leagueid,
			GETDATE() AS DATETIME,
			CONVERT(BIT,0) AS IsNeutral
		FROM
			Outright AS MATCH WITH (NOLOCK)
		WHERE 
			MATCH.orid = @matchID
		END   
		ELSE
		BEGIN
			SELECT
				MATCH.homeid,
				MATCH.awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				showtime AS GameEvent
			FROM
				MATCH WITH (NOLOCK)
			WHERE 
				MATCH.matchid = @matchID
		END
		
		SELECT
			customer.username,
			customer.username2,
			b.odds,  
			b.OddsType, 
			b.transdate,
			b.bettype,
			b.transid AS refno,
			betteam,
			hdp1,
			hdp2,
			betfrom,
			livehomescore,
			liveawayscore,
			liveindicator,
			cr.username creator,
			stake,     
			b.status,
			b.spositiontaking,
			b.mpositiontaking,
			b.apositiontaking,
			b.winlost - actual_stake as winlost,
			b.playercomm as comm,      
			b.currency,
			ag.site,
			@isNegativeBalance as isNegative
		FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN CustDB.dbo.customer  WITH (NOLOCK) ON customer.custid=b.custid
			INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
			INNER JOIN CustDB.dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		WHERE b.transid = @transid
		
		--check for live casino
		IF @bettype IN (1101,1102)
		BEGIN
			SELECT @isDepositCust = CASE WHEN @betfrom IN ('D', 'M', 'E', 'L') AND @srecommend IN (SELECT custid FROM CustDB.dbo.Dep_CustSuper WITH (NOLOCK)) THEN 1 ELSE 0 END 
			SELECT @is12EUCust	 = CASE WHEN @bet_username = '12EU' THEN 1 ELSE 0 END
			SELECT @isRealCust = CASE WHEN @currency = 20 THEN 1
									WHEN @currency <> 20 AND (@Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam') THEN 1 
									ELSE 0 END
			
			SELECT CASE WHEN @isDepositCust = 1 THEN 1 ELSE @is12EUCust END as isDeposit,
				@isRealCust as isRealCust, @transid as refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
			FROM bettransG bg WITH(NOLOCK)	
			WHERE bg.refno = @refno
		END
			
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
			--EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
			EXEC dbo.Dot_BalanceDebitUpd 
				@custID		= @custid
				,@balance	= @balance
				,@type		= @balance_type 
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
			--EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
			EXEC dbo.Dot_BalanceCreditUpd
				@custID		= @custid
				,@balance	= @balance
				,@type		= @balance_type
		END		
			
		SELECT @LogData = 'delete transaction for custid:' +cast(@custid as varchar(10))+' transid:' + cast(@transid as varchar(20))+ ' by_login:' + @username + 'IP:' + cast(@IP as varchar(15)) + ' reason: ' + @reason
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
GRANT EXECUTE ON [dbo].[Acc_BettransDelBet] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelBet] TO [ITVivi] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelBet] TO [vnteam] AS [dbo]