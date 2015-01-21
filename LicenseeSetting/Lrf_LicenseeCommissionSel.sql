ALTER PROCEDURE [dbo].[Lrf_LicenseeCommissionSel] 
	@CustID INT
	,@Product INT
AS
/*
	Created: Elodie
	Date: 20150121
	Task : Licensee Setting Configuration - Get Commission [#6304]
	DB: DBAGE/bodb02
	Original:

	Revisions:

	Param's Explanation:
		@Product:	1: Sportbook
					161: Number Game
					180: Virtual sport
					162: Live Casino
					202: Keno
		
*/ 
BEGIN
	SET NOCOUNT ON
	SELECT	ISNULL(v151discount_31,0) as v151discount_31,
			ISNULL(@v151discount_41,0) as v151discount_41,
			ISNULL(@v151discount_51,0) as v151discount_51,
			ISNULL(@v152discount_41,0) as v152discount_41,
			ISNULL(@v152discount_51,0) as v152discount_51,
			ISNULL(@v153discount_51,0) as v153discount_51
	FROM CustSetting3rd cs WITH (NOLOCK) ON cs.custid = @CustID 
END
	
GO 
GRANT VIEW DEFINITION ON [dbo].[Lrf_LicenseeCommissionSel] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Lrf_LicenseeCommissionSel] TO [bodbAdminNet]
GO 

