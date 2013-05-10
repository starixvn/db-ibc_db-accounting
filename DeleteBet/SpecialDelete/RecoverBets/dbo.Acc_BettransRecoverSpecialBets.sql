ALTER PROCEDURE [dbo].[Acc_BettransRecoverSpecialBets]
    @transid BIGINT,
    @Type SMALLINT = 0,
    @userid int,   
    @IP varchar(50),
    @ErrCode int output,
    @ErrMsg nvarchar(200) output
AS
/*
Created: Robert
DB: DBTXN/bodb02
Revisions:   
	- 20110517@Lukas: Update HomeTotal, AwayTotal to Odds table
	- 20110709@Johnson: Change to use new server BD053 instead DB052
	- 20111028@Sophia: Update balance and check settle date
	- 20120412@Sophia: Revise update balance 
	- 20120830@Elodie: Recover bet of Virtual sports
	- 20120914@Sophia: . Check concurrent running
					   . Change datatype of @ErrMsg varchar(100) to nvarchar(200)
	- 20121115@Elodie: Move recover function of Number Game to new SP
	- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   
	- 20130128@Elodie: Change link server DB053 to DBAGE
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20130320@Johnson: Correct value bettrans.winlost= 0 when recover bets and check balance change to update balance table					   
						   
Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		1: Virtual sports
*/

SET NOCOUNT ON
BEGIN

	DECLARE @LogData NVARCHAR(500)
	DECLARE @Remark VARCHAR(500)
    SELECT @errcode = 0, @errmsg = ''

    declare
        @LogSPData varchar(200),
        @startRun datetime,
        @endRun datetime,
        @duration int,
        @matchid int,      
        @bettype int,
        @balance money,
		@custid int,
		@winlostdate datetime

    SELECT @matchid = matchid, @bettype = bettype , @winlostdate = winlostdate FROM bettrans (nolock) WHERE transid=@transid
      
   	--Check settled Date
	EXEC dbo.Acc_CheckSettledDate @winlostdate = @winlostdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN	
		
	----################ Check concurrent running #####################----
	DECLARE @KeyID TINYINT
		
	IF @bettype = 10	--Outright
		SET @KeyID = 2
	ELSE 
		SET @KeyID = 1

	---Check table TempVariableNumber 		
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = @KeyID AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (@KeyID, @matchid)
	IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverSpecialBets'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
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
					
	---- 20121115@Elodie: Move recover function of Number Game to new SP
	-----Also check table SystemSettings for Number game 
	--IF @bettype BETWEEN 81 AND 120
	--BEGIN
	--			IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
	--			BEGIN
	--				SELECT @ErrCode = 102
	--				SELECT @ErrMsg = 'Another number game re-calculation is in progress or some tickets of this match are being deleted, please wait a few seconds until the on-going process has finished and try again.'
					
	--				----release data of TempVariableNumber table
	--				DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	--				WHERE KeyID = @KeyID AND KeyValue = @matchid
					
	--				RETURN
	--			END
	--			ELSE 
	--			BEGIN
	--				UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
	--				SET		VValue = '1'
	--				WHERE	VName = 'isCalculatingNGManual'
	--			END
	--END 
	
	
	-------------------		
		
    IF @bettype = 10  --@bettype = 10
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
            isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
        FROM
            MATCH WITH (NOLOCK)
        WHERE
            MATCH.matchid = @matchID
    END

    exec DBAGE.bodb02.dbo.Acc_BettransSelRecoverSpecialBets @transid = @transid, @Type = @Type

----Get data before update	
	DECLARE @bf_balance MONEY,
			@at_balance MONEY
			
	SELECT	@custid = b.custid, @bf_balance = b.winlost - b.actual_stake + b.playercomm
	FROM	bettrans b WITH (NOLOCK)			
	WHERE   b.transid = @transid		
	
------ Recover 
    UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
    SET winlost = 0, ruben= 0, statuswinlost = NULL, STATUS ='running', statusID=0,
        creator = z.creator   
    FROM bettrans b 
    INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
    WHERE b.transid = @transid
    
    ----Get data after update
    SELECT	@at_balance = b.winlost - b.actual_stake + b.playercomm
	FROM	bettrans b WITH (NOLOCK)
	WHERE   b.transid = @transid	
		
	--update balance	
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
	

	IF @bettype IN (1,3,7,8)
	BEGIN
		-- update totalbets
		DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)

		INSERT INTO @Total
		SELECT
			oddsid,
			SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
			SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
		FROM bettrans b WITH (nolock)
			INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
		WHERE bettype = @bettype AND ruben = 0 AND oddsid <> 0 and matchid = @matchid
		GROUP BY oddsid

		UPDATE odds WITH (rowlock, updlock)
		SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
		FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @matchid
	END

    DELETE FROM zzzbettrans WITH(ROWLOCK,UPDLOCK) WHERE transid = @transid

    IF @@error <> 0
    begin
        SELECT @errcode = 100, @errmsg = 'Recover transaction ' + convert(varchar, @transid) + ' unsuccessful. Please try again.'
    end

    --print('write log')-- Write Log Here
	SELECT @LogData = 'Recover bet has transid: ' + cast(@transid as varchar(20))+ ' IP: ' + cast(@IP as varchar(15))
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	
	-----release data of TempVariableNumber table 
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = @KeyID AND KeyValue = @matchid
	IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverSpecialBets'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
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
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0,
				@Remark = 'DEL FAILED SPName=Acc_BettransRecoverSpecialBets'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0,
				@Remark = @Remark
		END CATCH
	END
	---- 20121115@Elodie: Move recover function of Number Game to new SP
	-------release data of systemSettings table 
	--IF @bettype BETWEEN 81 AND 120
	--BEGIN
	--	UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
	--	SET		VValue = '0'
	--	WHERE	VName = 'isCalculatingNGManual'
	--END			 
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransRecoverSpecialBets] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransRecoverSpecialBets] TO [vnteam]
