/****** Object:  StoredProcedure [dbo].[NAP_Set_MatchSelCompleted]    Script Date: 09/08/2014 10:27:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Set_MatchSelCompleted] @Date DATETIME
	,@SportType TINYINT = 0
	,@LeagueID INT = 0
	,-- 0 for ALL Leagues   
	@isReLoad BIT = 0
AS
/*
	Created by: Kathy
	Date: 
	Task: List FT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompleted

	Revisions:
		- 20140421@Kathy: get match status in queue
		- 20140428@Kathy: get 1H FGLG ticket info [Redmine:#14449]
		- 20140701@Viet: change goalrecord to varchar(50), matchcode to nvarchar(50)
		- 20140905@Kathy: exclude virtual racing bettype 1231,1232,1233


	Param explanation: 
		@isReLoad: 1: reload partial matches of a league, 0: not reload
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT @LeagueID = CASE 
			WHEN @isReLoad = 1 THEN ISNULL(@LeagueID, 0)
			ELSE 0
			END -- reload partial; search on LeagueID, not reload: get all leagues

	CREATE TABLE #matchList (
		matchid INT
		,leagueid INT
		,HalfTimeHomeScore INT
		,HalfTimeAwayScore INT
		,IsCalculated BIT
		,IsMultiCaled BIT
		,IsRefund BIT
		,IsCalRefund BIT
		,homeid INT
		,awayid INT
		,matchcode NVARCHAR(50)
		,kickofftime DATETIME
		,finalhomescore INT
		,finalawayscore INT
		,betstatus NVARCHAR(50)
		,eventstatus NVARCHAR(50)
		,Foddsstatus NVARCHAR(50)
		,sporttype TINYINT
		,IsNeutral BIT
		,eventdate DATETIME
		,goalrecord VARCHAR(50)
		,suspenderHalfTime NVARCHAR(50)
		,suspenderFullTime NVARCHAR(50)
		,IsHalfTimeCal BIT
		,isPending BIT
		,isUndecided BIT
		,IsKeyscore BIT
		,calculate BIT
		,IsExistFGLG BIT
		,IsExistHTFGLG BIT
		,BetCount INT
		)

	CREATE TABLE #m(
		matchid INT PRIMARY KEY
		,IsCalculated BIT
		,IsMultiCaled BIT
		,IsRefund BIT
		,IsCalRefund BIT
		,IsHalfTimeCal BIT
		,suspenderHalfTime NVARCHAR(50)
		,suspenderFullTime NVARCHAR(50)
		,calculate BIT
		,isPending BIT
		,isUndecided BIT
		,leagueid int
		,homeid int 
		,awayid int 
		,matchcode nvarchar(50)
		,kickofftime datetime
		,finalhomescore int 
		,finalawayscore int 
		,betstatus nvarchar(50)
		,eventstatus nvarchar(50)
		,Foddsstatus nvarchar(50)
		,sporttype TINYINT 		
		, IsNeutral bit
		,eventdate smalldatetime
		,goalrecord varchar(50)
		,hthomescore int 
		,htawayscore int 		
		)

	INSERT INTO #m
	SELECT m.matchid
		,isnull(mr.calculate, 0) IsCalculated
		,isnull(mr.multiple, 0) IsMultiCaled
		,isnull(mr.refund, 0) IsRefund
		,isnull(mr.calrefund, 0) IsCalRefund
		,mr.IsHTCal
		,IsNull(ht.username, '')
		,IsNull(ft.username, '')
		,mr.calculate
		,ISNULL(mr.isPending, 0) AS isPending
		,ISNULL(mr.isUndecided, 0) AS isUndecided
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
		, m.sporttype	
		,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		,m.eventdate
		,m.goalrecord
		,m.hthomescore
		,m.htawayscore
	FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
		LEFT OUTER JOIN CustDB.dbo.custinfo ht WITH (NOLOCK) ON mr.ConfirmHT = ht.custid
		LEFT OUTER JOIN CustDB.dbo.custinfo ft WITH (NOLOCK) ON mr.ConfirmFT = ft.custid
	WHERE m.eventdate = @Date 	AND 
	m.leagueID = CASE 
			WHEN @LeagueID <> 0 THEN @LeagueID
			ELSE m.leagueID
			END AND m.sporttype = CASE 
			WHEN @sporttype = 0 THEN sporttype
			ELSE @sporttype
			END 
			AND m.eventstatus <> N'Completed' AND (m.kickofftime < dateadd(s, - 6000, CURRENT_TIMESTAMP) OR mr.ConfirmFT > 0)
	
	INSERT INTO #matchList	
		SELECT tm.matchid
			,tm.leagueid
			,hthomescore HalfTimeHomeScore
			,htawayscore HalfTimeAwayScore
			,IsCalculated
			,IsMultiCaled
			,IsRefund
			,IsCalRefund
			,tm.homeid
			,tm.awayid
			,tm.matchcode
			,tm.kickofftime
			,tm.finalhomescore
			,tm.finalawayscore
			,tm.betstatus
			,tm.eventstatus
			,'' AS Foddsstatus
			,tm.sporttype
			,tm.IsNeutral
			,tm.eventdate
			,tm.goalrecord
			,suspenderHalfTime
			,suspenderFullTime
			,ISNULL(tm.IsHalfTimeCal, 0) AS IsHalfTimeCal
			,ISNULL(tm.IsPending, 0) AS IsPending
			,ISNULL(tm.isUndecided, 0) AS isUndecided
			,CAST(CASE 
					WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1
					ELSE 0
					END AS BIT) AS IsKeyscore
			,ISNULL(tm.calculate, 0) AS calculate
			,case when c.cntFGLG = 0 THEN 0 ELSE 1 END as isExistFGLG
			,case when C.cntHTFGLG = 0 THEN 0 ELSE 1 END as isExistHTFGLG
			,C.BetCount
		FROM #m tm 
			INNER JOIN (
			SELECT b.matchid
				,count(b.matchid) AS BetCount
				,SUM(CASE 
						WHEN bettype = 14 THEN 1
						ELSE 0
						END) AS cntFGLG
				,SUM(CASE 
						WHEN bettype = 127 THEN 1
						ELSE 0
						END) AS cntHTFGLG
			FROM dbo.bettrans b WITH (NOLOCK,index=CIX_matchid_bettype)
				INNER JOIN #m stm ON b.matchid = stm.matchid
			WHERE winlostdate = @Date
				and b.matchid in (select distinct matchid from #m)
				AND b.bettype NOT IN (1231, 1232, 1233)
				AND b.bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			GROUP BY b.matchid
			) AS C ON tm.matchid = c.matchid

	DECLARE @tblSingle TABLE (matchid INT, seqS INT)

	INSERT INTO @tblSingle
	SELECT matchid, MAX(IsCalculating)
	FROM Single_Calculate_Queue WITH (NOLOCK)
	WHERE Starttime > DATEADD(HH, - 1, GETDATE()) 
	AND IsCalculating IN (1, 0)
	GROUP BY matchid


	SELECT m.matchid 
		,leagueid 
		,HalfTimeHomeScore 
		,HalfTimeAwayScore 
		,IsCalculated 
		,IsMultiCaled 
		,IsRefund 
		,IsCalRefund 
		,homeid 
		,awayid 
		,matchcode 
		,kickofftime 
		,finalhomescore 
		,finalawayscore 
		,betstatus 
		,eventstatus 
		,Foddsstatus 
		,sporttype 
		,IsNeutral 
		,eventdate 
		,goalrecord 
		,suspenderHalfTime 
		,suspenderFullTime 
		,IsHalfTimeCal 
		,isPending 
		,isUndecided 
		,IsKeyscore 
		,calculate 
		,IsExistFGLG 
		,m.IsExistHTFGLG
		,BetCount
		,t.seqS AS IsCalculatingSingle
	FROM #matchList m
	LEFT JOIN @tblSingle t ON t.matchid = m.matchid
	ORDER BY m.eventstatus, m.matchcode

	DROP TABLE #matchList
END



GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelCompleted] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelCompleted] TO [vnteam] AS [dbo]