ALTER PROCEDURE [dbo].[NAP_Set_MatchSel]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@matchcode nvarchar(50) = '',
	@statusid tinyint = 0,
	@filterBy tinyint = 0,
	@isReLoad bit = 0
AS 
  
/*  
 Created by: Dan
 Date: 20120815
 Task: Match results for calculating settlement 
 DB: DB02.BODB02
 Original: Acc_Set_MatchSel
 Revisions:  
      
 Param explanation:  
	@matchcode: match code
	@LeagueID: = 0: show info of all leagues     
	@statusid: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 
	@filterBy: 0: none, 1: un-calculated game; 2: Un-calculated multiple only; 3: all
	@isReLoad: 1: reload partial matches of a league, 0: not reload
*/  
  
SET NOCOUNT ON  

DECLARE @UncalOnly BIT,	
	@UncalMultiOnly BIT,
	@eventstatus NVARCHAR(50),
	@isRefund BIT,
	@matchid INT

SELECT @matchcode = ISNULL(@matchcode,''), @LeagueID = ISNULL(@LeagueID,0),	@filterBy = ISNULL(@filterBy,0)
-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
IF (@matchcode <> '')
BEGIN
	SELECT @eventstatus= '', @isRefund=null, 
		@LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END, -- reload partial; search on LeagueID, not reload: get all leagues
		@UncalOnly = CASE WHEN @filterBy in (3,1) THEN 1 ELSE 0 END,				
		@UncalMultiOnly = CASE WHEN @filterBy in (3,2) THEN 1 ELSE 0 END			
	BEGIN TRY	
		SET @matchid = CASE WHEN ISNUMERIC(@matchcode) = 1 THEN CAST(@matchcode AS INT) ELSE NULL END
	END TRY
	BEGIN CATCH
		SET @matchid=NULL
	END CATCH
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
									ELSE 0	END,						
		@UncalOnly = CASE WHEN @filterBy in (3,1) THEN 1 ELSE 0 END,				
		@UncalMultiOnly = CASE WHEN @filterBy in (3,2) THEN 1 ELSE 0 END			
	
	--ignore event status if selecting filterby
	IF (@UncalMultiOnly=1 OR @UncalOnly=1)
		SELECT @eventstatus= '', @isRefund=NULL
	
END
SELECT *
FROM   
(
	SELECT m.matchid, m.leagueid ,
		hthomescore,htawayscore, 
		isnull(mr.calculate,0) IsCalculated, isnull(mr.multiple,0) IsMultiCaled,  
		isnull(mr.refund,0) IsRefund, isnull(mr.calrefund,0) IsCalRefund,  
		
		m.homeid, m.awayid,  
		m.matchcode, m.kickofftime,  
		m.finalhomescore,  
		m.finalawayscore, m.betstatus,  
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
		case mr.ConfirmHT when 0 then '' else (select username from custinfo (nolock) where custid = mr.ConfirmHT ) end suspenderHT,   
		case mr.ConfirmFT when 0 then '' else (select username from custinfo (nolock) where custid = mr.ConfirmFT ) end suspenderFT,  
		ISNULL(mr.IsHTCal,0) as IsHTCal,  		
		ISNULL(mr.isPending,0) as isPending,  
		ISNULL(mr.isUndecided,0) as isUndecided,  
		CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore  
	FROM match m WITH (NOLOCK)  
		LEFT OUTER JOIN match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid  
	WHERE m.eventdate between @FromDate and @ToDate  
		AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
		AND m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end  	  		
		AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 
		AND (@eventstatus='' or eventstatus in (@eventstatus,'internal')) 
		AND (@isRefund is null or 
				(@isRefund =1 and betstatus like 'Refund%') or
				(@isRefund =0 and ISNULL(betstatus,'') not like 'Refund%') 
			)	  
		AND (@UncalOnly = 0 or (isnull(mr.calculate,0) = 0 and m.eventstatus <> 'Completed'))  
		and (@UncalMultiOnly = 0 or isnull(mr.multiple,0) = 0)    
		and CASE WHEN @UncalMultiOnly = 0 THEN 1   
			 WHEN @UncalMultiOnly = 1 THEN hthomescore*htawayscore*finalhomescore*finalawayscore  
		 END IS NOT NULL  
) X 
ORDER BY  
	sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode

GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSel] TO [vnteam]