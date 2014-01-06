ALTER PROCEDURE [dbo].[Acc_AutoFollowBetInsCustomer]	
	@Username varchar(30),
	@Rate smallmoney,
	@FollowLive		INT,
	@Handicap		BIT,
	@1stHandicap	BIT,
	@OverUnder		BIT,
	@1stOverUnder	BIT,

	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTrans.CustDB

Revision:
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144]
	
Param's Explanation:	
*/
SET NOCOUNT ON

DECLARE @custid INT

SELECT @custid = custid
FROM Custinfo with(nolock)
WHERE username = @Username
	AND roleid = 1

IF @@rowcount = 0
BEGIN
	SELECT @ErrMsg = 'Invalid username, please try again!', @ErrCode = 101			
	RETURN
END

IF EXISTS (SELECT TOP 1 1 FROM Cust_followBet WITH(NOLOCK) WHERE custid = @custid)
BEGIN
	SELECT @ErrMsg = 'Username existed, please try again!', @ErrCode = 102		
	RETURN
END

INSERT INTO Cust_followBet(custid, Rate, src, FollowLive, Follow1, Follow3, Follow7, Follow8)
VALUES (@custid, @Rate,0, @FollowLive, @Handicap, @OverUnder, @1stHandicap, @1stOverUnder)



GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [VNTeam]
GO