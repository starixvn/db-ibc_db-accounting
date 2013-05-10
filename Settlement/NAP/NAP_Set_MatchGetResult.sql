ALTER PROCEDURE [dbo].[NAP_Set_MatchGetResult]
	@Date datetime,	
	@sporttype tinyint,
	@LeagueID int = 0, -- 0 for ALL Leagues	
	@statusid tinyint = 0
AS 
  
/*  
 Created by: Dan
 Date: 20121003
 Task: View Match results on Settlement 
 DB: DB02.BODB02
 Original: Acc_Set_MatchSel
 Revisions:  
      
 Param explanation:  
	@sporttype: show info of particular sport
	@LeagueID: = 0: show info of all leagues    	
	@statusid: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 
  
*/  
  
SET NOCOUNT ON  
DECLARE @eventstatus NVARCHAR(50),
		@isRefund BIT
	
IF (@sporttype IN (151,152,153))
BEGIN
	SELECT *
	FROM   
	(	SELECT 
			o.groupmatch, --Race   
			o.leagueid ,   
			IsFavor,  --TF  
			o.IsSCR,  --SCR  
			o.teamid, 
			o.matchcode,   --Horse   
			o.kickofftime,  
			o.odds,  
			o.placeodds,   
			case when o.placing = 0 then '5' else isnull(convert(varchar(2),placing) ,5) end placing, --Placing  
			o.oddsstatus as eventstatus,			
			l.sporttype,  
			CAST(0 AS BIT) IsNeutral,  
			o.eventdate  	  
		FROM	outright o WITH (nolock)  
				INNER JOIN league l WITH (nolock) ON  o.leagueid = l.leagueid   
		WHERE	o.eventdate = @Date
				AND l.sporttype = @sporttype 								
				AND o.leagueid = case when @leagueid =0 then o.leagueid  else @leagueid end
				AND (o.oddsstatus ='completed' or o.Foddsstatus='completed') 		
	) X 

	ORDER BY  
		sporttype, leagueid, 
		CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
		eventdate, kickofftime, groupmatch, placing, matchcode
END
ELSE
BEGIN 
	SELECT @eventstatus = CASE @statusid WHEN 1 THEN 'running'
									WHEN 2 THEN 'closed'
									WHEN 3 THEN 'completed'
									ELSE ''
						END,
			@isRefund = CASE @statusid WHEN 4 THEN 1 
									WHEN 0 THEN NULL
									ELSE 0	END
								
	SELECT *
	FROM   
	(
		SELECT m.matchid, m.leagueid ,
			hthomescore,htawayscore, 						
			m.homeid, m.awayid,  
			m.matchcode, m.kickofftime,  
			m.finalhomescore,  
			m.finalawayscore, m.betstatus,  
			case when m.betstatus like 'Refund FT%' then 'Refund FT'  
			when m.betstatus like 'Refund HT%' then 'Refund HT'  
			when m.betstatus like 'Refund%' then 'Refund'  
			else m.eventstatus  
			end as eventstatus,    			
			m.sporttype,  
			CAST(isnull(m.isNeutral,0) AS BIT) as IsNeutral,  
			m.eventdate,  
			m.goalrecord,
			m.showtime,
			ISNULL(mr.isPending,0) as isPending,
			ISNULL(mr.calculate,0) as calculate	,
			ISNULL(mr.IsHTCal,0) as IsHTCal
		FROM match m WITH (NOLOCK)  
			LEFT JOIN match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid  
		WHERE m.eventdate = @date
			AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
			AND m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end 	
			AND (@eventstatus='' or eventstatus in (@eventstatus,'internal')) 
			AND (@isRefund is null or 
					(@isRefund =1 and betstatus like 'Refund%') or
					(@isRefund =0 and ISNULL(betstatus,'') not like 'Refund%') 
				)	  	
	) X 

	ORDER BY  
		sporttype, leagueid, 
		CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
		eventdate, kickofftime, matchid, matchcode
END	

GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchGetResult] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchGetResult] TO [vnteam]