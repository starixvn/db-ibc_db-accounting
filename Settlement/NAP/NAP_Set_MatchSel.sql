ALTER PROCEDURE [NAP_Set_MatchSel] @FromDate DATETIME
	,@ToDate DATETIME
	,@SportType TINYINT = 0
	,@LeagueID INT = 0
	,-- 0 for ALL Leagues
	@MatchCode NVARCHAR(50) = ''
	,@StatusId TINYINT = 0
	,@FilterBy TINYINT = 0
	,@IsReLoad BIT = 0
AS
/*  
 Created by: Kathy
 Date: 20131223
 Task: Match results for calculating settlement 
 DB: DB02.BODB02
 Original: Acc_Set_MatchSel
 Revisions:  
		- 20140417@Kathy: re-arrange order list (follow by old system)
		- 20140421@Kathy: get match status in queue
      
 Param explanation:  
	@MatchCode: match code
	@LeagueID: = 0: show info of all leagues     
	@StatusId: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 
	@FilterBy: 0: none, 1: un-calculated game; 2: Un-calculated multiple only; 3: all
	@IsReLoad: 1: reload partial matches of a league, 0: not reload
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @UncalOnly BIT
		,@UncalMultiOnly BIT
		,@eventstatus NVARCHAR(50)
		,@isRefund BIT
		,@matchid INT

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
		IF (@UncalMultiOnly = 1 OR @UncalOnly = 1)
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
		,Foddsstatus VARCHAR(10)
		,sporttype TINYINT
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
		,WinOdds SMALLMONEY
		,PlaceOdds SMALLMONEY
		)

	DECLARE @strmatchid VARCHAR(MAX)
		,@betstatus VARCHAR(8000)
		,@intDocHandle INT
		,@rowcount INT
		,@max_matchid INT
	DECLARE @tmp_match TABLE (matchid INT)

	INSERT INTO #matchList
	SELECT hthomescore
		,htawayscore
		,ISNULL(mr.calculate, 0) IsCalculated
		,ISNULL(mr.multiple, 0) IsMultiCaled
		,ISNULL(mr.refund, 0) IsRefund
		,ISNULL(mr.calrefund, 0) IsCalRefund
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
		,CASE 
			WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1
			ELSE 0
			END IsKeyscore
		,0 as IsExistFGLG
		,0
		,0
	FROM dbo.match m WITH (NOLOCK)
		LEFT JOIN dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate AND m.leagueID = CASE 
			WHEN @LeagueID <> 0 THEN @LeagueID
			ELSE m.leagueID
			END AND (@UncalOnly = 0 OR ISNULL(mr.calculate, 0) = 0 OR @UncalOnly IS NULL) AND (@UncalMultiOnly = 0 OR ISNULL(mr.multiple, 0) = 0 OR @UncalMultiOnly IS NULL) AND CASE 
			WHEN @UncalMultiOnly = 0 THEN 1
			WHEN @UncalMultiOnly = 1 THEN hthomescore * htawayscore * finalhomescore * finalawayscore
			WHEN @UncalMultiOnly IS NULL OR @UncalOnly IS NULL THEN 1
			END IS NOT NULL AND m.sporttype = CASE 
			WHEN @sporttype = 0 THEN m.sporttype
			ELSE @sporttype
			END AND (@matchcode = '' OR (m.matchid = @matchid OR m.matchcode = @matchcode)) AND (@eventstatus = '' OR eventstatus IN (@eventstatus, 'internal')) AND (@isRefund IS NULL OR (@isRefund = 1 AND betstatus LIKE 'Refund%') OR (@isRefund = 0 AND ISNULL(betstatus, '') NOT LIKE 'Refund%'))
	
	SELECT @rowcount = 0
		,@max_matchid = 0

	WHILE (1 = 1)
	BEGIN
		DELETE @tmp_match

		INSERT INTO @tmp_match (matchid)
		SELECT TOP 100 matchid
		FROM #matchList
		WHERE matchid > @max_matchid
		ORDER BY matchid ASC

		SELECT @rowcount = @@rowcount

		IF @rowcount = 0
			BREAK;

		SELECT @max_matchid = MAX(matchid)
		FROM @tmp_match

		SELECT @strmatchid = (
				SELECT matchid
				FROM @tmp_match
				FOR XML PATH('match')
					,ROOT('root')
				)

		EXEC DBTXN.bodb02.dbo.NAP_Set_MatchBetStatusSel @matchid = @strmatchid
			,@betstatus = @betstatus OUTPUT

		--Create an internal representation of the XML document.      
		EXEC sp_xml_preparedocument @intDocHandle OUTPUT
			,@betstatus

		UPDATE m
		SET IsExistFGLG = CASE 
				WHEN rs.cnt = 0 OR rs.cnt IS NULL THEN 0
				ELSE 1
				END
		FROM #matchList m
			INNER JOIN @tmp_match t ON m.matchid = t.matchid
			LEFT JOIN (
			SELECT matchid
				,cnt
			FROM OPENXML(@intDocHandle, '/root/match', 2) WITH (matchid INT, cnt INT)
			) rs ON m.matchid = rs.matchid
	END

	DECLARE @tblSingle table(matchid int, seqS int, seqP int) 
	DECLARE	@tblParlay table(matchid int, seqS int,seqP int)
	DECLARE	@tblSingle_Parlay table(matchid int, seqS int, seqP int)
	DECLARE	@tblResult table(matchid int, seqS int, seqP int)

	INSERT INTO @tblSingle
	SELECT matchid, MAX(IsCalculating), NULL
	FROM DBTXN.bodb02.dbo.Single_Calculate_Queue with(NOLOCK)
	WHERE matchid NOT IN (SELECT matchid FROM DBTXN.bodb02.dbo.Parlay_Calculate_Queue with(NOLOCK))
	AND Starttime > DATEADD(HH,-1,GETDATE())
	AND IsCalculating IN (1,0)
	group BY matchid

	INSERT INTO @tblParlay
	SELECT matchid, NULL, MAX(isCalculating)
	FROM DBTXN.bodb02.dbo.Parlay_Calculate_Queue  WITH(NOLOCK)
		WHERE matchid NOT IN (SELECT matchid FROM DBTXN.bodb02.dbo.Single_Calculate_Queue with(NOLOCK))
			AND Starttime > DATEADD(HH,-1,GETDATE())	
			AND IsCalculating IN (0, 1)
	group BY matchid	

	INSERT INTO @tblSingle_Parlay
	SELECT s.matchid, MAX(s.IsCalculating), MAX(p.IsCalculating)
	FROM DBTXN.bodb02.dbo.Single_Calculate_Queue s WITH(NOLOCK) 
	INNER JOIN DBTXN.bodb02.dbo.Parlay_Calculate_Queue p WITH(NOLOCK) ON p.matchid = s.matchid
	WHERE (p.IsCalculating IN (0, 1) or s.IsCalculating IN (0, 1))
	and (s.Starttime > DATEADD(HH,-1,GETDATE())
			or p.Starttime > DATEADD(HH,-1,GETDATE()))
	group BY s.matchid	

	INSERT INTO @tblResult
	SELECT matchid, seqS, seqP
	FROM @tblSingle
	UNION ALL
	SELECT matchid, seqS, seqP
	FROM @tblParlay
	UNION ALL
	SELECT matchid, seqS, seqP
	FROM @tblSingle_Parlay

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
		,m.WinOdds
		,m.PlaceOdds
		,case when ISNULL(t.seqS,0) > 1 THEN NULL ELSE t.seqS end as IsCalculatingSingle
		,case when isnull(t.seqP,0) >1 THEN NULL ELSE t.seqP END  as IsCalculatingMP
	FROM #matchList m
	LEFT JOIN @tblResult t ON t.matchid = m.matchid
	ORDER BY case m.eventstatus when 'completed' then 1 when 'refund' then 1 else 0 END
		, m.eventdate
		,m.kickofftime
		, m.sporttype
		,m.leagueid
		,m.matchid
		,m.betstatus
		,m.matchcode			


	DROP TABLE #matchList
END

GO

GRANT EXECUTE ON [NAP_Set_MatchSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSel] TO [vnteam] AS [dbo]
GO


