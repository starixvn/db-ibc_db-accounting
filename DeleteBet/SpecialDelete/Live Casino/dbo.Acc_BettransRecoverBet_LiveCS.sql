ALTER PROCEDURE [dbo].[Acc_BettransRecoverBet_LiveCS]
    @transid BIGINT,
    @userid int,   
    @IsNegativeBal bit output,
    @IP varchar(50),
    @ErrCode int output,
    @ErrMsg nvarchar(200) output
AS
/*
	Created: 20120210@Lukas
	DB: DBTXN/bodb02

	Revisions:   
		- 20120914@Sophia: . Add table TempVariableNumber to check and not to allow attempt to proceed on same game while it's still not finish
						   . Change datatype of @ErrMsg varchar(100) to nvarchar(200)
		- 20121115@Elodie:  Only recover today ticket
							Allow to recover settled ticket				  
		- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   							 
		- 20130128@Elodie: Change link server DB03 to DBPOLICY, DB053 to DBAGE
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20131108@Elodie: Splitting bodb02 into CustDB (Get credit in CustInfo from CustDB by link database)						   
		
	Param's Explanation:
*/

SET NOCOUNT ON
BEGIN
	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid, @funcname='[SpecialDeleteLivecasino]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end
	
	DECLARE @LogData NVARCHAR(500)
	DECLARE @Remark VARCHAR(500)
    SELECT @errcode = 0, @errmsg = ''

    declare      
		@custid int,
        @matchid int,      
        @bettype int,        		
		@winlostdate datetime,
		@status NVARCHAR(10),
		
		@bf_balance money,
        @at_balance money,       
        @balance money,
        @TotalBalance money      
	
	DECLARE @today SMALLDATETIME
	SET @today = convert(nvarchar(10), current_timestamp, 120)
	
    SELECT @custid = custid, @matchid = matchid, @bettype = bettype , @winlostdate = winlostdate, @status = status 
    FROM bettrans (nolock) WHERE transid = @transid
	IF(@winlostdate <> @today)
	BEGIN
		SELECT  @ErrCode = 103,
				@ErrMsg = 'You are only allowed to recover today tickets.'
		RETURN
	END
   
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
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @userid, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverBet_LiveCS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverBet_LiveCS ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @userid, 
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
	-------    
    SELECT
		homeid,
		awayid,
		matchcode,
		eventdate,
		leagueid,
		betstatus,
		eventstatus,
		GETDATE() AS [DATETIME],
		0 IsNeutral,
		showtime AS GameEvent
	FROM
		match WITH (NOLOCK)
	WHERE 
		matchid = @matchID

    EXEC DBAGE.bodb02.dbo.Acc_BettransSelRecoverBet_LiveCS @transid = @transid

--	-- check if the game was settled
--	IF NOT EXISTS (SELECT 1 FROM match WIHT(NOLOCK) WHERE matchid = @matchid AND eventstatus = 'running')
--	BEGIN
--		SELECT @errcode = 100, @errmsg = 'only uncompleted game can be recoverbet.'
--		RETURN
--	END
	-- check if the ticket is not in zzzbettrans
	IF NOT EXISTS (	SELECT 1 
				FROM bettrans b WITH(NOLOCK)
						INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid = z.transid    
				WHERE b.transid = @transid AND b.custid = z.custid AND b.matchid = z.matchid AND b.bettype = z.bettype ) 
	BEGIN			
		SELECT @errcode = 101, @errmsg = 'Status of this ticket is already ' + @status		
		----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_LiveCS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_LiveCS ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0,  
					@Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_LiveCS'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_LiveCS ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0,  
					@Remark = @Remark
			END CATCH					
		END
		RETURN
	END
		
--Check this customer who have negative balance
----Calculate a balance of customer
	SELECT	@TotalBalance = SUM (b.winlost - b.actual_stake + b.playercomm)
	FROM	bettrans b WITH (NOLOCK)
	WHERE   b.custid = @custid		
	
	select @IsNegativeBal = CASE WHEN c.credit + @TotalBalance - b.actual_stake < 0 then 1 ELSE 0 end
	FROM	bettrans b WITH (NOLOCK)
			inner join CustDB.dbo.custInfo c WITH (NOLOCK) ON b.custid = c.custid	
	WHERE	b.transid = @transid
	
----Get data before update	
	SELECT	@bf_balance = b.winlost - b.actual_stake + b.playercomm
	FROM	bettrans b WITH (NOLOCK)
	WHERE   b.transid = @transid	

------ Recover 
    UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
    SET winlost = 0, 
		ruben = 0, 
		statuswinlost = 0, 
		status = 'running', 
		statusID = 0,						
        creator = z.creator   
    FROM bettrans b INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
    WHERE b.transid = @transid and b.winlostdate = @today
        
----Get data after update
    SELECT	@at_balance = b.winlost - b.actual_stake + b.playercomm
	FROM	bettrans b WITH (NOLOCK)
	WHERE   b.transid = @transid
	
---update balance	
	SELECT @balance = (@at_balance - @bf_balance )
	IF @balance > 0
	BEGIN
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END
	IF @balance < 0
	BEGIN
		SELECT @balance = ABS(@balance)
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
	END

    DELETE FROM zzzbettrans WITH(ROWLOCK,UPDLOCK) WHERE transid = @transid

    IF @@error <> 0
    begin
        SELECT @errcode = 102, @errmsg = 'Recover transaction ' + convert(varchar, @transid) + ' unsuccessful. Please try again.'
    end

    --print('write log')-- Write Log Here
	SELECT @LogData = 'Live Casino recover bet has transid: ' + cast(@transid as varchar(20))+ ' IP: ' + cast(@IP as varchar(15))
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	
	----
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid	
	IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_LiveCS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_LiveCS ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0,  
					@Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_LiveCS'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_LiveCS ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0,  
					@Remark = @Remark
			END CATCH					
		END
END


GO
GRANT EXECUTE ON [dbo].[Acc_BettransRecoverBet_LiveCS] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransRecoverBet_LiveCS] TO [vnteam] AS [dbo]