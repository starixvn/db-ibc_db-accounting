ALTER  PROCEDURE [dbo].[Acc_BA_GroupCurrencySel]
	@LicenseeID INT
AS
/*
Created: 20111114@Jim
Task : Get list of currency for: Separate the BA Commission Setting by Currency
DB: DB052.bodb_Licensee
Revisions:
	
Param's Explanation:

*/
BEGIN  
	SELECT 
		lc.currency,
		CASE 
			WHEN e.exchangeid = 20 THEN 'UUS'
			WHEN e.exchangeid = 51 THEN e.currency
			ELSE e.Code END AS CurrencyName
	FROM bodb02.dbo.exchange e (NOLOCK)
	INNER JOIN 
	(
		SELECT DISTINCT Currency FROM LicenseeCust (nolock)  
		WHERE LicenseeID=@LicenseeID
	) lc ON lc.currency = e.exchangeid

	  
	SELECT  
		Currency,  
		ugroup
	FROM LicenseeCurrencyBAGroup WITH (nolock)  
	WHERE LicenseeID=@LicenseeID 
	ORDER BY ugroup
		
END  
GO
GRANT EXECUTE ON [dbo].[Acc_BA_GroupCurrencySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BA_GroupCurrencySel] TO [vnteam] 