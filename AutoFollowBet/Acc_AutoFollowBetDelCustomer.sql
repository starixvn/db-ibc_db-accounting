ALTER PROCEDURE [dbo].[Acc_AutoFollowBetDelCustomer]	
	@username varchar(30),
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTrans.CustDB

	
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

DELETE Cust_followBet WHERE custid = @custid

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetDelCustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetDelCustomer] TO [VNTeam]
GO