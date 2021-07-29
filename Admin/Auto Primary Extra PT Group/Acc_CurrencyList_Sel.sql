/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" isNested="0" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_CurrencyList_Sel]
	@IsTest BIT = 1
AS

/*
	Created: 20210301@Percy
	DB: DBAGE-bodb02
	Task: Get list credit's currency

	Revisions:
		- 20210301@Percy: Initialize SP [RedmineID: #146710]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ExchangeId, Currency
	FROM dbo.Exchange WITH (NOLOCK)
	WHERE (@IsTest = 1 OR ExchangeId NOT IN (20, 27, 28))
		AND (OfferSite IN (0, 1))
		AND IsActive = 1
	ORDER BY Currency
END
GO