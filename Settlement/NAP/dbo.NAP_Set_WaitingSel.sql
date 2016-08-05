ALTER PROCEDURE [dbo].[NAP_Set_WaitingSel]
	@MatchCode nvarchar(50) = '',
	@SportType smallint = 0,
	@LeagueID int = 0 -- 0 for ALL Leagues
AS
/*
	Created: 20140103@Kathy
	Task: get status for a match
	DB: DBTXN/BODB02
	
	Revision:
		- 20140419@Lukas: reduce data return by excluding old matches
		- 20140421@Kathy: Directly get IsExistFGLG value from bettrans (not use NAP_Set_MatchBetStatusSel)
		- 20140506@Kathy: get HT FGLG status 
		- 20140711@Kathy: get Penalty Shootout status
		- 20141007@Jamie: Get Tennis in new table [Redmine: #23034]
		- 20150420@Jamie: Betradar phase II [Readmine:#27212]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160805@Kathy: Write log duration

	Param's explanation:  
		
*/
BEGIN

	SET NOCOUNT ON 
	DECLARE @matchid int 
			,@StartTime DATETIME
			,@EndTime	DATETIME
			,@SqlCommand VARCHAR(MAX)
			
	SELECT @MatchCode = ISNULL(@MatchCode,''), @LeagueID = ISNULL(@LeagueID,0),@SportType = ISNULL(@SportType, 0)
	
	SET @StartTime = GETDATE()

	IF (@matchcode <> '')
	BEGIN TRY	
		SET @matchid = CASE WHEN ISNUMERIC(@MatchCode) = 1 THEN CAST(@MatchCode AS INT) ELSE NULL END
	END TRY
	BEGIN CATCH
		SET @matchid=NULL
	END CATCH

	declare @topn int

	;WITH SingleTicket AS
	(
		SELECT matchid, min(IsCalculating)  IsCalculating
		FROM Single_Calculate_Queue s WITH(NOLOCK)
		WHERE Starttime > DATEADD(HH,-1,GETDATE())
		group by matchid 
	),
	ParlayTicket AS
	(
		SELECT p.matchid, min(IsCalculating)  IsCalculating
		FROM Parlay_Calculate_Queue p WITH(NOLOCK)
		WHERE Starttime > DATEADD(HH,-1,GETDATE())
		group by matchid 
	)	
	select isnull(sg.matchid, pl.matchid) matchid, 
			sg.IsCalculating singlestatus, pl.IsCalculating parlaystatus, 
			cast(ISNULL(sg.IsCalculating, 0) as bit) as IsSingle,
			cast(ISNULL(pl.IsCalculating, 0) AS bit) as IsMixParlay
	into #tempmatch
	from SingleTicket sg
		full outer join ParlayTicket pl on sg.matchid = pl.matchid 
		 
	set @topn = @@ROWCOUNT


	CREATE TABLE #tmpAutoSettle1s(
		 MatchID		INT
		,ResultStatusID	TINYINT 
	)
	INSERT INTO #tmpAutoSettle1s(MatchID,ResultStatusID)
	SELECT	MatchID, MIN(ResultStatusID)
	FROM	DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
	WHERE	@Sporttype IN(0,1)
			AND MatchID IN (SELECT MatchID FROM #tempmatch)
			AND (ResourceID IN ('135','168','173','174','175','176','192','193','210','211','212','213','214','215','216','217')
					OR ResourceID LIKE '160__'
					OR ResourceID LIKE '164__'
					OR ResourceID LIKE '169__'
					OR ResourceID LIKE '180__'
					OR ResourceID LIKE '216__' 
				)
	GROUP BY MatchID 

	select matchid,
		leagueid,
		HalfTimeHomeScore,
		HalfTimeAwayScore,
		IsCalculated,
		IsMultiCaled,
		IsRefund,
		IsCalRefund,
		homeid,
		awayid,
		matchcode,
		--kickofftime,
		finalhomescore,
		finalawayscore,
		betstatus,
		eventstatus,
		SettlementStatus135,
		--Foddsstatus,
		sporttype,
		IsNeutral,
		--eventdate,
		goalrecord,
		--suspenderHalfTime,
		--suspenderFullTime,
		IsHalfTimeCal,
		isPending,
		isUndecided,
		IsKeyscore,
		IsExistFGLG,
		IsExistHTFGLG,
		IsCalculatingSingle,
		IsCalculatingMP,
		t.AutoSettleResultStatus
	from 
	(
		select m.matchid, m.leagueid ,
			hthomescore HalfTimeHomeScore,
			htawayscore HalfTimeAwayScore, 
			isnull(mr.calculate,0) IsCalculated, isnull(mr.multiple,0) IsMultiCaled,  
			isnull(mr.refund,0) IsRefund, isnull(mr.calrefund,0) IsCalRefund,  		
			m.homeid, m.awayid,  
			m.matchcode, 
			--m.kickofftime,  
			m.finalhomescore,  
			m.finalawayscore, m.betstatus,  
			case when m.betstatus like 'Refund FT%' then 'Refund FT'  
				when m.betstatus like 'Refund HT%' then 'Refund HT'  
				when m.betstatus like 'Refund%' then 'Refund'  
				else m.eventstatus  
			end as eventstatus,    
			ISNULL(mr.SettlementStatus135,0) SettlementStatus135,
			--'' as Foddsstatus,  
			m.sporttype,  
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
			--m.eventdate,  
			m.goalrecord, 
			--case mr.ConfirmHT when 0 then '' else (select username from CustDB.dbo.custInfo (nolock) where custid = mr.ConfirmHT ) end suspenderHalfTime,   
			--case mr.ConfirmFT when 0 then '' else (select username from CustDB.dbo.custInfo (nolock) where custid = mr.ConfirmFT ) end suspenderFullTime,  
			ISNULL(mr.IsHTCal,0) as IsHalfTimeCal,  		
			ISNULL(mr.isPending,0) as isPending,  
			ISNULL(mr.isUndecided,0) as isUndecided,  
			CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore ,
			case when C.cntFGLG <> 0 then 1 ELSE 0 END IsExistFGLG,
			case when C.cntHTFGLG <> 0 then 1 ELSE 0 END IsExistHTFGLG,
			tm.singlestatus as IsCalculatingSingle,
			tm.parlaystatus as IsCalculatingMP
			,CASE	WHEN a.ResultStatusID IS NULL THEN 'N/A'
				WHEN a.ResultStatusID IN(0,1,3) THEN 'Running'
				WHEN a.ResultStatusID IN (2,5) THEN 'Completed'
				ELSE '' END AS AutoSettleResultStatus
		FROM #tempmatch tm		
			INNER JOIN DBPRO.bodb02.dbo.match m with(NOLOCK) ON  tm.matchid = m.matchid
			LEFT JOIN #tmpAutoSettle1s a WITH (NOLOCK) ON m.matchID = a.MatchID
			LEFT JOIN (
							SELECT b.matchid,
								sum(CASE when b.bettype = 14 THEN 1 ELSE 0 end) as cntFGLG  ,
								sum(CASE when b.bettype = 127 THEN 1 ELSE 0 end)  as cntHTFGLG 
							FROM bettrans b WITH(NOLOCK) 
							where b.bettype in (14 , 127)
							GROUP BY b.matchid				
						) C ON C.matchid = m.matchid
			LEFT OUTER JOIN DBPRO.bodb02.dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid		
		WHERE  
			 m.matchid in (select top (@topn) matchid from #tempmatch)
			and mr.matchid in (select top (@topn) matchid from #tempmatch)
	) t 
	where 
		t.leagueID = case when @LeagueID <> 0 then @LeagueID else t.leagueID end  
			AND t.sporttype = case when @sporttype = 0 then t.sporttype else @sporttype end  	  		
			AND (@matchcode = '' or (t.matchid = @matchid OR t.matchcode = @matchcode))
	
	-- GET TENNIS RESULT DETAIL 
	SELECT	MatchId
			, ResourceId
			, HomeValue
			, AwayValue
			, ResultStatusID
			, SettlementStatusID
	FROM	DBPRO.bodb02.dbo.[ResultDetail] WITH (NOLOCK) 
	WHERE	MatchID IN (SELECT MatchID FROM #tempmatch)	
			AND ResourceId LIKE '0[0-5]' 
			
	SET @EndTime = GETDATE()
	
	IF DATEDIFF(MILLISECOND,@StartTime, @EndTime) > 1000
	BEGIN
		SET @SqlCommand = 'EXEC NAP_Set_WaitingSel @MatchCode =''' + ISNULL(@MatchCode,'') + ''', @SportType = ' + CONVERT(VARCHAR(10),@SportType) + ', @LeagueId =' + CONVERT(VARCHAR(10),@LeagueId)
	
		INSERT INTO SettlementRunSPLog(LogDate, SqlCommand, StartTime, EndTime)
		SELECT GETDATE(), @SqlCommand, @StartTime, @EndTime
	END
END

GO

 GRANT VIEW DEFINITION ON [dbo].[NAP_Set_WaitingSel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_Set_WaitingSel] TO [bodbAdminNet]
GO 
