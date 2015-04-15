ALTER PROCEDURE [dbo].[U3_Result_SportSelByDate]  
 @EventDate DATETIME,
 @isshowall BIT = 0
AS  
/*  
Created: 20150305@Sophia
Task: U3 - Get Sport by Date for Result Page - Only show Number Game (Not show Live Casino by business and Bingo by structure)
DB: DBAGE/bodb02  
Original: Age_Result_SportSelByDate
Revision:   
 
*/  
  
SET NOCOUNT ON  
DECLARE @toDate  DATETIME
 
SELECT @toDate = DATEADD(s,-1, DATEADD(d, 1, @EventDate))  

SELECT  DISTINCT sports.sporttype, sportname   
FROM	dbo.sports WITH (nolock) 
		INNER JOIN (    SELECT matchid, eventdate, eventstatus, sporttype, leagueid
						FROM dbo.match WITH (NOLOCK)  
						UNION ALL  
						SELECT matchid, eventdate, eventstatus, sporttype, leagueid
						FROM dbo.match14 WITH (NOLOCK)  
					) match ON match.sporttype = sports.sporttype  
	
		LEFT JOIN dbo.match_remark mr WITH (NOLOCK) ON match.matchid = mr.matchid         
		INNER JOIN dbo.league l WITH (NOLOCK) on l.leagueid = match.leagueid
WHERE   
		match.eventdate >= @EventDate  
		AND match.eventdate <= @toDate  
		AND ( match.eventstatus NOT IN ('internal','closed','running')  
		OR ( mr.IsPending=1 AND match.eventstatus IN ('running','closed') )  
		OR ( mr.IsHTCal = 1 AND match.eventstatus ='running')  
		)  
		AND sports.sporttype = 161
		AND l.isTest= CASE WHEN @isshowall = 1 THEN l.isTest ELSE @isshowall END 
  

 
GO
GRANT EXECUTE ON [dbo].[U3_Result_SportSelByDate] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[U3_Result_SportSelByDate] TO [bodbDownlineNetView] AS [dbo] 
GO