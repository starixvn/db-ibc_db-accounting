/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_CustomerSelExRate
(
	@Username NVARCHAR(50)
)
AS
/*
	Create: 20110902@Lukas
	Task: Get customer's currency info
	DB: DBAGE.bodb02

	Revisions:
		- 20150724@Lukas: change to use customer (IX_username) instead of custinfo table
*/
BEGIN
	SET NOCOUNT ON	
	
	SELECT c.custid, c.username, e.currency, e.actualrate
	FROM customer c WITH(NOLOCK)
			INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
	WHERE c.username = CONVERT(VARCHAR(50),@Username)

END
GO