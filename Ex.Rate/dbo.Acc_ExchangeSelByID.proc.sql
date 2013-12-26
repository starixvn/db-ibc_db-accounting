ALTER PROCEDURE [dbo].[Acc_ExchangeSelByID]
	@ExchangeID [int]
WITH EXECUTE AS CALLER
AS
/*
Created: 
Task : Select currency by Id
DB: DB052.bodb02/DBTXN.CustDB [DBTXN: used for Deposite]
Original:

Revisions:
	- 20100128@Khoa: select columns GPBRate, AUDRate, ZARRate, EURORATE, USDRATE
	- 20110605@Johnson: get description, multipliedBy, code 
Param's Explanation:
	• @ExchangeID: specIFy exchange-rate of the currency

*/

SET NOCOUNT ON
BEGIN
	SELECT exchangeid, currency, actualrate, creator, currency, minbet, minbetlive, GBPRate, AUDRate, ZARRate, EURORate, US$Rate , Description, MultipliedBy, Code
	FROM exchange WITH(NOLOCK)
	WHERE exchangeid = @ExchangeID
END

GO
GRANT  EXECUTE  ON [dbo].[Acc_ExchangeSelByID]  TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeSelByID] TO [bodbAdminNet] AS [dbo]
