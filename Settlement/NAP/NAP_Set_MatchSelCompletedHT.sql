/****** Object:  StoredProcedure [dbo].[NAP_Set_MatchSelCompletedHT]    Script Date: 09/10/2014 09:44:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_Set_MatchSelCompletedHT    Script Date: 3/17/2014 4:21:11 PM ******/

ALTER PROCEDURE [dbo].[NAP_Set_MatchSelCompletedHT] @Date DATETIME
	,@SportType TINYINT = 0
	,@LeagueID INT = 0
	,-- 0 for ALL Leagues
	@isReLoad BIT = 0
AS
/*
	Created by: Kathy
	Date: 
	Task: List HT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompletedHT
	
	Revisions:
		- 20140421@Kathy: get match status in queue
		- 20140428@Kathy: get 1H FGLG ticket info [Redmine:#14449]
		- 20140905@Kathy: exclude virtual racing bettype 1231,1232,1233
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33),
						 sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		
*/
BEGIN
	SET NOCOUNT ON

	IF @sporttype NOT IN (1, 2, 3, 32) RETURN

	DECLARE @HTOverStartMins INT
		,@HTOverEndMins INT

	SELECT @LeagueID = CASE 
			WHEN @isReLoad = 1 THEN ISNULL(@LeagueID, 0)
			ELSE 0
			END -- reload partial; search on LeagueID, not reload: get all leagues

	SELECT @HTOverStartMins = CASE 
			WHEN @sporttype = 1 THEN 40
			ELSE 25
			END
		,@HTOverEndMins = CASE 
			WHEN @sporttype = 1 THEN 100
			ELSE 60
			END
	DECLARE @tblSingle TABLE (matchid INT, seqS INT)

	INSERT INTO @tblSingle
	SELECT matchid, MAX(IsCalculating)
	FROM Single_Calculate_Queue WITH (NOLOCK)
	WHERE Starttime > DATEADD(HH, - 1, GETDATE()) 
	AND IsCalculating IN (1, 0)
	GROUP BY matchid

	SELECT x.matchid
		,x.leagueid
		,x.HalfTimeHomeScore
		,x.HalfTimeAwayScore
		,x.IsCalculated
		,x.IsMultiCaled
		,x.IsRefund
		,x.IsCalRefund
		,x.homeid
		,x.awayid
		,x.matchcode
		,x.kickofftime
		,x.finalhomescore
		,x.finalawayscore
		,x.betstatus
		,x.eventstatus
		,x.Foddsstatus
		,x.sporttype
		,x.IsNeutral
		,x.eventdate
		,x.goalrecord
		,x.suspenderHalfTime
		,x.suspenderFullTime
		,x.IsHalfTimeCal
		,x.isPending
		,x.isUndecided
		,x.IsKeyscore
		,x.betcount
		,x.isExistFGLG
		,x.isExistHTFGLG
		,t.seqS as IsCalculatingSingle
	FROM (
		SELECT m.matchid
			,m.leagueid
			,HalfTimeHomeScore
			,HalfTimeAwayScore
			,isnull(m.calculate, 0) IsCalculated
			,isnull(m.multiple, 0) IsMultiCaled
			,isnull(m.refund, 0) IsRefund
			,isnull(m.calrefund, 0) IsCalRefund
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
			,Foddsstatus
			,m.sporttype
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,m.eventdate
			,m.goalrecord
			,CASE m.confirmHalfTime
				WHEN 0 THEN ''
				ELSE (
						SELECT username
						FROM CustDB.dbo.custinfo(NOLOCK)
						WHERE custid = m.confirmHalfTime
						)
				END suspenderHalfTime
			,
			--case m.ConfirmFT when 0 then '' else (select username from custinfo (nolock) where custid = m.ConfirmFT ) end suspenderFT,     
			'' AS suspenderFullTime
			,ISNULL(m.IsHalfTimeCal, 0) AS IsHalfTimeCal
			,ISNULL(m.isPending, 0) AS isPending
			,ISNULL(m.isUndecided, 0) AS isUndecided
			,CAST(CASE 
					WHEN HalfTimeHomeScore IS NOT NULL AND HalfTimeAwayScore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1
					ELSE 0
					END AS BIT) AS IsKeyscore
			,c.betcount
			,CASE 
				WHEN c.cntFGLG = 0 THEN 0
				ELSE 1
				END AS isExistFGLG
			,CASE 
				WHEN c.cntHTFGLG = 0 THEN 0
				ELSE 1
				END AS isExistHTFGLG
		FROM (
			SELECT m.matchid
				,m.leagueid
				,hthomescore AS HalfTimeHomeScore
				,htawayscore AS HalfTimeAwayScore
				,mr.calculate
				,mr.multiple
				,mr.refund
				,mr.calrefund
				,m.homeid
				,m.awayid
				,m.matchcode
				,m.kickofftime
				,m.finalhomescore
				,m.finalawayscore
				,m.betstatus
				,m.eventstatus
				,'' AS Foddsstatus
				,m.sporttype
				,m.isNeutral
				,m.eventdate
				,m.goalrecord
				,mr.confirmHT AS confirmHalfTime
				,mr.confirmFT AS confirmFullTime
				,mr.IsHTCal AS IsHalfTimeCal
				,mr.isPending
				,mr.isUndecided
			FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
				INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
			WHERE m.eventdate = @Date AND m.leagueID = CASE 
					WHEN @LeagueID <> 0 THEN @LeagueID
					ELSE m.leagueID
					END AND m.sporttype = @sporttype AND m.eventstatus IN ('Closed', 'running', 'internal') AND ((datediff(minute, m.kickofftime, CURRENT_TIMESTAMP) > @HTOverStartMins AND datediff(minute, m.kickofftime, CURRENT_TIMESTAMP) < @HTOverEndMins) OR mr.confirmHT <> 0) AND mr.ishtcal = 0
			) m
			INNER JOIN (
			SELECT bettrans.matchid
				,count(bettrans.matchid) betcount
				,SUM(CASE 
						WHEN bettype = 14 THEN 1
						ELSE 0
						END) AS cntFGLG
				,SUM(CASE 
						WHEN bettype = 127 THEN 1
						ELSE 0
						END) AS cntHTFGLG
			FROM bettrans WITH (NOLOCK, index=CIX_matchid_bettype)
				inner JOIN DBPRO.BODB02.dbo.match WITH (NOLOCK) ON match.matchid = bettrans.matchid
			WHERE match.eventdate = @Date AND BETTYPE <= 19000 AND match.eventstatus IN ('Closed', 'running', 'internal') 
			AND match.sporttype = @sporttype
			AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238)
			AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			GROUP BY bettrans.matchid
			) c ON m.matchid = c.matchid
		) x LEFT JOIN @tblSingle t ON t.matchid = x.matchid

	ORDER BY eventstatus, matchcode
END


GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelCompletedHT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelCompletedHT] TO [vnteam] AS [dbo]