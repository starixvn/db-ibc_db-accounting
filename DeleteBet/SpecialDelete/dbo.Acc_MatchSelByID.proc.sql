ALTER PROCEDURE [dbo].[Acc_MatchSelByID] 
	@matchID INT = 0,
	@transid bigint = 0,	
	@Language varchar(2) = 'E'
AS

/*
Created: Khoa
Date: 20100108
Task : View match info
DB: DBPRO/bodb02
Original:

Revisions: 
	- 20091218@PhuongNguyen	: Get IsNeuTral from Match
	- 20100108@Khoa			: Add more conodition - Can search by matchcode
	- 20120917@Lukas		: Get matchid
	- 20140715@Kathy		: Get showtime value
	- 20151110@Kathy:		: Move SP to DBPRO
*/
SET NOCOUNT ON
declare @bettype int

if @matchid=0
	select @matchid = matchid, @bettype = bettype 
	from DBTXN.bodb02.dbo.bettrans WITH(nolock) 
	where transid = @transid
if @bettype = 10
	SELECT
		match.orid as matchid,
        MATCH.teamid AS homeid,
        0 AS awayid,
        MATCH.matchcode,
        MATCH.eventdate,
        MATCH.leagueid,
        GETDATE() AS DATETIME,
        CONVERT(BIT,0) AS IsNeutral,
		convert(nvarchar(50),MATCH.kickofftime) as showtime
    FROM
        Outright AS MATCH WITH (NOLOCK)
    WHERE 
        MATCH.orid = @matchID
else
	SELECT 
			match.matchid,
			match.homeid,
			match.awayid,
			match.matchcode, 
			match.eventdate, 
			match.leagueid,
			isnull(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			showtime
		FROM 
			match WITH (NOLOCK) 
		WHERE  
			match.matchid = @matchID



GO
GRANT EXECUTE ON [dbo].[Acc_MatchSelByID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MatchSelByID] TO [vnteam] AS [dbo]