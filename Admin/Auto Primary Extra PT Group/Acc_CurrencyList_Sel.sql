/*<info serverAlias="DBAGE-bodb02" executers="wsv_nap" isNested="0" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_CurrencyList_Sel]
	@IsTest BIT = 1,
	@DeniedList NVARCHAR(MAX) = NULL
AS

/*
	Created: 20210301@Percy
	DB: DBAGE-bodb02
	Task: Get list credit's currency

	Revisions:
		- 20210301@Percy: Initialize SP [RedmineID: #146710]
		- 20240529@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240729@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	SELECT ExchangeId, Currency
	FROM dbo.Exchange WITH (NOLOCK)
	WHERE (@IsTest = 1 OR ExchangeId NOT IN (20, 27, 28))
		AND (OfferSite IN (0, 1))
		AND IsActive = 1
		AND ExchangeId NOT IN (SELECT exchangeID FROM @tmpExchange)
	ORDER BY Currency
END
GO