ALTER PROCEDURE [dbo].[DBA_BettransDelBet14]
	@transid bigint = 0,	
	@UserID int = 0, --custid of Admin
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: 
DB: DBTRANS.bodb02
Revisions:
	- 20100424@Henry: UPDATE statusID of bettrans14 (StatusID = 102 for status VOID)
	-- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20101007@Henry: Change column transid from INT to BIGINT
Param's Explanation:
*/

SET NOCOUNT ON

DECLARE @LogData NVARCHAR(200)

if not exists (select * from bettrans14 with (nolock) where transid = @transid and 
				--status in ('WON','LOSE','DRAW')
				statusID in (112,113,111)
			)
BEGIN
	Select @ErrMsg = 'Invalid bet transaction!!', @ErrCode = 103
	Return
END
IF EXISTS (SELECT transid FROM bettrans14 (nolock) WHERE transid = @transid)
	IF EXISTS (SELECT custid FROM customer (nolock) WHERE custid = @UserID)
	BEGIN
		INSERT INTO zzzbettrans
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
		FROM
			bettrans14 with (nolock)
		WHERE
			transid = @transid
	
		UPDATE bettrans14 with (rowlock)
		SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,statusID = 102
		WHERE transid = @transid

		
		SELECT @LogData = 'delete transaction from bettrans14 for transid:' + cast(@transid as varchar(20))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	END
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_BettransDelBet14] TO [vnteam]