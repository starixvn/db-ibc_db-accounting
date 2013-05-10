ALTER PROCEDURE [dbo].[Acc_BettransRecoverSpecialBets_xtest]
    @transid BIGINT,
    @Type SMALLINT = 0,
    @userid int,   
    @IP varchar(50),
    @ErrCode int output,
    @ErrMsg nvarchar(200) output
AS
/*
Created: Robert
DB: DBTRANS.bodb02
Revisions:   
	- 20110517@Lukas: Update HomeTotal, AwayTotal to Odds table
	- 20110709@Johnson: Change to use new server BD053 instead DB052
	- 20111028@Sophia: Update balance and check settle date
	- 20120412@Sophia: Revise update balance 
	- 20120830@Elodie: Recover bet of Virtual sports
	- 20120914@Sophia: . Check concurrent running
					   . Change datatype of @ErrMsg varchar(100) to nvarchar(200)
	- 20120927@Lukas: put servername to control PS execution
	
Param's Explanation:
	- @Type: sports type
		0: Sportsbook or Number Game
		1: Virtual sports
*/

SET NOCOUNT ON
BEGIN

	DECLARE @LogData NVARCHAR(500)
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
      
  		
	----################ Check concurrent running #####################----
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
    BEGIN
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
	END
	
	---Also check table SystemSettings for Number game 
	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		IF @bettype BETWEEN 81 AND 120
		BEGIN
			IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
			BEGIN
				SELECT @ErrCode = 102
				SELECT @ErrMsg = 'Another number game re-calculation is in progress or some tickets of this match are being deleted, please wait a few seconds until the on-going process has finished and try again.'
				
				----release data of TempVariableNumber table
				DELETE FROM dbo.TempVariableNumber WITH(ROWLOCK,UPDLOCK)
				WHERE KeyID = @KeyID AND KeyValue = @matchid
				
				RETURN
			END
			ELSE 
			BEGIN
				UPDATE	systemSettings WITH(ROWLOCK, UPDLOCK)
				SET		VValue = '1'
				WHERE	VName = 'isCalculatingNGManual'
			END
		END 
	END	
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

	IF @@SERVERNAME IN ('DBTRANS','DB206')
		EXEC db053.bodb02.dbo.Acc_BettransSelRecoverSpecialBets @transid = @transid, @Type = @Type

----Get data before update	
	SELECT	@custid = b.custid, @balance = (b.winlost - z.winlost)
	FROM	bettrans b 
	INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
	WHERE   b.transid = @transid
	
	--update balance debit
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')  
	BEGIN  
		IF @balance > 0
		BEGIN
			EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
		END
	END
------ Recover 
    UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
    SET winlost = z.winlost, ruben= 0, statuswinlost = NULL, STATUS ='running', statusID=0,
        creator = z.creator   
    FROM bettrans b 
    INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
    WHERE b.transid = @transid
    
    --update balance credit	
    IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S') 
    BEGIN
		IF @balance < 0
		BEGIN
			SELECT @balance = ABS(@balance)
			EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
		END
	END


    DELETE FROM zzzbettrans WITH(ROWLOCK,UPDLOCK) WHERE transid = @transid
	
    IF @@error <> 0
    begin
        SELECT @errcode = 100, @errmsg = 'Recover transaction ' + convert(varchar, @transid) + ' unsuccessful. Please try again.'
    end

	SELECT transid,
		b.custid, mem.UserName        AS CustUserName,
		b.recommend, ag.UserName    AS AgUserName,
		b.mrecommend, mag.UserName AS MagUserName,
		b.srecommend, sag.Username AS SagUserName
	FROM bettrans b WITH(NOLOCK) 
		INNER JOIN custinfo mem WITH(NOLOCK) ON b.custid     = mem.custid
		INNER JOIN custinfo ag  WITH(NOLOCK) ON b.recommend  = ag.custid
		INNER JOIN custinfo mag WITH(NOLOCK) ON b.mrecommend = mag.custid
		INNER JOIN custinfo sag WITH(NOLOCK) ON b.srecommend = sag.custid
	WHERE b.transid = @transid
	
    --print('write log')-- Write Log Here
    IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		SELECT @LogData = 'Recover bet has transid: ' + cast(@transid as varchar(20))+ ' IP: ' + cast(@IP as varchar(15))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	END
	
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
    BEGIN
		-----release data of TempVariableNumber table 
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = @KeyID AND KeyValue = @matchid

		-----release data of systemSettings table 
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			IF @bettype BETWEEN 81 AND 120
			BEGIN
				UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
				SET		VValue = '0'
				WHERE	VName = 'isCalculatingNGManual'
			END		
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransRecoverSpecialBets_xtest] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransRecoverSpecialBets_xtest] TO [vnteam]
