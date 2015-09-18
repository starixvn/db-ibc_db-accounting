 ALTER PROCEDURE [dbo].[BettradeTickets_APIGet]
 
 AS
 /*
	Created: Johnson
	Date: 2015-09-10
	Task: get list tickets of bettrade and send by API
	DB: DBTXN/bodb02
	
	Revisions:
	
	Parameter's Explanation:
 */ 
 BEGIN
	SET NOCOUNT ON
	DECLARE @session NVARCHAR(50)
	
	SELECT top (1) @session = session
	FROM BettradeAPI WITH(NOLOCK)
	ORDER BY id ASC
	
	IF @@ROWCOUNT = 0 
		RETURN
		
	SELECT action, 		
		matchid,
		transid as TicketID,
		BuyBackNo,
		Payout,
		Remark as Reason	
	FROM BettradeAPI WITH(NOLOCK)	
	WHERE session = @session
		
	
	SELECT @session as session, @@rowcount as numTicket
 END
 GO
 GRANT EXECUTE ON [dbo].[BettradeTickets_APIGet] TO [bodbAdminNet]
 
 