 ALTER PROCEDURE [dbo].[Acc_BettransRecoverSpecialBets_VirtualSports]
    @transid BIGINT,
    @userid int,   
    @IP varchar(50),
    @errcode int output,
    @errmsg varchar(100) output
AS
/*
Created: 20120815@Elodie
Task: Recover bets of Virtual Sports
Original: Acc_BettransRecoverSpecialBets
DB: DBTRANS.bodb02
Revisions:   
	
Param's Explanation:

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
   
   	--Check settled Date
	EXEC dbo.Acc_CheckSettledDate @winlostdate = @winlostdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN		
		   
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

    exec db053.bodb02.dbo.Acc_BettransSelRecoverSpecialBets @transid = @transid, @Type = 1
		
----Get data before update	
	SELECT	@custid = b.custid, @balance = (b.winlost - z.winlost)
	FROM	bettrans b 
	INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid = z.transid
	WHERE   b.transid = @transid
	
	--update balance debit
	IF @balance > 0
	BEGIN
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
	END
	
------ Recover 
    UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
    SET winlost = z.winlost, ruben= 0, statuswinlost = NULL, STATUS ='running', statusID=0,
        creator = z.creator   
    FROM bettrans b 
    INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
    WHERE b.transid = @transid
    
    --update balance credit	
	IF @balance < 0
	BEGIN
		SELECT @balance = ABS(@balance)
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END

    DELETE FROM zzzbettrans WITH(ROWLOCK,UPDLOCK) WHERE transid = @transid

    IF @@error <> 0
    begin
        SELECT @errcode = 100, @errmsg = 'Recover transaction ' + convert(varchar, @transid) + ' unsuccessful. Please try again.'
    end

    --print('write log')-- Write Log Here
	SELECT @LogData = 'Recover bet has transid: ' + cast(@transid as varchar(20))+ ' IP: ' + cast(@IP as varchar(15))
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransRecoverSpecialBets_VirtualSports] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransRecoverSpecialBets_VirtualSports] TO [vnteam]
GO
