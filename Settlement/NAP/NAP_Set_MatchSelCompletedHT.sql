ALTER PROCEDURE [NAP_Set_MatchSelCompletedHT]	
	@Date datetime,
	@SportType tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@isReLoad bit = 0
AS

/*
	Created by: Dan
	Date: 20120906
	Task: List HT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompletedHT
	
	Revisions:
		- 20131226@Kathy: Remove @param don't use (@MatchCode,@ToDate)
*/  
SET NOCOUNT ON  
IF @sporttype NOT IN(1,2,3,32)  
	RETURN

DECLARE @HTOverStartMins int,
		@HTOverEndMins int
		
SELECT @LeagueID = CASE WHEN @isReLoad = 1 THEN ISNULL(@LeagueID,0) ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues

SELECT @HTOverStartMins = CASE WHEN @sporttype = 1 THEN 45 ELSE 30 END ,
		@HTOverEndMins = CASE WHEN @sporttype = 1 THEN 100 ELSE 60 END

SELECT * 
FROM
(
	SELECT 
			m.matchid, m.leagueid ,
			HalfTimeHomeScore,
			HalfTimeAwayScore, 
			isnull(m.calculate,0) IsCalculated, isnull(m.multiple,0) IsMultiCaled,  
			isnull(m.refund,0) IsRefund, isnull(m.calrefund,0) IsCalRefund,  		
			m.homeid, m.awayid,  
			m.matchcode, m.kickofftime,  
			m.finalhomescore,  
			m.finalawayscore, m.betstatus,  
			case when m.betstatus like 'Refund FT%' then 'Refund FT'  
			when m.betstatus like 'Refund HT%' then 'Refund HT'  
			when m.betstatus like 'Refund%' then 'Refund'  
			else m.eventstatus  
			end as eventstatus,    
			Foddsstatus,  
			m.sporttype,  
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
			m.eventdate,  
			m.goalrecord, 
			case m.confirmHalfTime when 0 then '' else (select username from CustDB.dbo.custinfo (nolock) where custid = m.confirmHalfTime ) end suspenderHalfTime,     
			--case m.ConfirmFT when 0 then '' else (select username from custinfo (nolock) where custid = m.ConfirmFT ) end suspenderFT,     
			'' as suspenderFT,  
			ISNULL(m.IsHalfTimeCal,0) as IsHalfTimeCal,   		
			ISNULL(m.isPending, 0) as isPending,   
			ISNULL(m.isUndecided,0) as isUndecided,
			CAST(CASE WHEN HalfTimeHomeScore IS NOT NULL AND HalfTimeAwayScore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore ,
			c.betcount
	FROM		
		(
		select m.matchid, m.leagueid ,
			hthomescore as HalfTimeHomeScore,
			htawayscore as HalfTimeAwayScore, 
			mr.calculate, mr.multiple,  
			mr.refund, mr.calrefund,  		
			m.homeid, m.awayid,  
			m.matchcode, m.kickofftime,  
			m.finalhomescore,  
			m.finalawayscore, m.betstatus,  
			m.eventstatus,  		
			'' as Foddsstatus,  
			m.sporttype,  
			m.isNeutral,  
			m.eventdate,  
			m.goalrecord, 
			mr.confirmHT as confirmHalfTime,  		
			mr.confirmFT as confirmFullTime,  				
			mr.IsHTCal as IsHalfTimeCal,  		
			mr.isPending,  
			mr.isUndecided 
		FROM  DBPRO.BODB02.dbo.match m WITH (NOLOCK)   
		INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) on m.matchid = mr.matchid                    
		WHERE m.eventdate = @Date
			AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
			AND m.sporttype = @sporttype 		
			and m.eventstatus in ('Closed','running','internal')
			AND ((datediff(minute,m.kickofftime,CURRENT_TIMESTAMP) > @HTOverStartMins
				AND datediff(minute,m.kickofftime,CURRENT_TIMESTAMP) < @HTOverEndMins
				)  
				OR  mr.confirmHT <> 0) 		
			AND mr.ishtcal=0  
		) m
		INNER JOIN  
		(SELECT   bettrans.matchid,  
			 count(bettrans.matchid)  betcount  
		  FROM     bettrans WITH (NOLOCK) --(NOLOCK, index=CIX_matchid_bettype),  
			 JOIN DBPRO.BODB02.dbo.match WITH (NOLOCK)  ON match.matchid = bettrans.matchid  
		  WHERE  match.eventdate = @Date
				 and BETTYPE <= 19000  			 			 
				 and match.eventstatus in ('Closed','running','internal')
				 and match.sporttype = @sporttype  
		  GROUP BY bettrans.matchid  
			) c on m.matchid = c.matchid  
) X
ORDER BY  
	sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode	 	



GO

GRANT EXECUTE ON [NAP_Set_MatchSelCompletedHT] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSelCompletedHT] TO [vnteam] AS [dbo]
GO


