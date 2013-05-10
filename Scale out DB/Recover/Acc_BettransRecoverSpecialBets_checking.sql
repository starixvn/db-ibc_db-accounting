alter PROCEDURE [dbo].[Acc_BettransRecoverSpecialBets_checking_xtest]
    @transid BIGINT,
    @errcode int output,
    @errmsg varchar(200) output,
    @betcount INT = 0 OUTPUT
AS
/*
	Created: 20120916@Lukas
	Task: 
	DB: DBTransPool, licensee TransDB
	
	Revisions:   		
		
	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @LogData NVARCHAR(500)
    SELECT @errcode = 0, @errmsg = ''

    DECLARE @matchid int
			,@bettype int

    SELECT	@matchid = matchid
			,@bettype = bettype
    FROM bettrans WITH(NOLOCK) 
    WHERE transid=@transid
      
     
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
	END
	
	---Also check table SystemSettings for Number game 
	IF @@SERVERNAME IN ('DBTRANS','DB206')
		IF @bettype BETWEEN 81 AND 120
		BEGIN
			IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
			BEGIN
				SELECT @ErrCode = 102
				SELECT @ErrMsg = 'Another number game re-calculation is in progress or some tickets of this match are being deleted, please wait a few seconds until the on-going process has finished and try again.'
				
				RETURN
			END		
		END 
		
	IF @matchid IS NOT NULL
		SET @betcount = 1
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransRecoverSpecialBets_checking_xtest] TO [bodbAdminNet]
