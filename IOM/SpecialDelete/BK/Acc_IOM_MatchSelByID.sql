ALTEr PROCEDURE [dbo].[Acc_IOM_MatchSelByID] 
	@matchID INT = 0,
	@transid bigint = 0,	
	@Language varchar(2) = 'E'
AS

/*
Created: Elodie
Date: 20120702
Task : View match info
DB: db053.bodb02
Original: Acc_MatchSelByID

Revisions: 
	
*/
SET NOCOUNT ON
declare @bettype int

if @matchid=0
	select @matchid = matchid, @bettype = bettype from bettrans (nolock) where transid = @transid
if @bettype = 10
	SELECT
        MATCH.teamid AS homeid,
        0 AS awayid,
        MATCH.matchcode,
        MATCH.eventdate,
        MATCH.leagueid,
        GETDATE() AS DATETIME,
        CONVERT(BIT,0) AS IsNeutral
    FROM
        Outright AS MATCH WITH (NOLOCK)
    WHERE 
        MATCH.orid = @matchID
else
	SELECT 
			match.homeid,
			match.awayid,
			match.matchcode, 
			match.eventdate, 
			match.leagueid,
			isnull(match.isNeutral, CONVERT(BIT,0)) as IsNeutral
		FROM 
			match WITH (NOLOCK) 
		WHERE  
			match.matchid = @matchID  

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_MatchSelByID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_MatchSelByID] TO [vnteam]
GO

 