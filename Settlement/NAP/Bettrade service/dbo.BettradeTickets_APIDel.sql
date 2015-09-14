 ALTER PROCEDURE [dbo].[BettradeTickets_APIDel]
	@matchid INT,
	@logdate DATETIME
 AS
	/*
		Created: Johnson
		Date: 2015-09-14
		Task: remove list tickets of bettrade have been sent by API
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON 
	
	DELETE BettradeAPI WITH(UPDLOCK,ROWLOCK)
	WHERE matchid = @matchid
		AND logdate = @logdate
END
GO
GRANT EXECUTE ON [dbo].[BettradeTickets_APIDel] TO [bodbAdminNet]