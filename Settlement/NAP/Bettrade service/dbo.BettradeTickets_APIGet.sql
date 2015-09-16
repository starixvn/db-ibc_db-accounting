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
	DECLARE @session NVARCHAR(50), @matchid INT
	
	SELECT top (1) @session = session, @matchid = matchid
	FROM BettradeAPI WITH(NOLOCK)
	ORDER BY id ASC
	
	IF @@ROWCOUNT = 0 
		RETURN
		
	SELECT action, 		
		transid as TicketID,
		BuyBackNo,
		Payout	
	FROM BettradeAPI WITH(NOLOCK)	
	WHERE session = @session
		AND matchid = @matchid
	
	SELECT @session as session, @matchid as matchid, @@rowcount as numTicket
 END
 GO
 GRANT EXECUTE ON [dbo].[BettradeTickets_APIGet] TO [bodbAdminNet]
 
 