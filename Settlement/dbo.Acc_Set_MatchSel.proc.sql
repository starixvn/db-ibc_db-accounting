ALTER PROCEDURE [dbo].[Acc_Set_MatchSel]
	@FromDate datetime,
	@ToDate datetime,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@UncalOnly bit = 0,	
	@UncalMultiOnly bit = 0,
	@sporttype tinyint = 0
AS 
  
/*  
	Created by: []  
	Date: 2008  
	Task: Match results  
	DB: DBPRO/BODB02  

	Revisions:  
		- 20090116@Vinh: add filter by sporttype  
		- 20090206@PhuongNguyen: get GoalRecord from match table  
		- 20090114@PhuongDao: Horse Racing Result  
		- 20090301@Thien:  fix the display of Horse Racing section  
		- 20090429@PhuongDao: Show suspender who confirms the score of match.   
		- 20091202@Jamie: Get results for Fixed Odds HR  
		- 20091202@Simon: Get "Foddsstatus" column for Fixed Odds HR  
		- 20110907@Sophia: Add column IsHTCal, calculate for Pending Result    
		- 20110914@Lukas: Add column IsKeyscore for multiple calculate  
		- 20111003@Sophia: Add column IsPending for Pending Status  
		- 20111004@Viet: rearrange orderby part  
		- 20120306@Hurri: Add column IsUndecided for mark/unmark Undecided match  
		- 20120626@Jamie: Get meetings for Harness 
		- 20130328@Lukas: move to DBTXN/bodb02 & get FGLG ticket info 		
		- 20130719@Elodie: get result for Virtual HR
		- 20130808@Kathy:  Amend to show refund game for virtual horse racing/tennis
		- 20131125@Elodie: get result for Virtual Greyhounds, Motor Racing
		- 20131212@Johnson: move sp to DBPRO.bodb02
	Param explanation:  
		@LeagueID: = 0: show info of all leagues     
  
*/  

