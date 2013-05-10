ALTER PROCEDURE [dbo].[Acc_AutoFollowBetUpdRate]	
	@username varchar(30),
	@rate smallmoney,
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTrans.bodb02

	
Param's Explanation:	
*/
SET NOCOUNT ON

DECLARE @custid int
SELECT @custid = custid
FROM Custinfo with(nolock)
WHERE username = @username
	and roleid = 1

IF @@rowcount = 0
BEGIN
	SELECT @ErrMsg = 'Invalid username', @ErrCode = 101			
	RETURN
END

UPDATE Cust_followBet
SET rate = @rate
WHERE custid = @custid

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetUpdRate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetUpdRate] TO [VNTeam]
GO