ALTER PROCEDURE [dbo].[NAP_Set_MatchSelCompleted]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@matchcode nvarchar(50) = '',
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
*/  
  
SET NOCOUNT ON  

DECLARE @matchid INT

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
  
Declare @m TABLE (
		matchid int primary key, 
		IsCalculated bit, 
		IsMultiCaled bit,  
		IsRefund bit, 
		IsCalRefund bit,  
		IsHTCal bit, 
		suspenderHT varchar(20), 
		suspenderFT varchar(20), 
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
	DB02.BODB02.dbo.match m with (nolock)  
	INNER JOIN DB02.BODB02.dbo.match_remark mr with (nolock) ON m.matchid = mr.matchid  
	LEFT OUTER JOIN dbo.custinfo ht with (nolock) ON mr.ConfirmHT = ht.custid  
	LEFT OUTER JOIN dbo.custinfo ft with (nolock) ON mr.ConfirmFT = ft.custid  
WHERE
	m.eventdate between @FromDate and @ToDate  
	AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
	AND m.sporttype = case when @sporttype = 0 then sporttype else @sporttype end 
	AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 
	AND m.eventstatus <> N'Completed'  
	AND (m.kickofftime < dateadd(s, -6000, CURRENT_TIMESTAMP) or mr.ConfirmFT > 0)  

SELECT *
FROM  
(	SELECT  
		m.matchid,  
		m.leagueid,  
		hthomescore,htawayscore, 
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
		suspenderHT,  
		suspenderFT,  
		ISNULL(tm.IsHTCal,0) as IsHTCal,  
		ISNULL(tm.calculate,0) as calculate,  
		ISNULL(tm.IsPending,0) as IsPending,
		ISNULL(tm.isUndecided,0) as isUndecided ,
		CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore  
	FROM  
		DB02.BODB02.dbo.match m with (nolock)  
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
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelCompleted] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelCompleted] TO [vnteam]