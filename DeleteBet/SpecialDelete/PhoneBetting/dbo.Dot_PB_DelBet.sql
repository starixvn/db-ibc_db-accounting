ALTER PROCEDURE [dbo].[Dot_PB_DelBet]
	@transid bigint,
	@UserID int, --custid of Admin
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	Created:  
	Date:  
	Task:  Phonebetting: Delete ticket
	Original : Acc_BettransDelBet
	DB: DBTXN/BODB02
	
	Revisions:
		- 20120529@Jack Chang: Add Balance and Log
		- 20120913@Sophia: Add table TempVariableNumber to check and not to allow attempt to delete same game while it's still not finish
		- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   
		- 20130128@Elodie: Write more log on DBTXN server in case of DBLOG server failure
		- 20130207@Elodie: Add more transID into content of log and convert @actual_stake from money to varchar(20)
		
	Parameters Explanations:			
*/

BEGIN
SET NOCOUNT ON

	DECLARE @LogData NVARCHAR(200), @matchid INT, @bettype SMALLINT
	DECLARE @Remark VARCHAR(500)
	-- check ticket
	IF not exists (select * from bettrans with (nolock) where transid = @transid and statusID in (0, 1)) --0:running,1:waiting
	BEGIN
		Select @ErrMsg = 'Invalid bet transaction!!', @ErrCode = 103
		Return
	END

	SELECT @matchid = matchid, @bettype = bettype FROM bettrans WITH (NOLOCK) WHERE transid = @transid
	
	---- check and not allow attempt to delete same game while it's still not finish
	IF @bettype = 10 
	BEGIN 
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 2 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END

		INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (2, @matchid)
		IF (@@Error = 0)
		BEGIN TRY
			SELECT @Remark = 'ADD SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20))
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 2,
				@ActionID = 0, 
				@Remark = @Remark
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20)) + ' ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 2,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE 
		BEGIN
			SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END
	END	
	ELSE
	BEGIN 
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END

		INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
		IF (@@Error = 0)
		BEGIN TRY
			SELECT @Remark = 'ADD SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20))
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20)) + ' ErrMsg=' + left(error_message(), 400)
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
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
	END

	-- update odds hometotal or awaytotal
	update odds set 
		hometotal=hometotal-(case when b.betteam='h' then case when abs(b.odds)>1 then b.stake*b.virtualrate*abs(b.odds)*(1-b.tpositiontaking) else b.stake*b.virtualrate*(1-b.tpositiontaking) end  else 0 end ),
		awaytotal=awaytotal-(case when b.betteam='a' then case when abs(b.odds)>1 then b.stake*b.virtualrate*abs(b.odds)*(1-b.tpositiontaking) else b.stake*b.virtualrate*(1-b.tpositiontaking) end  else 0 end ) 
	from odds o with (nolock)
		inner join bettrans b with (nolock) on o.oddsid=b.oddsid
	where b.transid = @transid

	-- backup ticket
	INSERT INTO zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	FROM
		bettrans with (nolock)
	WHERE
		transid = @transid
	
	Declare @actual_stake money, @Custid Int
	
	
	-- update ticket to void
	UPDATE bettrans with (rowlock,updlock)
	SET  @actual_stake = winlost = actual_stake,
		@Custid = Custid,
		ruben = 1,
		status = 'Void', 
		creator = @UserID,
		awinlost = 0, mwinlost = 0, swinlost = 0, 
		playercomm = 0, comm  = 0, acomm = 0, scomm = 0,
		statusID = 102 
	WHERE transid = @transid
	
	exec Dot_BalanceUpdCredit @custid, @actual_stake, 1	
	
	-- write log
	SELECT @LogData = 'PB delete transaction for transid:' + cast(@transid as varchar(20))+ ' by_login:' + cast(@UserID as varchar(20)) + ' return custid:' + cast(@Custid as varchar(20)) + ' credit:' + cast(@actual_stake as varchar(20))
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

	-----
	IF @bettype = 10 
	BEGIN 
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 2 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN TRY
			SELECT @Remark = 'DEL SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20))
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 2,
				@ActionID = 0, 
				@Remark = @Remark
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20)) + ' ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 2,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				SELECT @Remark = 'DEL FAILED SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20))
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 2,
					@ActionID = 0, 
					@Remark = @Remark
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20)) + ' ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 2,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
	END
	ELSE 
	BEGIN 
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN TRY
			SELECT @Remark = 'DEL SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20))
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20)) + ' ErrMsg=' + left(error_message(), 400)
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
				SELECT @Remark = 'DEL FAILED SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20))
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Dot_PB_DelBet TransID=' + cast(@transid as varchar(20)) + ' ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
	END 

END
