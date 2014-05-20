ALTER PROCEDURE [dbo].[Acc_CustomerSelCheckSmartPunter]
	@custid INT,
	@isSmartPunter BIT = 0 OUTPUT
AS
	/*
		Created: Johnson
		Date: 2014-05-20
		DB: DBAGE/bodb02
		Task: Check customer is smart punter or not
	*/
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS (SELECT 1 FROM SmartPunterList WITH(NOLOCK) WHERE custid = @custid)
		SELECT @isSmartPunter = 1
	ELSE SELECT @isSmartPunter = 0
END 
GO

GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckSmartPunter] TO [bodbAdminNet]