/*<info serverAlias="DBAGE-bodb02" executers="wsv_nap" isNested="0" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_CurrencyList_Sel]
	@UserID INT,
	@IsTest BIT = 1
AS

/*
	Created: 20210301@Percy
	DB: DBAGE-bodb02
	Task: Get list credit's currency

	Revisions:
		- 20210301@Percy: Initialize SP [RedmineID: #146710]
		- 20240529@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	DECLARE @SearchCurrency VARCHAR(1024)

	DECLARE @tmpUserid VARCHAR(50)
	SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))

	--get deny currency
    SELECT @SearchCurrency = 'SELECT * 
	FROM OPENQUERY(DBPOL, 
	''SELECT exchangeID, Currency, OfferSite FROM NAP_UserControl.dbo.f_GetDeniedCurrencyByUser ( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
	EXECUTE(@SearchCurrency)

	SELECT ExchangeId, Currency
	FROM dbo.Exchange WITH (NOLOCK)
	WHERE (@IsTest = 1 OR ExchangeId NOT IN (20, 27, 28))
		AND (OfferSite IN (0, 1))
		AND IsActive = 1
		AND ExchangeId NOT IN (SELECT exchangeID FROM @tmpExchange)
	ORDER BY Currency
END
GO