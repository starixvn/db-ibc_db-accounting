

alter PROCEDURE [dbo].[Acc_BettransRecoverBet_LiveCS_xtest]
    @transid BIGINT,
    @userid int,   
    @IP varchar(50),
    @ErrCode int output,
    @ErrMsg nvarchar(200) output
AS
/*
	Created: 20120210@Lukas
	DB: DBTRANS.bodb02

	Revisions:   
		- 20120914@Sophia: . Add table TempVariableNumber to check and not to allow attempt to proceed on same game while it's still not finish
						   . Change datatype of @ErrMsg varchar(100) to nvarchar(200)
		- 20120927@Lukas: Put servername to control SP execution
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
        @bf_balance money,
        @at_balance money,
        @balance money,
		@custid int,
		@winlostdate datetime,
		@status NVARCHAR(10)

    SELECT @matchid = matchid, @bettype = bettype , @winlostdate = winlostdate FROM bettrans (nolock) WHERE transid=@transid
   
   
    ---- check and not allow attempt to delete same game while it's still not finish
    IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	
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

	IF @@SERVERNAME IN ('DBTRANS','DB206')	
		EXEC db053.bodb02.dbo.Acc_BettransSelRecoverBet_LiveCS @transid = @transid


	-- check if the ticket is not in zzzbettrans
	IF NOT EXISTS (	SELECT 1 
				FROM bettrans b WITH(NOLOCK)
						INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid    
				WHERE b.transid = @transid AND b.custid = z.custid AND b.matchid = z.matchid AND b.bettype = z.bettype ) 
	BEGIN	
		SELECT @status = status
		FROM bettrans WITH(NOLOCK)
		WHERE transid = @transid

		SELECT @errcode = 101, @errmsg = 'Status of this ticket is already ' + @status
		
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
	
		RETURN
	END

----Get data before update
	
	SELECT	@custid = b.custid, @bf_balance = SUM (b.winlost - b.actual_stake + b.playercomm)
	FROM	bettrans b WITH (NOLOCK)
	WHERE   b.transid = @transid
	GROUP BY b.custid
	

------ Recover 
    UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
    SET winlost = z.winlost, ruben= 1, statuswinlost = 0, status = z.status, statusID=103,
        creator = z.creator   
    FROM bettrans b INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
    WHERE b.transid = @transid

    
	

    DELETE FROM zzzbettrans WITH(ROWLOCK,UPDLOCK) WHERE transid = @transid

    IF @@error <> 0
    begin
        SELECT @errcode = 102, @errmsg = 'Recover transaction ' + convert(varchar, @transid) + ' unsuccessful. Please try again.'
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
		SELECT @LogData = 'Live Casino recover bet has transid: ' + cast(@transid as varchar(20))+ ' IP: ' + cast(@IP as varchar(15))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	END
	
	----
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid	
	
END


GO
GRANT EXECUTE ON [Acc_BettransRecoverBet_LiveCS_xtest] TO bodbAdminNet

