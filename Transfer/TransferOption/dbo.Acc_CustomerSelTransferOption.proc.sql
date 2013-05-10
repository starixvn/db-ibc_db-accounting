ALTER PROCEDURE [dbo].[Acc_CustomerSelTransferOption]
	@CustId int,	
	@TransferOption varchar(8) OUTPUT
AS

/*
Created: 
Task : select transfer option.
DB: DB052.BODB02
Original: 

Revisions:
	- 20100413@Kiwi: Get transferoption from CustSuper/CustMaster/CustAgent
	
Param's Explanation:
*/

	DECLARE @RoleID TINYINT
	SELECT @RoleID = RoleID FROM custinfo WITH (NOLOCK) WHERE custid = @CustId

	IF (@RoleID = 4)
	BEGIN 
		SELECT @TransferOption = dbo.F_Decimal_Binary(ISNULL(TransferOption,0))
		FROM CustSuper  WITH (NOLOCK) 
		WHERE custid = @CustId
	END
	ELSE IF (@RoleID = 3)
	BEGIN 
		SELECT @TransferOption = dbo.F_Decimal_Binary(ISNULL(TransferOption,0))
		FROM CustMaster  WITH (NOLOCK) 
		WHERE custid = @CustId
	END
	ELSE IF (@RoleID = 2)
	BEGIN 
		SELECT @TransferOption = dbo.F_Decimal_Binary(ISNULL(TransferOption,0))
		FROM CustAgent  WITH (NOLOCK) 
		WHERE custid = @CustId
	END	

		
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelTransferOption] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelTransferOption] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelTransferOption] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelTransferOption] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelTransferOption] TO [vnteam]
	