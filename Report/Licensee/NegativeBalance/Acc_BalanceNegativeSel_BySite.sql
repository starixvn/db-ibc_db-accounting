ALTER PROCEDURE [dbo].[Acc_BalanceNegativeSel_BySite]
 @Site		VARCHAR(50) = 'Haifa'

AS
/*
	Created by: Jamie
	Date: 2013-06-26
	Task: Retrieve Negative Balance by Site 
	DB: DBTXN/bodb02 
	
	Revision: 
	
	
*/
BEGIN 
	SET NOCOUNT ON 
	SELECT	  h.LogID	
			, h.LogDate
			, h.MatchID
			, h.GroupID
			, h.CustID
			, ci.Username
			, h.TotalBalance
			, CurrencyName = e.currency 
			, h.Site
			, bin.CustomInfo1
	FROM	BalanceNegativeHistory h WITH (NOLOCK)
			LEFT JOIN DBDEPBBIN.bbin.dbo.Customer bin WITH (NOLOCK) ON h.CustID = bin.CustID
			LEFT JOIN custInfo ci WITH (NOLOCK) ON h.CustID = ci.custid
			LEFT JOIN exchange e WITH (NOLOCK) ON ci.currency = e.exchangeid
	WHERE	h.StatusID = 0 
	ORDER BY	  h.LogID ASC
				, h.MatchID ASC
				, ci.Username ASC
END 
GO 
GRANT EXECUTE ON [dbo].[Acc_BalanceNegativeSel_BySite] TO [bodbAdminNet]
GO 
 