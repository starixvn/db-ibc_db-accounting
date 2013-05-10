ALTER PROCEDURE [dbo].[Acc_AutoFollowBetInsCustomer]	
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

if exists (select top 1 1 from Cust_followBet where custid = @custid)
BEGIN
	SELECT @ErrMsg = 'customer is existed', @ErrCode = 102		
	RETURN
END

INSERT INTO Cust_followBet(custid, rate)
VALUES (@custid, @rate)

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [VNTeam]
GO