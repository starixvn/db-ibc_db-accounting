CREATE PROCEDURE [dbo].[Acc_ExchangeSelCodeforCrossTransfer]
AS
/*
	Created: 20120611@Sophia
	Task : Get currency code and actualrate used for Cross transfer
	DB: DB053.BODB02
	Original: 

	Revisions:
	
	Param's Explanation:

*/
SET NOCOUNT ON

--- Hardcode: Show Code = 'INH' instead of 'VND' for exchangeid = 51 

SELECT  CASE WHEN Code = 'VND' THEN 'INH' ELSE Code END as Code, actualrate, currency, exchangeid
FROM	Exchange WITH (NOLOCK)
WHERE	exchangeid IN (	1, -- SGD
						2, -- MYR
						3, -- USD
						5, -- HKD
						6, -- EUR
						9, -- AUD
						12,-- GBP
						13,-- CNY
						41,-- CHF
						42,-- PHP
						51 -- INH
						)
ORDER BY Code


GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeSelCodeforCrossTransfer]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeSelCodeforCrossTransfer] TO [vnteam]
