ALTER PROCEDURE [NAP_Set_MatchSel]
	@FromDate datetime,
	@ToDate datetime,
	@SportType tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@MatchCode nvarchar(50) = '',
	@StatusId tinyint = 0,
	@FilterBy tinyint = 0,
	@IsReLoad bit = 0
AS 
  
/*  
 Created by: Kathy
 Date: 20131223
 Task: Match results for calculating settlement 
 DB: DB02.BODB02
 Original: Acc_Set_MatchSel
 Revisions:  

      
 Param explanation:  
	@MatchCode: match code
	@LeagueID: = 0: show info of all leagues     
	@StatusId: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 
	@FilterBy: 0: none, 1: un-calculated game; 2: Un-calculated multiple only; 3: all
	@IsReLoad: 1: reload partial matches of a league, 0: not reload
*/  
BEGIN
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
		SELECT @eventstatus= '', 	
				@isRefund = NULL,
			@LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END, -- reload partial; search on LeagueID, not reload: get all leagues	
			@UncalOnly = NULL,
			@UncalMultiOnly = NULL 		
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

	CREATE TABLE #matchList
	(
		HalfTimeHomeScore INT,
		HalfTimeAwayScore INT,
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
		sporttype tinyint,
		IsNeutral BIT,
		eventdate  DATETIME,          
		goalrecord VARCHAR(50),                       
		suspenderHalfTime NVARCHAR(50),
		suspenderFullTime NVARCHAR(50),
		IsHalfTimeCal BIT,
		calculate BIT,
		isPending BIT,
		isUndecided BIT,
		IsKeyscore BIT,
		IsExistFGLG BIT, 
		WinOdds SMALLMONEY,
		PlaceOdds SMALLMONEY
	)
	
	DECLARE @strmatchid VARCHAR(MAX),
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
		,CASE mr.ConfirmHT WHEN 0 THEN '' ELSE (SELECT username FROM custdb.dbo.custinfo WITH(NOLOCK) WHERE custid = mr.ConfirmHT ) END suspenderHT
		,CASE mr.ConfirmFT WHEN 0 THEN '' ELSE (SELECT username FROM custdb.dbo.custinfo WITH(NOLOCK) WHERE custid = mr.ConfirmFT ) END suspenderFT
		,ISNULL(mr.IsHTCal,0) AS IsHTCal
		,ISNULL(mr.calculate,0) AS calculate
		,ISNULL(mr.isPending,0) AS isPending  
		,ISNULL(mr.isUndecided,0) AS isUndecided  
		,CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END IsKeyscore  
		,0,0,0
	FROM dbo.match m WITH(NOLOCK)
		LEFT JOIN dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid  
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate  
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END
		AND (@UncalOnly = 0 OR ISNULL(mr.calculate,0) = 0 OR @UncalOnly IS NULL )  
		AND (@UncalMultiOnly = 0 OR ISNULL(mr.multiple,0) = 0 OR @UncalMultiOnly IS NULL)    
		AND CASE	WHEN @UncalMultiOnly = 0 THEN 1   
					WHEN @UncalMultiOnly = 1 THEN hthomescore*htawayscore*finalhomescore*finalawayscore  
					WHEN @UncalMultiOnly IS NULL OR @UncalOnly IS NULL THEN 1
			END IS NOT NULL  
		AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END
		AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 
		AND (@eventstatus='' or eventstatus in (@eventstatus,'internal')) 
		AND (@isRefund is null or 
				(@isRefund =1 and betstatus like 'Refund%') or
				(@isRefund =0 and ISNULL(betstatus,'') not like 'Refund%') 
			)	  
	SELECT @rowcount = 0, @max_matchid = 0
	
	WHILE (1=1)
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
		
		SELECT @strmatchid = (
			SELECT matchid 
			FROM @tmp_match
			FOR XML PATH('match'), ROOT('root')
		)
		
		EXEC DBTXN.bodb02.dbo.Acc_Set_MatchBetStatusSel @matchid = @strmatchid, @betstatus = @betstatus OUTPUT
		
		--Create an internal representation of the XML document.      
		EXEC sp_xml_preparedocument @intDocHandle OUTPUT, @betstatus
		
		UPDATE m
		SET IsExistFGLG = CASE WHEN rs.cnt = 0 OR rs.cnt IS NULL THEN 0 ELSE 1 END
		FROM #matchList m
			INNER JOIN @tmp_match t ON m.matchid = t.matchid
			LEFT JOIN (
					SELECT matchid, cnt
					FROM OPENXML(@intDocHandle,'/root/match',2)
					with (matchid INT,
						cnt INT) 
			)rs ON m.matchid = rs.matchid
	END		
			
	SELECT	m.HalfTimeHomeScore,
			m.HalfTimeAwayScore,
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
			m.suspenderHalfTime,
			m.suspenderFullTime,
			m.IsHalfTimeCal,
			m.calculate,
			m.isPending,
			m.isUndecided,
			m.IsKeyscore,
			m.IsExistFGLG,
			m.WinOdds,
			m.PlaceOdds
	FROM #matchList m		
	ORDER BY sporttype, leagueid, 
		CASE when eventstatus = 'Running' THEN 0
			 when eventstatus = 'Closed' then 1
			 WHEN eventstatus = 'completed' THEN 3
			 WHEN eventstatus LIKE '%Refund%' THEN 3 
		END,  
		eventdate, 
		kickofftime

	DROP TABLE #matchList
END

GO

GRANT EXECUTE ON [NAP_Set_MatchSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSel] TO [vnteam] AS [dbo]
GO


