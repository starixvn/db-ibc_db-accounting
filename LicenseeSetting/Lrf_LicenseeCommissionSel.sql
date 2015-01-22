ALTER PROCEDURE [dbo].[Lrf_LicenseeCommissionSel] 
	@CustID INT
AS
/*
	Created: Elodie
	Date: 20150121
	Task : Licensee Setting Configuration - Get Commission of Horse Racing [#6304]
	DB: DBAGE/bodb02
	Original:

	Revisions:

	Param's Explanation:
		
*/ 
BEGIN
	SET NOCOUNT ON
	SELECT	sporttype, bettype, sdiscount
	FROM Dep_CustSetting3rd cs WITH (NOLOCK) 
	WHERE cs.custid = @CustID AND sporttype IN (151,152,153) AND bettype IN (31,41,51)
	ORDER BY sporttype, bettype
END
	
GO 
GRANT VIEW DEFINITION ON [dbo].[Lrf_LicenseeCommissionSel] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Lrf_LicenseeCommissionSel] TO [bodbAdminNet]
GO 

