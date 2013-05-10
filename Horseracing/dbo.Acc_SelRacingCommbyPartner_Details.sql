ALTER PROCEDURE [dbo].[Acc_SelRacingCommbyPartner_Details]
@PartnerID	INT = 0 
AS
/*	Created by: Jamie
	Date: 2010-03-31
	Task: Horse Racing Commission by Partner 
	DB: DB052.BODB02
	Original: [Acc_SelHRCommbyPartner_Details]
	
	Revisions:
		- 20110311@Johnson: Get commision of all meetings under partner from RacingMeeting table
	
	Parameter's Explanation:
		- @PartnerID <> 0: PartnerID in RacingPartner
					 = 0: get all partner
*/
BEGIN
	SET NOCOUNT ON 
	
	SELECT	m.PartnerID,
			m.MeetingID, 	
			m.PoolCurrency,
			m.ToteCommWin,
			m.ToteCommPlace,
			m.ToteFee
	FROM	RacingMeeting m WITH (NOLOCK)			
	WHERE	PartnerID=@partnerID	
	ORDER BY m.partnerID, m.MeetingID, m.PoolCurrency
END
GO 
GRANT EXECUTE ON [dbo].[Acc_SelRacingCommbyPartner_Details] TO [bodbAdminNet]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_SelRacingCommbyPartner_Details] TO [VNTeam]