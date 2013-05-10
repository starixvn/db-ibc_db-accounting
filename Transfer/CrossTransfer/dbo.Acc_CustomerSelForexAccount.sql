

ALTER PROCEDURE Acc_CustomerSelForexAccount
AS
/*
	Create: 20110908@Lukas
	Task: Get forex account
	DB: DBTRANS.BODB02

	Revisions:
*/
BEGIN
	
	SELECT VValue 
	FROM SystemSettings WITH(NOLOCK)
	WHERE VName = 'ForexAccount'
END

GO
GRANT  EXECUTE  ON [dbo].[Acc_CustomerSelForexAccount]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelForexAccount] TO [vnteam]