ALTER PROCEDURE [dbo].[NAP_Set_MatchSelCompletedHT]	
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@matchcode nvarchar(50) = '',
	@isReLoad bit = 0
AS

/*
	Created by: Dan
	Date: 20120906
	Task: List HT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompletedHT
	
	Revisions:
		
*/  
SET NOCOUNT ON  
IF @sporttype NOT IN(1,2,3,32)  
	RETURN

DECLARE @HTOverStartMins int,
		@HTOverEndMins int,
		@matchid INT
		
SELECT @matchcode = ISNULL(@matchcode,''), @LeagueID = ISNULL(@LeagueID,0)
-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
IF (@matchcode <> '')
BEGIN
	SELECT @LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
	
	BEGIN TRY	
		SET @matchid = CASE WHEN ISNUMERIC(@matchcode) = 1 THEN CAST(@matchcode AS INT) ELSE NULL END
	END TRY
	BEGIN CATCH
		SET @matchid=NULL
	END CATCH					
END

SELECT @HTOverStartMins = CASE WHEN @sporttype = 1 THEN 45 ELSE 30 END ,
		@HTOverEndMins = CASE WHEN @sporttype = 1 THEN 100 ELSE 60 END

SELECT * 
FROM
(
	SELECT 
			m.matchid, m.leagueid ,
			hthomescore,htawayscore, 
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
			case m.ConfirmHT when 0 then '' else (select username from custinfo (nolock) where custid = m.ConfirmHT ) end suspenderHT,     
			--case m.ConfirmFT when 0 then '' else (select username from custinfo (nolock) where custid = m.ConfirmFT ) end suspenderFT,     
			'' as suspenderFT,  
			ISNULL(m.IsHTCal,0) as IsHTCal,   		
			ISNULL(m.isPending, 0) as isPending,   
			ISNULL(m.isUndecided,0) as isUndecided,
			CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore ,
			c.betcount
	FROM		
		(
		select m.matchid, m.leagueid ,
			hthomescore,htawayscore, 
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
			mr.confirmHT,  		
			mr.confirmFT,  				
			mr.IsHTCal,  		
			mr.isPending,  
			mr.isUndecided 
		FROM  DB02.BODB02.dbo.match m WITH (NOLOCK)   
		INNER JOIN DB02.BODB02.dbo.match_remark mr WITH (NOLOCK) on m.matchid = mr.matchid                    
		WHERE m.eventdate between @FromDate and @ToDate  
			AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
			AND m.sporttype = @sporttype 		
			AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 
			--AND m.eventstatus <> 'Completed'    
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
			 JOIN DB02.BODB02.dbo.match WITH (NOLOCK)  ON match.matchid = bettrans.matchid  
		  WHERE  match.eventdate between @FromDate and @ToDate  			
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
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelCompletedHT] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelCompletedHT] TO [vnteam]