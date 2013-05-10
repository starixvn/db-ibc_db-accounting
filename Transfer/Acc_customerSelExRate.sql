

ALTER PROCEDURE [dbo].[Acc_customerSelExRate]
(
	@Username NVARCHAR(50)
)
AS
/*
	Create: 20110902@Lukas
	Task: Get customer's currency info
	DB: DB053.BODB02

	Revisions:

*/
BEGIN
	SET NOCOUNT ON	
	
	SELECT c.custid, c.username, e.currency, e.actualrate
	FROM custinfo c WITH(NOLOCK)
			INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
	WHERE c.username = @Username

END


GO
GRANT  EXECUTE  ON [dbo].[Acc_customerSelExRate]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_customerSelExRate] TO [vnteam]