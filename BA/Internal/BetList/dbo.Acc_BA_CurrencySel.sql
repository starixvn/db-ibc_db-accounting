ALTER PROCEDURE  [dbo].[Acc_BA_CurrencySel]		
AS	
/*
Created: 20110808@Henry
Task : Get all the currency for BA betlist
DB: DB052.bodb02


Revisions:
    
Param's Explanation:
*/

SET NOCOUNT ON
BEGIN
	declare @temp as table (currency int)

	insert into @temp
	SELECT 
		distinct Currency 
	FROM bodb_Licensee.dbo.LicenseeCust lc (nolock)
	

	SELECT 
		t.currency, 
		e.currency as currencyname
	FROM 
		@temp t
	INNER JOIN exchange e with (nolock) ON t.currency = e.exchangeid

END


GO
GRANT EXECUTE ON [dbo].[Acc_BA_CurrencySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BA_CurrencySel] TO [vnteam]  