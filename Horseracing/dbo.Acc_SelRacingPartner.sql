CREATE PROCEDURE [dbo].[Acc_SelRacingPartner]
AS
/*	Created by: Jamie
	Date: 2010-03-31
	Task: Horse Racing Commission by Partner 
	DB: DB052.BODB02
	Original: [Acc_SelHRCommbyPartner]
	
	Revisions:
		- 20110311@Johnson: Get PartnerID and PartnerName from RacingPartner instead HorsePartner
							
*/
BEGIN
	SET NOCOUNT ON 
	SELECT	PartnerID,
			PartnerName			
	FROM	RacingPartner WITH (NOLOCK)
END
GO 
GRANT EXECUTE ON [dbo].[Acc_SelRacingPartner] TO [bodbAdminNet]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_SelRacingPartner] TO [VNTeam]