ALTER PROCEDURE [dbo].[Acc_BalanceNegativeSel_BySite]
  @Site		VARCHAR(50) = 'Haifa'
 ,@isTest	BIT			= 0

AS
/*
	Created by: Jamie
	Date: 2013-06-26
	Task: Retrieve Negative Balance by Site 
	DB: DBTXN/bodb02 
	
	Revision: 
		- 20131108@Elodie: Splitting bodb02 into CustDB (call custInfo, exchange by link database)
		- 20140312@Elodie: Group result by CustID, MatchId, GroupID, TotalBalance
	Param's Explanation: 
		@isTest: 0: Exclude currency UUS; 1: All Currency 
	
*/
BEGIN 
	SET NOCOUNT ON 
	SELECT	  MAX(h.LogID)
			, MAX(h.LogDate)
			, h.MatchID
			, CASE WHEN h.GroupID = 2 THEN 1 ELSE h.GroupID END AS GroupID
			, h.CustID
			, ci.Username
			, h.TotalBalance
			, CurrencyName = e.currency 
			, h.Site
			, bin.CustomInfo1
	FROM	BalanceNegativeHistory h WITH (NOLOCK)
			LEFT JOIN DBDEPBBIN.bbin.dbo.Customer bin WITH (NOLOCK) ON h.CustID = bin.IBCCustID
			LEFT JOIN CustDB.dbo.custInfo ci WITH (NOLOCK) ON h.CustID = ci.custid
			LEFT JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON ci.currency = e.exchangeid
	WHERE	h.StatusID = 0 
			AND e.exchangeid <> CASE @isTest WHEN 0 THEN 20 ELSE 0 END
	GROUP BY h.CustID, h.MatchID, 
			 CASE WHEN h.GroupID = 2 THEN 1 ELSE h.GroupID END,
			 ci.UserName, TotalBalance, e.currency, Site, bin.CustomInfo1
	ORDER BY	  MAX(h.LogID) ASC
				, h.MatchID ASC
				, ci.Username ASC
END 


GO
GRANT EXECUTE ON [dbo].[Acc_BalanceNegativeSel_BySite] TO [bodbAdminNet] AS [dbo]