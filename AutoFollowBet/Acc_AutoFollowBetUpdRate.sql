ALTER PROCEDURE [dbo].[Acc_AutoFollowBetUpdRate]	
	@UserName		VARCHAR(50),
	@Rate			SMALLMONEY,
	@FollowLive		INT,
	@Handicap		BIT,
	@1stHandicap	BIT,
	@OverUnder		BIT,
	@1stOverUnder	BIT,

	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTrans.bodb02
Revison:
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144] 
	
Param's Explanation:	
*/
SET NOCOUNT ON

DECLARE @custid int
SELECT @custid = custid
FROM Custinfo with(nolock)
WHERE username = @Username
	AND roleid = 1

IF @@rowcount = 0
BEGIN
	SELECT @ErrMsg = 'Invalid username', @ErrCode = 101			
	RETURN
END

UPDATE Cust_followBet WITH(UPDLOCK, ROWLOCK)
SET rate = @Rate,
	FollowLive = @FollowLive,
	Follow1 = @Handicap,
	Follow7 = @1stHandicap,
	Follow3 = @OverUnder,
	Follow8 = @1stOverUnder
WHERE custid = @custid



GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetUpdRate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetUpdRate] TO [VNTeam]
GO