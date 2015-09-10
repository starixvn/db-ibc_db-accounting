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
 AS
 BEGIN
	SET NOCOUNT ON
	DECLARE @logdate DATETIME
	
	SELECT top (1) @logdate = LogDate
	FROM BettradeAPI WITH(NOLOCK)
	ORDER BY logdate ASC
	
	DELETE BettradeAPI WITH(UPDLOCK,ROWLOCK)
	OUPUT DELETED.transid as TicketID, DELETED.BuyBackNo, DELETED.Payout
	WHERE logdate = @logdate
	
 END
 GO
 GRANT EXECUTE ON [dbo].[BettradeTickets_APIGet] TO [bodbAdminNet]
 
 