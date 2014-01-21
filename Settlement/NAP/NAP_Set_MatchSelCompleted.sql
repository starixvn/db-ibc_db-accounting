ALTER PROCEDURE [NAP_Set_MatchSelCompleted]
	@Date datetime,
	@SportType tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@isReLoad bit = 0
AS

/*
	Created by: Dan
	Date: 20120905
	Task: List FT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompleted

	Revisions:
		@isReLoad: 1: reload partial matches of a league, 0: not reload
		- 20131226@Kathy: Remove @param don't use (@MatchCode,@ToDate)
*/  
  
SET NOCOUNT ON  

SELECT @LeagueID = CASE WHEN @isReLoad = 1 THEN ISNULL(@LeagueID,0) ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
  
Declare @m TABLE (
		matchid int primary key, 
		IsCalculated bit, 
		IsMultiCaled bit,  
		IsRefund bit, 
		IsCalRefund bit,  
		IsHalfTimeCal bit, 
		suspenderHalfTime varchar(20), 
		suspenderFullTime varchar(20), 
		calculate bit, 
		isPending bit, 
		isUndecided bit)  
INSERT INTO @m  
SELECT  
		m.matchid, 
		isnull(mr.calculate,0) IsCalculated, 
		isnull(mr.multiple,0) IsMultiCaled,  
		isnull(mr.refund,0) IsRefund, 
		isnull(mr.calrefund,0) IsCalRefund,  
		mr.IsHTCal, IsNull(ht.username, ''), 
		IsNull(ft.username, ''),   
		mr.calculate, 
		ISNULL(mr.isPending,0) as isPending,
		ISNULL(mr.isUndecided,0) as isUndecided 
FROM  
	DBPRO.BODB02.dbo.match m with (nolock)  
	INNER JOIN DBPRO.BODB02.dbo.match_remark mr with (nolock) ON m.matchid = mr.matchid  
	LEFT OUTER JOIN CustDB.dbo.custinfo ht with (nolock) ON mr.ConfirmHT = ht.custid  
	LEFT OUTER JOIN CustDB.dbo.custinfo ft with (nolock) ON mr.ConfirmFT = ft.custid  
WHERE
	m.eventdate = @Date  
	AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
	AND m.sporttype = case when @sporttype = 0 then sporttype else @sporttype end 
	AND m.eventstatus <> N'Completed'  
	AND (m.kickofftime < dateadd(s, -6000, CURRENT_TIMESTAMP) or mr.ConfirmFT > 0)  

SELECT *
FROM  
(	SELECT  
		m.matchid,  
		m.leagueid,  
		hthomescore HalfTimeHomeScore,
		htawayscore HalfTimeAwayScore, 
		IsCalculated, IsMultiCaled,  
		IsRefund, IsCalRefund,  
		m.homeid,  
		m.awayid,  
		m.matchcode,  
		m.kickofftime,  
		m.finalhomescore,  
		m.finalawayscore,  
		m.betstatus,  
		case when m.betstatus like 'Refund FT%' then 'Refund FT'  
		when m.betstatus like 'Refund HT%' then 'Refund HT'  
		when m.betstatus like 'Refund%' then 'Refund'  
		else m.eventstatus  
		end as eventstatus,  		
		'' as Foddsstatus,  
		m.sporttype,  	
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
		m.eventdate,  
		m.goalrecord, 	
		C.betcount,  	
		suspenderHalfTime,  
		suspenderFullTime,  
		ISNULL(tm.IsHalfTimeCal,0) as IsHalfTimeCal,  
		ISNULL(tm.calculate,0) as calculate,  
		ISNULL(tm.IsPending,0) as IsPending,
		ISNULL(tm.isUndecided,0) as isUndecided ,
		CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore  
	FROM  
		DBPRO.BODB02.dbo.match m with (nolock)  
		INNER JOIN @m tm ON m.matchid = tm.matchid  
		INNER JOIN  
		(  
		SELECT b.matchid, count(b.matchid) AS BetCount  
		FROM dbo.bettrans b with (nolock)  
		INNER JOIN @m stm ON b.matchid = stm.matchid  
		GROUP BY b.matchid  
		) as C ON m.matchid = c.matchid  
) X 
ORDER BY  
	sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode	 


GO

GRANT EXECUTE ON [NAP_Set_MatchSelCompleted] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSelCompleted] TO [vnteam] AS [dbo]
GO


