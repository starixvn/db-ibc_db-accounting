CREATE PROCEDURE [NAP_Set_MatchSelNumberGameDetail]
	@matchid int	
AS
/*
Created: 20121203@Dan
Task: Get detail info of a number game match
DB: DB053.bodb02  
Original: 
  
Revisions:   

Param explanation:  
	
*/  
  
SET NOCOUNT ON  

SELECT   	
	m.matchid,
	m.matchcode,  	 
	m.kickofftime,	
	b.seq,
	CAST(b.number AS VARCHAR(20)) AS number
FROM  
   (SELECT matchid, matchcode, kickofftime
	FROM MATCH (NOLOCK)  
    WHERE	matchid=@matchid
	UNION ALL  
	SELECT matchid, matchcode, kickofftime
	FROM match14 (NOLOCK)  
	WHERE matchid=@matchid
   )AS m 
	LEFT OUTER JOIN (SELECT matchid, seq, number FROM bingoball(NOLOCK)
				UNION ALL
				SELECT matchid, seq, number FROM bingoball14(NOLOCK)
				) AS B ON B.matchid = m.matchid
ORDER BY b.seq
  
  

GO

GRANT EXECUTE ON [NAP_Set_MatchSelNumberGameDetail] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSelNumberGameDetail] TO [vnteam] AS [dbo]
GO


