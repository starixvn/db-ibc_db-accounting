ALTER PROCEDURE [dbo].[Acc_IOM_BettransRecoverSpecialBets]
    @transid BIGINT,
    @userid int,   
    @IP varchar(50),
    @errcode int output,
    @errmsg varchar(100) output
AS
/*
Created: Elodie
Date: 20120705
DB: DBTRANS.bodb02
Origional: Acc_BettransRecoverSpecialBets

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

    exec db053.bodb02.dbo.Acc_BettransSelRecoverSpecialBets @transid = @transid
		
	--Get data before update	
	SELECT	@custid = b.custid, @balance = (b.winlost - z.winlost)
	FROM	bettrans b 
	INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
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
    FROM bettrans b INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
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
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransRecoverSpecialBets] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransRecoverSpecialBets] TO [vnteam] 