ALTER PROCEDURE dbo.Acc_P2PSelDefaultSetting
/*
	Created: TOM
	Date: 08152011
	DB: DB053.BODB02
	Task: get default setting of P2P 
	
	Revisions:
		- 20120618@Elodie:  Order by currency name
							Change server DB053 instead of DB052
*/
AS
SET NOCOUNT ON

SELECT dp.Currency CurrencyID
      ,e.Currency      
      ,dp.MinCredit
      ,dp.MaxCredit
      ,dp.Maxsdiscount
      ,dp.Maxadiscount
      ,dp.Maxdiscount
      ,dp.Maxplayerdiscount 
FROM P2PDefaultSetting dp WITH (NOLOCK)
	INNER JOIN exchange e WITH (NOLOCK)
		ON dp.currency = e.exchangeid
ORDER BY e.Currency

GO
GRANT EXECUTE ON [dbo].[Acc_P2PSelDefaultSetting] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_P2PSelDefaultSetting] TO [vnteam]