BEGIN
	SET NOCOUNT ON  
	

	CREATE TABLE #matchList
	(
		hthomescore INT,
		htawayscore INT,
		IsCalculated BIT,
		IsMultiCaled BIT,
		IsRefund BIT,   
		IsCalRefund BIT,
		matchid INT,
		leagueid INT,
		homeid INT,
		awayid INT,
		matchcode NVARCHAR(50),
		kickofftime DATETIME, 
		finalhomescore INT,
		finalawayscore INT,   
		betstatus NVARCHAR(50),
		eventstatus NVARCHAR(50),                            
		Foddsstatus VARCHAR(10),
		sporttype INT,
		IsNeutral BIT,
		eventdate  DATETIME,          
		goalrecord VARCHAR(50),                       
		suspenderHT NVARCHAR(50),
		suspenderFT NVARCHAR(50),
		IsHTCal BIT,
		calculate BIT,
		isPending BIT,
		isUndecided BIT,
		IsKeyscore BIT,
		IsFGLG BIT, 
		WinOdds SMALLMONEY,
		PlaceOdds SMALLMONEY
	)
	
	DECLARE @matchid VARCHAR(MAX),
			@betstatus VARCHAR(8000),
			@intDocHandle INT,
			@rowcount INT,
			@max_matchid INT
			
	DECLARE @tmp_match TABLE(matchid INT)

	INSERT INTO #matchList
	SELECT 
		hthomescore
		,htawayscore
		,ISNULL(mr.calculate,0) IsCalculated
		,ISNULL(mr.multiple,0) IsMultiCaled
		,ISNULL(mr.refund,0) IsRefund
		,ISNULL(mr.calrefund,0) IsCalRefund
		,m.matchid
		,m.leagueid
		,m.homeid
		,m.awayid
		,m.matchcode
		,m.kickofftime
		,m.finalhomescore
		,m.finalawayscore
		,m.betstatus
		,CASE	WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'  
				WHEN m.betstatus like 'Refund HT%' THEN 'Refund HT'  
				WHEN m.betstatus like 'Refund%' THEN 'Refund'  
				ELSE m.eventstatus  
		END AS eventstatus
		,'' AS Foddsstatus
		,m.sporttype
		,ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral
		,m.eventdate
		,m.goalrecord --Phuong.Nguyen  
		,CASE mr.ConfirmHT WHEN 0 THEN '' ELSE (SELECT username FROM custinfo WITH(NOLOCK) WHERE custid = mr.ConfirmHT ) END suspenderHT
		,CASE mr.ConfirmFT WHEN 0 THEN '' ELSE (SELECT username FROM custinfo WITH(NOLOCK) WHERE custid = mr.ConfirmFT ) END suspenderFT
		,ISNULL(mr.IsHTCal,0) AS IsHTCal
		,ISNULL(mr.calculate,0) AS calculate
		,ISNULL(mr.isPending,0) AS isPending  
		,ISNULL(mr.isUndecided,0) AS isUndecided  --Hurri@20120306
		,CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END IsKeyscore  
		,0,0,0
	FROM dbo.match m WITH(NOLOCK)
		LEFT JOIN dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid  
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate  
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END
		AND (@UncalOnly = 0 OR ISNULL(mr.calculate,0) = 0)  
		AND (@UncalMultiOnly = 0 OR ISNULL(mr.multiple,0) = 0)  
		AND (@UncalMultiOnly = 0 OR ISNULL(mr.multiple,0) = 0)     
		AND CASE	WHEN @UncalMultiOnly = 0 THEN 1   
					WHEN @UncalMultiOnly = 1 THEN hthomescore*htawayscore*finalhomescore*finalawayscore  
			END IS NOT NULL  
		AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END
		
	SELECT @rowcount = 0, @max_matchid = 0
	
	WHILE @rowcount < 100
	BEGIN
		DELETE @tmp_match
		
		INSERT INTO @tmp_match(matchid)
		SELECT TOP 100 matchid
		FROM #matchList
		WHERE matchid > @max_matchid
		ORDER BY  matchid ASC
		
		SELECT @rowcount = @@rowcount
		
		IF @rowcount = 0
			break;
		
		SELECT @max_matchid = MAX(matchid)
		FROM @tmp_match
		
		SELECT @matchid = (
			SELECT matchid 
			FROM @tmp_match
			FOR XML PATH('match'), ROOT('root')
		)
		
		EXEC DBTXN.bodb02.dbo.Acc_Set_MatchBetStatusSel @matchid = @matchid, @betstatus = @betstatus OUTPUT
		
		--Create an internal representation of the XML document.      
		EXEC sp_xml_preparedocument @intDocHandle OUTPUT, @betstatus
		
		UPDATE m
		SET IsFGLG = CASE WHEN rs.cnt = 0 OR rs.cnt IS NULL THEN 0 ELSE 1 END
		FROM #matchList m
			INNER JOIN @tmp_match t ON m.matchid = t.matchid
			LEFT JOIN (
					SELECT matchid, cnt
					FROM OPENXML(@intDocHandle,'/root/match',2)
					with (matchid INT,
						cnt INT) 
			)rs ON m.matchid = rs.matchid
	END		
	
	-- outright table
	INSERT INTO #matchList
	SELECT 
		o.IsFavor hthomescore  --TF  
		,o.IsSCR   htawayscore  --SCR  
		,0  IsCalculated
		,0  IsMultiCaled
		,0  IsRefund 
		,0  IsCalRefund
		,o.groupmatch  matchid --Race   
		,o.leagueid
		,o.teamid homeid
		,0 awayid
		,o.matchcode  --Horse   
		,o.kickofftime
		,0 finalhomescore
		,0 finalawayscore
		,CASE WHEN o.placing = 0 THEN '5' ELSE ISNULL(CONVERT(VARCHAR(2),placing),5) END betstatus --Placing  
		,o.oddsstatus eventstatus
		,o.Foddsstatus
		,l.sporttype
		,0 IsNeutral
		,o.eventdate
		,'' AS goalrecord --Phuong.Nguyen   
		,'' AS suspenderHT  
		,'' AS suspenderFT  
		,0 AS IsHTCal
		,0 AS calculate
		,0 AS isPending
		,0 AS isUndecided --Hurri@20120306 
		,0 AS IsKeyscore
		,0 AS IsFGLG
		,o.Odds
		,o.PlaceOdds
	FROM	dbo.outright o WITH(NOLOCK)
			INNER JOIN league l WITH(NOLOCK) ON o.leagueid = l.leagueid   
	WHERE	o.eventdate >= @FromDate AND o.eventdate <= @ToDate   
			AND l.sporttype BETWEEN (CASE WHEN @sporttype = 0 THEN 151 ELSE @sporttype END ) AND (CASE WHEN @sporttype = 0 THEN 153 ELSE @sporttype END )
			AND @sporttype IN (0, 151, 152, 153)
			AND o.leagueid = CASE WHEN @leagueid = 0 THEN o.leagueid ELSE @leagueid END
			AND (o.oddsstatus = 'completed' OR o.oddsstatus = 'refund' OR o.Foddsstatus = 'completed' )   
		
	--Virtual HR, Virtual Grey Hounds, Motor Racing
	INSERT INTO #matchList
	SELECT 
		0 hthomescore  --TF  
		,0  htawayscore  --SCR  
		,0  IsCalculated
		,0  IsMultiCaled
		,0  IsRefund 
		,0  IsCalRefund
		,o.EventID  matchid --Race   
		,r.leagueid
		,o.RacerID homeid
		,0 awayid
		,o.RacerNum matchcode  --Horse   
		,r.EventTime kickofftime
		,0 finalhomescore
		,0 finalawayscore
		,o.placing betstatus --Placing  
		--,o.eventstatus 
		, CASE WHEN r.betstatus LIKE 'Refund%' THEN 'Refund' ELSE o.eventstatus END eventstatus		
		,o.IsFavor Foddsstatus
		,r.sporttype
		,0 IsNeutral
		,o.eventdate
		,'' AS goalrecord --Phuong.Nguyen   
		,'' AS suspenderHT  
		,'' AS suspenderFT  
		,0 AS IsHTCal
		,0 AS calculate
		,0 AS isPending
		,0 AS isUndecided --Hurri@20120306 
		,0 AS IsKeyscore
		,0 AS IsFGLG
		,o.WinOdds
		,o.PlaceOdds
		
	FROM	dbo.VSOutright o WITH(NOLOCK)
			INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			INNER JOIN league l WITH(NOLOCK) ON r.leagueid = l.leagueid   
	WHERE	o.eventdate >= @FromDate AND o.eventdate <= @ToDate   
			AND l.sporttype = CASE WHEN @sporttype = 0 THEN l.sporttype ELSE @sporttype END
			AND @sporttype in (0,181,182,184)
			AND r.leagueid = CASE WHEN @leagueid = 0 THEN r.leagueid ELSE @leagueid END
			AND o.eventstatus = 'completed' 
			
	SELECT	m.hthomescore,
			m.htawayscore,
			m.IsCalculated,
			m.IsMultiCaled,
			m.IsRefund,
			m.IsCalRefund,
			m.matchid,
			m.leagueid,
			m.homeid,
			m.awayid,
			m.matchcode,
			m.kickofftime,
			m.finalhomescore,
			m.finalawayscore,
			m.betstatus,
			m.eventstatus  ,
			m.Foddsstatus,
			m.sporttype,
			m.IsNeutral,
			m.eventdate,
			m.goalrecord,
			m.suspenderHT,
			m.suspenderFT,
			m.IsHTCal,
			m.calculate,
			m.isPending,
			m.isUndecided,
			m.IsKeyscore,
			m.IsFGLG,
			m.WinOdds,
			m.PlaceOdds
	FROM #matchList m		
	ORDER BY CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END
			,eventdate
			,kickofftime
			,sporttype
			,leagueid
			,matchid
			,betstatus
			,matchcode  

	DROP TABLE #matchList
END




GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_MatchSel] TO [vnteam] AS [dbo]