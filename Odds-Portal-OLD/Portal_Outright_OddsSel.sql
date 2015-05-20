ALTER PROC  [dbo].[Portal_Outright_OddsSel]
AS
/*    
Created:  Peter@20100128 
Task : Select all outright odds
DB: DB02.bodb02
Original: [Aff_AffiliateIns]  
Revisions:    

Param's Explanation:    
• @ErrCode:    
    = 0: Create agent successfully.    
    > 0: Specific Error.    
      
• @ErrMsg: Error description.    
*/   

SET NOCOUNT ON

SELECT o.orid, o.leagueid, t.teamid, o.odds, o.eventdate,
    l.leaguename, l.leaguenamec_uni, l.leaguenamecn,
    t.teamname, t.teamnamec_uni, t.teamnamecn, l.lcolor, l.leaguenametc sportname
FROM dbo.outright o WITH (nolock)
    INNER JOIN dbo.team t WITH (nolock) ON o.teamid = t.teamid
    INNER JOIN dbo.league l WITH (nolock) ON o.leagueid = l.leagueid
WHERE
    o.oddsstatus = 'running' AND o.kickofftime > CURRENT_TIMESTAMP
    and l.sporttype = 1
    AND  leaguename LIKE '%2010 FIFA World Cup%'
ORDER BY o.matchcode, o.eventdate, l.leaguename, o.odds

GO
GRANT EXECUTE ON [dbo].[Portal_Outright_OddsSel] TO [bodbadmin]
GO
GRANT EXECUTE ON [dbo].[Portal_Outright_OddsSel] TO [Portal]
GO
GRANT VIEW DEFINITION ON [dbo].[Portal_Outright_OddsSel] TO [vnteam]