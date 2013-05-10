ALTER PROCEDURE [dbo].[Acc_BettransDelBet_Parlay]
	@transid bigint,
	@custid int = 0,
	@username varchar(50),
	@password varchar(50),	
	@UserID int,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT

AS
/*
	Created: Daniel@20120202
	Task: delete whole parlay ticket
	DB: DBTXN/bodb02
	Original: DBA_DeleteBet_Parlay
	
	Revisions:
		- 20120411@Sophia: Revise update balance credit/debit
		- 20130201@Elodie: Change link server DB03 to DBPOLICY
						   Add table TempVariableNumber to check and not to allow attempt to delete same game while it's still not finish
						   Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   
						   Write more log on DBTXN server in case of DBLOG server failure

*/
SET NOCOUNT ON

--Check permission for account site:
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteBets]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN

Declare @LogData nvarchar(200), @statusID int, @balance MONEY, @winlostdate datetime, @matchid int, @Remark VARCHAR(500)
select @ErrCode = 0

If NOT EXISTS (select 1 from customer c with (nolock) where userpwd = @password and custid = @userid and roleid >= 5)
BEGIN
	Select @ErrMsg = 'Wrong username/password or You do not have permission to delete this bet!!', @ErrCode = 101	
	SELECT @LogData = 'Try to delete transaction for custid ' + cast(@CustID as varchar(10)) + ' - Transid ' + cast(@transid as varchar(20)) + ' - Username ' + @username
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData	
	Return
END

if NOT EXISTS(select 1 from bettrans with (nolock) where transid = @transid)--cannot find valid ticket
BEGIN
	SELECT @ErrMsg =  'Sorry! No ticket with such transid', @ErrCode = 102	
	return
END

select @statusID = statusID from bettrans with (nolock) where transid = @transid

if @statusID <> 0
BEGIN
	SELECT @ErrMsg =  'Sorry! You can only delete running tickets', @ErrCode = 103
	return
END

SELECT	@winlostdate = b.winlostdate, @matchid = matchid
FROM	bettrans b with (nolock)
WHERE	b.transid = @transid

--Check settled Date
EXEC dbo.Acc_CheckSettledDate @winlostdate = @winlostdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
If @ErrCode <> 0
	RETURN

---- check and not allow attempt to delete same game while it's still not finish
IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
IF (@@Error = 0)
BEGIN TRY
	SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelBet_Parlay TransID=' + + cast(@transid as varchar(20))
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
		@UserID = @UserID, 
		@Matchid = @matchid, 
		@KeyID = 1,
		@ActionID = 0, 
		@Remark = @Remark
END TRY
BEGIN CATCH
	SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelBet_Parlay TransID=' + + cast(@transid as varchar(20)) + ' ErrMsg='+ left(error_message(), 400)
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
		@UserID = @UserID, 
		@Matchid = @matchid, 
		@KeyID = 1,
		@ActionID = 0, 
		@Remark = @Remark
END CATCH
ELSE 
BEGIN
	SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

-- get balance
SELECT @balance = winlost-actual_stake+playercomm
FROM bettrans WITH(NOLOCK)
WHERE transid = @transid AND bettype = 9
	
-- STEP 1 : BackUp
insert into 
	zzzbettrans 
	(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
select 
	 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
from 
	bettrans with (nolock)
where transid = @transid
	  AND bettype = 9

-- STEP 2 : Update

-----Update debit balance 
IF @balance > 0
BEGIN 
	EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
END

--Delete
update  
	bettrans with (ROWLOCK, UPDLOCK)
SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', statusID=102 , creator = @UserID,
	awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0
where transid = @transid
 
-----Update Credit balance 
IF @balance < 0
BEGIN
	SET @balance = ABS(@balance)
	EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
END

Select @LogData ='delete parlay ticket for transid ' + convert(varchar(20), @transid) + ' by_login:' + @username + 'IP:' + cast(@IP as varchar(15))
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

-----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 1 AND KeyValue = @matchid	
IF (@@Error = 0)
	BEGIN TRY
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelBet_Parlay TransID=' + + cast(@transid as varchar(20))
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = @Remark
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelBet_Parlay TransID=' + + cast(@transid as varchar(20)) + ' ErrMsg='+ left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE
	BEGIN
		BEGIN TRY
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelBet_Parlay TransID=' + + cast(@transid as varchar(20))
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelBet_Parlay TransID=' + + cast(@transid as varchar(20)) + ' ErrMsg='+ left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
	END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelBet_Parlay] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelBet_Parlay] TO [vnteam]