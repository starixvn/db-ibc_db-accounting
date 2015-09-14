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
	DECLARE @logdate DATETIME, @matchid INT
	
	SELECT top (1) @logdate = LogDate, @matchid = matchid
	FROM BettradeAPI WITH(NOLOCK)
	ORDER BY logdate ASC
	
	SELECT action, 
		transid as TicketID,
		BuyBackNo,
		Payout	
	FROM BettradeAPI WITH(NOLOCK)	
	WHERE logdate = @logdate
		AND matchid = @matchid
	
 END
 GO
 GRANT EXECUTE ON [dbo].[BettradeTickets_APIGet] TO [bodbAdminNet]
 
 