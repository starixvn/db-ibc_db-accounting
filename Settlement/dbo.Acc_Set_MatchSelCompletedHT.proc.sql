ALTER PROCEDURE [Acc_Set_MatchSelCompletedHT]	
	@FromDate DATETIME,
	@sporttype TINYINT = 0
AS

/*
	Created by: Vinh Truong
	Date: 2008-12-16
	Task: List HT-completed matches for billing
	DB: DBTXN/BODB02
	
	Revisions:
		- 20081218@PhuongNguyen: Get IsNeutral from Match
		- 20090429@PhuongDao: Add condition "Confirm HT" for display the result
		- 20110421@Lukas: Add Netball game (sporttype = 32)
		- 20110520@Amy: re-arrange bettype
		- 20110602@Lukas: modify where clause to get corrected sporttype
		- 20110620@Jamie: Refer Match in DB02 instead of DBTRANS
		- 20110907@Sophia: Add column IsHTCal, calculate for Pending Status
		- 20111003@Sophia: Add column isPending Pending Status
		- 20111008@Thien: put index hint index=CIX_matchid_bettype  
		- 20120306@Hurri: Add column IsUndecided for mark/unmark Undecided match
		- 20130121@Elodie: Change link server DB02 to DBPRO
		- 20130325@Lukas: get goalrecord & isExistFGLG
		- 20131017@Elodie: Adjust the display time for HT Over Only [Redmine:#6725]
		- 20140428@Kathy: Get 1H FGLG ticket info [Redmine:#14718]
*/  
BEGIN
	SET NOCOUNT ON  
	  
	IF @sporttype = 1  
	BEGIN  
		SELECT  m.matchid,  
				m.leagueid,  
				m.homeid,  
				m.awayid,                  
				m.matchcode,  
				m.kickofftime,  
				m.finalhomescore,  
				m.finalawayscore,  
				m.hthomescore,  
				m.htawayscore,  
				CASE	WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'  
						WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'  
						WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'  
						ELSE m.eventstatus  
				END AS eventstatus,  
				m.betstatus,  
				m.IsNeutral,  
				C.betcount,  
				CASE m.confirmHT WHEN 0 THEN '' ELSE (SELECT username FROM custdb.dbo.custinfo WITH(NOLOCK) WHERE custid = m.confirmHT) END suspenderHT,  
				m.IsHTCal,   
				m.calculate,  
				m.isPending,
				m.isUndecided,  --Hurri@20120306  
				m.goalrecord,
				CASE WHEN c.cntFGLG = 0 THEN 0 ELSE 1 END AS isExistFGLG,
				CASE WHEN c.cntHTFGLG = 0 THEN 0 ELSE 1 END AS isExistHTFGLG
		FROM    (
				SELECT	match.matchid,  
						match.leagueid,  
						match.homeid,  
						match.awayid,  
						match.matchcode,  
						match.kickofftime,  
						match.finalhomescore,  
						match.finalawayscore,  
						match.hthomescore,  
						match.htawayscore,  
						match.eventstatus,  
						match.betstatus,  
						ISNULL(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
						mr.confirmHT,  
						ISNULL(mr.IsHTCal,0) AS IsHTCal,   
						ISNULL(mr.calculate,0) AS calculate,  
						ISNULL(mr.isPending, 0) AS isPending,   
						ISNULL(mr.isUndecided,0) AS isUndecided,  --Hurri@20120306  
						match.goalrecord
				FROM  DBPRO.BODB02.dbo.match WITH(NOLOCK)
					INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH(NOLOCK) ON match.matchid = mr.matchid                    
				WHERE match.eventstatus <> 'Completed'    
					AND ((DATEDIFF(MINUTE,match.kickofftime,CURRENT_TIMESTAMP) > 40  
					AND DATEDIFF(MINUTE,match.kickofftime,CURRENT_TIMESTAMP) < 100)  
						OR  mr.confirmHT <> 0 )  
					AND match.eventdate = @FromDate  
					AND match.sporttype = 1  
					AND mr.ishtcal=0  
				) m -- for soccer only  
			INNER JOIN  
				(	
				SELECT   bettrans.matchid,  
						COUNT(bettrans.matchid)  betcount,
						SUM(CASE WHEN bettype = 14 THEN 1 ELSE 0 END) AS cntFGLG,
						SUM(CASE WHEN bettype = 127 THEN 1 ELSE 0 END) AS cntHTFGLG
				FROM     bettrans WITH (NOLOCK, INDEX=CIX_matchid_bettype),  
					 DBPRO.BODB02.dbo.match WITH(NOLOCK)
				 WHERE    match.eventdate = @FromDate  
					 and BETTYPE <= 19000  
					 and match.matchid = bettrans.matchid  
					 and match.eventstatus in ('Closed','running','internal')  
					 and match.sporttype = 1  
				  GROUP BY bettrans.matchid  
				) c on m.matchid = c.matchid  
	-- inner join match_remark mr with (nolock) on m.matchid = mr.matchid   
	-- where mr.ishtcal=0   
		ORDER BY eventstatus, matchcode  
	END  
	ELSE IF @sporttype IN(2,3,32)  
	BEGIN  
		SELECT  m.matchid,  
			m.leagueid,  
			m.homeid,  
			m.awayid,                  
			m.matchcode,  
			m.kickofftime,  
			m.finalhomescore,  
			m.finalawayscore,  
			m.hthomescore,  
			m.htawayscore,  
			m.eventstatus,  
			m.betstatus,  
			m.IsNeutral,        
			C.betcount,  
			CASE m.confirmHT WHEN 0 THEN '' ELSE (SELECT username FROM custdb.dbo.custinfo WITH(NOLOCK) WHERE custid = m.confirmHT) end suspenderHT,  
			m.IsHTCal,   
			m.calculate,  
			m.isPending,
			m.isUndecided,  --Hurri@20120306  
			m.goalrecord,
			CASE WHEN c.cntFGLG = 0 THEN 0 ELSE 1 END AS isExistFGLG,
			CASE WHEN c.cntHTFGLG = 0 THEN 0 ELSE 1 END AS isExistHTFGLG
	 FROM	(
			SELECT match.matchid,  
				  match.leagueid,  
				  match.homeid,  
				  match.awayid,                  
				  match.matchcode,  
				  match.kickofftime,  
				  match.finalhomescore,  
				  match.finalawayscore,  
				  match.hthomescore,  
				  match.htawayscore,  
				  match.eventstatus,  
				  match.betstatus,  
				  ISNULL(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
				  mr.confirmHT,  
				  ISNULL(mr.IsHTCal,0) as IsHTCal,   
				  ISNULL(mr.calculate,0) as calculate,  
				  ISNULL(mr.isPending, 0) as isPending,   
				  ISNULL(mr.isUndecided,0) as isUndecided,  --Hurri@20120306  
				  match.goalrecord
			FROM   DBPRO.BODB02.dbo.match WITH(NOLOCK)  
				INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH(NOLOCK) ON match.matchid = mr.matchid                      
			WHERE  match.eventstatus <> 'Completed'    
				AND (
						(DATEDIFF(MINUTE,match.kickofftime,CURRENT_TIMESTAMP) > 25 
						 AND DATEDIFF(MINUTE,match.kickofftime,CURRENT_TIMESTAMP) < 60
						)  
						OR mr.confirmHT >0   
					)  
				AND mr.ishtcal = 0   
				AND match.eventdate = @FromDate  
				AND match.sporttype = @sporttype
			) m -- for basketball & football only  
			INNER JOIN  
			(
			SELECT   bettrans.matchid,  
				COUNT(bettrans.matchid)  betcount ,
				SUM(CASE WHEN bettype = 14 THEN 1 ELSE 0 END) AS cntFGLG,
				SUM(CASE WHEN bettype = 127 THEN 1 ELSE 0 END) AS cntHTFGLG
			FROM     bettrans WITH(NOLOCK,INDEX=CIX_matchid_bettype),  
				DBPRO.BODB02.dbo.match WITH(NOLOCK)  
			WHERE    match.eventdate = @FromDate  
				AND BETTYPE <= 19000  
				AND match.matchid = bettrans.matchid  
				AND match.eventstatus in ('Closed','running','internal')  
				AND match.sporttype = @sporttype  
			GROUP BY bettrans.matchid  
			) c on m.matchid = c.matchid  
	-- inner join match_remark mr with (nolock) on m.matchid = mr.matchid   
	-- where mr.ishtcal=0   
		ORDER BY eventstatus, matchcode  
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelCompletedHT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_MatchSelCompletedHT] TO [vnteam] AS [dbo]