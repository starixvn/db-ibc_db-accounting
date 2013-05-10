CREATE PROCEDURE [dbo].[NAP_Set_MatchSelHedge]      
	@matchid int    
AS

/* Created: 20120925@Dan
 Task: Select hedging matches correlative real matches    
 DB: DB02.bodb02    
 Original SP: [Acc_Set_MatchSelHedge]
     
 Revisions:    
     
 Param's Explanation:     
*/

SET NOCOUNT ON

Declare @leagueid int, @homeid int, @awayid int, @eventdate datetime     
SELECT @leagueid = leagueid
	 , @homeid = homeid
	 , @awayid = awayid
	 , @eventdate = eventdate
FROM
	match WITH (NOLOCK)
WHERE
	matchid = @matchid

SELECT matchid
	 , matchcode
FROM
	match WITH (NOLOCK)
WHERE
	leagueid = @leagueid
	AND homeid = @homeid
	AND awayid = @awayid
	AND eventdate = @eventdate
	AND matchid <> @matchid
	AND matchcode LIKE '%hedge%'
ORDER BY
	matchcode  

GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelHedge] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelHedge] TO [VNTeam]
GO 