alter PROCEDURE [dbo].[Acc_BettransDelSpecial_LiveCS_Checking_xtest]
    @matchid		INT,    
    @f_transid		BIGINT,
    @t_transid		BIGINT,
    @transids		VARCHAR(4000)	= '',   
    @UserName		NVARCHAR(50),
    @UserPwd		NVARCHAR(50),
    @UserID			INT,
	@IP				VARCHAR(15)		= '',
    @ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT,
	@betcount		INT				= 0 OUTPUT
AS
/*
	Created by: 20120925@Lukas
	Task : Check concurrency & count ticket
	DB: DBTRANS.bodb02

	Revisions:
		
	Param's Explanation: Special bet delete option

*/
BEGIN
	SET NOCOUNT ON

	---- check and not allow attempt to delete same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END	
	
	CREATE TABLE #BetDelete (transid BIGINT, custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @Status TABLE (statusID TINYINT)
	
	/*
	INSERT INTO @Status
	SELECT 'Void' UNION ALL
	SELECT 'Reject' UNION ALL
	SELECT 'WON' UNION ALL
	SELECT 'LOSE' UNION ALL
	SELECT 'DRAW'
	*/
	INSERT INTO @Status
	SELECT 102 UNION ALL
	SELECT 101 UNION ALL
	SELECT 121 UNION ALL    ---- dummy ticket
	SELECT 112 UNION ALL
	SELECT 113 UNION ALL
	SELECT 111	
	
	
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)			
			SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
			FROM bettrans b WITH (nolock)
			WHERE
				b.matchid=@matchid 						
				AND
				b.transid BETWEEN @f_transid AND @t_transid						
				AND 
				b.bettype = 1101						


	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (0, 111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the refunded tickets.'
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END

	
	DELETE FROM #BetDelete
	WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))

	SELECT @betcount = COUNT(1)
	FROM #BetDelete

	DROP TABLE #BetDelete		

END

GO
GRANT EXECUTE ON [Acc_BettransDelSpecial_LiveCS_Checking_xtest] TO bodbAdminNet

