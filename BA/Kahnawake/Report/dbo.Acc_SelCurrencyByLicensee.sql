ALTER PROCEDURE  [dbo].[Acc_SelCurrencyByLicensee]		
	@LicenseeID int = 0
AS	
/*
Created: 20120220@Henry
Task : Get all the currency by a licensee
DB: bodb_MoveBet


Revisions:
  
Param's Explanation:
*/

SET NOCOUNT ON
BEGIN
	declare @temp as table (currency int)

	insert into @temp
		SELECT 
			distinct Currency 
		FROM LicenseeCust lc (nolock)
		WHERE 
			@LicenseeID = 0 OR LicenseeID = @LicenseeID

	
	SELECT 
		t.currency, 
		CASE 
			WHEN t.currency = 20 THEN 'UUS' 
			WHEN t.currency = 51 THEN 'INH'
			ELSE e.Code 
		END AS CurrencyName
	FROM 
		@temp t
	INNER JOIN exchange e with (nolock) ON t.currency = e.exchangeid
	ORDER BY 
		CASE 
			WHEN t.currency = 20 THEN 'UUS' 
			WHEN t.currency = 51 THEN 'INH'
			ELSE e.Code 
		END

END

GO
GRANT EXECUTE ON [dbo].[Acc_SelCurrencyByLicensee] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SelCurrencyByLicensee] TO [vnteam]  