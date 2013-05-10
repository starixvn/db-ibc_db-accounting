 
ALTER PROCEDURE [dbo].[Acc_BettransRecoverBet_LiveCS_Checking_xtest]
    @transid BIGINT,
    @userid int,   
    @IP varchar(50),
    @ErrCode int output,
    @ErrMsg nvarchar(200) output
AS
/*
	Created: 20120927@Lukas
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
        @matchid int,      
        @bettype int,      
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
	-------
    
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
		RETURN
	END
	
END


GO
GRANT EXECUTE ON [Acc_BettransRecoverBet_LiveCS_Checking_xtest] TO bodbAdminNet
