ALTER PROCEDURE [dbo].[NAP_Set_MatchSel] @FromDate DATETIME
	,@ToDate DATETIME
	,@SportType SMALLINT = 0
	,@LeagueID INT = 0 -- 0 for ALL Leagues
	,@MatchCode NVARCHAR(50) = ''
	,@StatusId TINYINT = 0
	,@FilterBy TINYINT = 0
	,@AutoSettlementOnly BIT = 0 
	,@IsReLoad BIT = 0
AS
/*  
 Created by: Kathy
 Date: 20131223
 Task: Match results for calculating settlement 
 DB: DBTXN/BODB02
 Original: Acc_Set_MatchSel
 Revisions:  
		- 20140417@Kathy: re-arrange order list (follow by old system)
		- 20140421@Kathy: get match status in queue
		- 20140428@Kathy: get 1H FGLG ticket info [Redmine:#14449]
		- 20140714@Kathy: filter by running penalty shootout only [Redmine:#17142]
		- 20141006@Jamie: Get ResultDetail for Tennis [Redmine:#23034]
		- 20150130@Jamie: Betradar phase II [Readmine:#27212]
		- 20150618@Jamie: Offer the option Exclude Corner tickets [Feature #38099]
		- 20151207@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160805@Kathy: Write log duration
		- 20160830@Kathy: PH-AIO phase 2b [Redmine:#62861]
		- 20161118@Kathy: Changes on Auto Settlement - Move sp to DBTXN [Redmine:#67328]
      
 Param explanation:  
	@MatchCode: match code
	@LeagueID: = 0: show info of all leagues     
	@StatusId: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 5: Completed (Running Corner)
	@FilterBy: 0: none, 1: un-calculated game; 2: Un-calculated multiple only; 3: all
	@PenaltyShootoutOnly: 0: none; 1: running penalty shootout only
	@IsReLoad: 1: reload partial matches of a league, 0: not reload
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @UncalOnly BIT
		,@UncalMultiOnly BIT
		,@eventstatus NVARCHAR(50)
		,@isRefund BIT
		,@matchid INT
		,@StartTime DATETIME
		,@EndTime	DATETIME
		,@SqlCommand VARCHAR(MAX)
	
	SET @StartTime = GETDATE()
	
	SELECT @matchcode = ISNULL(@matchcode, '')
		,@LeagueID = ISNULL(@LeagueID, 0)
		,@filterBy = ISNULL(@filterBy, 0)

	-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
	IF (@matchcode <> '')
	BEGIN
		SELECT @eventstatus = ''
			,@isRefund = NULL
			,@LeagueID = CASE 
				WHEN @isReLoad = 1 THEN @LeagueID
				ELSE 0
				END
			,-- reload partial; search on LeagueID, not reload: get all leagues	
			@UncalOnly = NULL
			,@UncalMultiOnly = NULL

		BEGIN TRY
			SET @matchid = CASE 
					WHEN ISNUMERIC(@matchcode) = 1 THEN CAST(@matchcode AS INT)
					ELSE NULL
					END
		END TRY

		BEGIN CATCH
			SET @matchid = NULL
		END CATCH
	END
	ELSE
	BEGIN
		SELECT @eventstatus = CASE @statusid
				WHEN 1 THEN 'running'
				WHEN 2 THEN 'closed'
				WHEN 3 THEN 'completed'
				WHEN 5 THEN 'running'
				ELSE ''
				END
			,@isRefund = CASE @statusid
				WHEN 4 THEN 1
				WHEN 0 THEN NULL
				ELSE 0
				END
			,@UncalOnly = CASE 
				WHEN @filterBy IN (3, 1) THEN 1
				ELSE 0
				END
			,@UncalMultiOnly = CASE 
				WHEN @filterBy IN (3, 2) THEN 1
				ELSE 0
				END

		--ignore event status if selecting filterby
		IF (@UncalMultiOnly = 1 OR @UncalOnly = 1 OR @AutoSettlementOnly = 1)
			SELECT @eventstatus = ''
				,@isRefund = NULL
	END

	CREATE TABLE #matchList (
		HalfTimeHomeScore INT
		,HalfTimeAwayScore INT
		,IsCalculated BIT
		,IsMultiCaled BIT
		,IsRefund BIT
		,IsCalRefund BIT
		,matchid INT
		,leagueid INT
		,homeid INT
		,awayid INT
		,matchcode NVARCHAR(50)
		,kickofftime DATETIME
		,finalhomescore INT
		,finalawayscore INT
		,betstatus NVARCHAR(50)
		,eventstatus NVARCHAR(50)
		,SettlementStatus135 tinyint
		,Foddsstatus VARCHAR(10)
		,sporttype SMALLINT
		,IsNeutral BIT
		,eventdate DATETIME
		,goalrecord VARCHAR(50)
		,suspenderHalfTime NVARCHAR(50)
		,suspenderFullTime NVARCHAR(50)
		,IsHalfTimeCal BIT
		,calculate BIT
		,isPending BIT
		,isUndecided BIT
		,IsKeyscore BIT
		,IsExistFGLG BIT
		,IsExistHTFGLG BIT
		,WinOdds MONEY
		,PlaceOdds MONEY
		)

	DECLARE @strmatchid VARCHAR(MAX)
		,@betstatus VARCHAR(8000)
		,@intDocHandle INT
		,@rowcount INT
		,@max_matchid INT
	DECLARE @tmp_match TABLE (matchid INT)

	INSERT INTO #matchList
	SELECT 
		tmp.hthomescore
		,tmp.htawayscore
		,ISNULL(mr.calculate, 0) IsCalculated
		,ISNULL(mr.multiple, 0) IsMultiCaled
		,ISNULL(mr.refund, 0) IsRefund
		,ISNULL(mr.calrefund, 0) IsCalRefund
		,tmp.matchid
		,tmp.leagueid
		,tmp.homeid
		,tmp.awayid
		,tmp.matchcode
		,tmp.kickofftime
		,tmp.finalhomescore
		,tmp.finalawayscore
		,tmp.betstatus
		,tmp.eventstatus
		,ISNULL(mr.SettlementStatus135,0) as SettlementStatus135
		,tmp.Foddsstatus
		,tmp.sporttype
		,tmp.IsNeutral
		,tmp.eventdate
		,tmp.goalrecord
		,CASE mr.ConfirmHT
		WHEN 0 THEN ''
		ELSE (
				SELECT username
				FROM dbo.custinfo WITH (NOLOCK)
				WHERE custid = mr.ConfirmHT
				)
		END suspenderHT
		,CASE mr.ConfirmFT
			WHEN 0 THEN ''
			ELSE (
					SELECT username
					FROM dbo.custinfo WITH (NOLOCK)
					WHERE custid = mr.ConfirmFT
					)
		END suspenderFT
		,ISNULL(mr.IsHTCal, 0) AS IsHTCal
		,ISNULL(mr.calculate, 0) AS calculate
		,ISNULL(mr.isPending, 0) AS isPending
		,ISNULL(mr.isUndecided, 0) AS isUndecided
		,tmp.IsKeyscore
		,tmp.IsExistFGLG
		,tmp.IsExistHTFGLG
		,tmp.WinOdds
		,tmp.PlaceOdds
	FROM (
		SELECT hthomescore
			,htawayscore			
			,m.matchid
			,m.leagueid
			,m.homeid
			,m.awayid
			,m.matchcode
			,m.kickofftime
			,m.finalhomescore
			,m.finalawayscore
			,m.betstatus
			,CASE 
				WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'
				WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'
				WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'
				ELSE m.eventstatus
				END AS eventstatus
			,'' AS Foddsstatus
			,m.sporttype
			,ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,m.eventdate
			,m.goalrecord						
			,CASE 
				WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1
				ELSE 0
				END IsKeyscore
			,0 as IsExistFGLG
			,0 as IsExistHTFGLG
			,0 as WinOdds
			,0 as PlaceOdds
		FROM	dbo.match m WITH (NOLOCK)
				LEFT JOIN dbo.ResultDetail r WITH (NOLOCK) ON m.matchID = r.MatchId AND r.ResourceId ='00'
		WHERE m.eventdate BETWEEN @FromDate AND @ToDate 
			AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END 			
			AND CASE WHEN @UncalMultiOnly = 0 THEN 1 
					 WHEN @UncalMultiOnly = 1 THEN hthomescore * htawayscore * finalhomescore * finalawayscore
					 WHEN @UncalMultiOnly IS NULL OR @UncalOnly IS NULL THEN 1
				END IS NOT NULL AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END 
			AND (@matchcode = '' OR (m.matchid = @matchid OR m.matchcode = @matchcode)) 
			AND (@eventstatus = '' OR eventstatus IN (@eventstatus, 'internal')) 
			AND (@isRefund IS NULL 
					OR (m.sporttype <> 5 AND @isRefund = 1 AND betstatus LIKE 'Refund%') 
					OR (m.sporttype <> 5 AND @isRefund = 0 AND ISNULL(betstatus, '') NOT LIKE 'Refund%')
					OR (m.sporttype = 5 AND @isRefund = 1 AND ISNULL(r.SettlementStatusID,0) BETWEEN 1 AND 3)
					OR (m.sporttype = 5 AND @isRefund = 0 AND ISNULL(r.SettlementStatusID,0) NOT BETWEEN 1 AND 3)
				)
	) tmp
	LEFT JOIN dbo.match_remark mr WITH (NOLOCK) ON tmp.matchid = mr.matchid
	where (@UncalOnly = 0 OR ISNULL(mr.calculate, 0) = 0 OR @UncalOnly IS NULL) 
	AND (@UncalMultiOnly = 0 OR ISNULL(mr.multiple, 0) = 0 OR @UncalMultiOnly IS NULL)	
	
	SELECT @rowcount = 0
		,@max_matchid = 0

	WHILE (1 = 1)
	BEGIN
		DELETE @tmp_match

		INSERT INTO @tmp_match (matchid)
		SELECT TOP 1000 matchid
		FROM #matchList
		WHERE matchid > @max_matchid
		ORDER BY matchid ASC

		SELECT @rowcount = @@rowcount

		IF @rowcount = 0
			BREAK;

		SELECT @max_matchid = MAX(matchid)
		FROM @tmp_match

		SELECT @strmatchid = ( SELECT matchid 
							   FROM @tmp_match
							   FOR XML PATH('match') ,ROOT('root')
				)
		-- FGLG
		EXEC DBTXN.bodb02.dbo.NAP_Set_MatchBetStatusSel @matchid = @strmatchid
			,@betstatus = @betstatus OUTPUT

		--Create an internal representation of the XML document.      
		EXEC sp_xml_preparedocument @intDocHandle OUTPUT
			,@betstatus


		UPDATE m
		SET IsExistFGLG = ISNULL(rs.cnt,0)		
		FROM #matchList m
		INNER JOIN ( SELECT matchid 
					,cnt
					FROM OPENXML(@intDocHandle, '/root/match', 2) WITH (matchid INT, cnt INT)
			) rs ON m.matchid = rs.matchid


		-- HT FGLG
		EXEC DBTXN.bodb02.dbo.NAP_Set_MatchBetStatusSel @matchid = @strmatchid
			,@bettype = 127
			,@betstatus = @betstatus OUTPUT

		--Create an internal representation of the XML document.      
		EXEC sp_xml_preparedocument @intDocHandle OUTPUT
			,@betstatus

		UPDATE m
		SET IsExistHTFGLG = ISNULL(rs.cnt,0)		
		FROM #matchList m
		INNER JOIN ( SELECT matchid 
					,cnt
					FROM OPENXML(@intDocHandle, '/root/match', 2) WITH (matchid INT, cnt INT)
			) rs ON m.matchid = rs.matchid
	END

	;WITH SingleTicket AS
	(
		SELECT matchid, max(IsCalculating)  IsCalculating
		FROM DBTXN.bodb02.dbo.Single_Calculate_Queue s WITH(NOLOCK)
		WHERE Starttime > DATEADD(HH,-1,GETDATE())
		AND s.IsCalculating IN (0,1)
		group by matchid 
	),
	ParlayTicket AS
	(
		SELECT p.matchid, min(IsCalculating)  IsCalculating
		FROM DBTXN.bodb02.dbo.Parlay_Calculate_Queue p WITH(NOLOCK)
		WHERE Starttime > DATEADD(HH,-1,GETDATE())
		AND p.IsCalculating IN (0,1)
		group by matchid 
	)	

	select isnull(sg.matchid, pl.matchid) matchid, sg.IsCalculating IsCalculatingSingle, pl.IsCalculating IsCalculatingMP
	into #tempmatch
	from SingleTicket sg
		full outer join ParlayTicket pl on sg.matchid = pl.matchid 

	CREATE TABLE #tmpAutoSettle1s(
		 MatchID		INT
		,SettlementStatusID	TINYINT 
	)
	INSERT INTO #tmpAutoSettle1s(MatchID,SettlementStatusID)
	SELECT	MatchID, MIN(SettlementStatusID)
	FROM	ResultDetail WITH (NOLOCK)
	WHERE	@Sporttype IN(0,1)
			AND MatchID IN (SELECT MatchID FROM #matchList)
			AND (ResourceId IN (SELECT CAST(BetType AS VARCHAR(20)) FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
					OR ResourceID LIKE '160__'
					OR ResourceID LIKE '164__'
					OR ResourceID LIKE '169__'
					OR ResourceID LIKE '180__'
					OR ResourceID LIKE '216__' 
				)
	GROUP BY MatchID 

	CREATE TABLE #tmpCornerBets(
		 MatchID		INT
		,SettlementStatusID	TINYINT
	)
	INSERT INTO #tmpCornerBets(MatchID,SettlementStatusID)
	SELECT	MatchID, MIN(SettlementStatusID)
	FROM	ResultDetail WITH (NOLOCK)
	WHERE	@Sporttype IN(0,1)
			AND MatchID IN (SELECT MatchID FROM #matchList)
			AND ResourceID IN ('04','05','206','207','208','209')			
	GROUP BY MatchID 


	IF @AutoSettlementOnly = 1 --Running Auto bettypes ONLY ( BETRADAR USED)
	BEGIN
		DELETE FROM #matchList
		WHERE	MatchID NOT IN (
			SELECT	MatchID
			FROM	#tmpAutoSettle1s
			WHERE	SettlementStatusID = 0 
		)
	END

	IF @StatusID = 5 
	BEGIN
		DELETE FROM #matchList
		WHERE	MatchID NOT IN (
			SELECT	MatchID
			FROM	#tmpCornerBets
			WHERE	SettlementStatusID = 0 
		)
	END 


	SELECT m.HalfTimeHomeScore
		,m.HalfTimeAwayScore
		,m.IsCalculated
		,m.IsMultiCaled
		,m.IsRefund
		,m.IsCalRefund
		,m.matchid
		,m.leagueid
		,m.homeid
		,m.awayid
		,m.matchcode
		,m.kickofftime
		,m.finalhomescore
		,m.finalawayscore
		,m.betstatus
		,m.eventstatus
		,m.Foddsstatus
		,m.sporttype
		,m.IsNeutral
		,m.eventdate
		,m.goalrecord
		,m.suspenderHalfTime
		,m.suspenderFullTime
		,m.IsHalfTimeCal
		,m.calculate
		,m.isPending
		,m.isUndecided
		,m.IsKeyscore
		,m.IsExistFGLG
		,m.IsExistHTFGLG
		,m.WinOdds
		,m.PlaceOdds
		,t.IsCalculatingSingle
		,t.IsCalculatingMP
		,CASE	WHEN a.SettlementStatusID IS NULL THEN 'N/A'
				WHEN a.SettlementStatusID = 0 THEN 'Running'
				WHEN a.SettlementStatusID > 0 THEN 'Completed'
				ELSE '' END AS AutoSettleResultStatus
	FROM	#matchList m
			LEFT JOIN #tempmatch t ON t.matchid = m.matchid
			LEFT JOIN #tmpAutoSettle1s a WITH (NOLOCK) ON m.matchID = a.MatchID
	ORDER BY case m.eventstatus when 'completed' then 1 when 'refund' then 1 else 0 END
		, m.eventdate
		,m.kickofftime
		, m.sporttype
		,m.leagueid
		,m.matchid
		,m.betstatus
		,m.matchcode			

	-- Get TENNIS RESULT 
	SELECT	MatchId
			, ResourceId
			, HomeValue
			, AwayValue
			, ResultStatusID
			, SettlementStatusID
	FROM	dbo.[ResultDetail] WITH (NOLOCK) 
	WHERE	@Sporttype IN (0,5)
			AND ResourceId LIKE '0[0-5]'  
			AND MatchID IN (SELECT MatchID FROM #matchList)

	DROP TABLE #matchList
	
	SET @EndTime = GETDATE()
	
	IF DATEDIFF(MILLISECOND,@StartTime, @EndTime) > 10000
	BEGIN
		SET @SqlCommand = 'EXEC NAP_Set_MatchSel @FromDate =''' + CONVERT(VARCHAR(20),@FromDate) + ''''
						+ ', @ToDate = ''' + CONVERT(VARCHAR(20),@ToDate) + ''''
						+ ', @SportType =' + CONVERT(VARCHAR(10),@SportType) 
						+ ', @LeagueID =' + CONVERT(VARCHAR(10),@LeagueID)  
						+ ', @MatchCode =''' + ISNULL(@MatchCode,'') + ''''
						+ ', @StatusId = '+ CONVERT(VARCHAR(10),@StatusId)  
						+ ', @FilterBy = '+ CONVERT(VARCHAR(10),@FilterBy)  
						+ ', @AutoSettlementOnly = '+ CONVERT(VARCHAR(10),@AutoSettlementOnly)  
						+ ', @IsReLoad = '+ CONVERT(VARCHAR(10),@IsReLoad)  
						
	
		INSERT INTO SettlementRunSPLog(LogDate, SqlCommand, StartTime, EndTime)
		SELECT GETDATE(), @SqlCommand, @StartTime, @EndTime
	END
END


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_Set_MatchSel] TO [bodbAdminNet]
GO 
