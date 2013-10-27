

ALTER PROCEDURE [dbo].[Acc_Set_MatchSelCompleted]
	@FromDate datetime,
	@sporttype tinyint = 0
AS

/*
	Created by: []
	Date: 2008
	Task: List FT-completed matches for billing
	DB: DBTXN/BODB02

	Revisions:
		- 20080116@Vinh: add filter by sporttype
		- 20090429@PhuongDao: Add matches confirmed by suspender
		- 20100618@Joe: Change the way to get data to reduce load for main DB.
		- 20101014@Jamie: Check to get Refund eventstatus 
		- 20110620@Jamie: Refer Match in DB02 instead of DBTRANS
		- 20110907@Sophia: Add column IsHTCal, calculate for Pending Status
		- 20111003@Sophia: Add column IsPending for Pending Status  
		- 20120306@Hurri: Add column IsUndecided for mark/unmark Undecided match
		- 20130121@Elodie: Change link server DB02 to DBPRO
		- 20130325@Lukas: get goalrecord & isExistFGLG
		- 20131027@Lukas: add filter winlostdate to reduce data return
*/  
BEGIN 
	SET NOCOUNT ON  
  
	DECLARE @m TABLE (matchid int primary key, IsHTCal bit, suspenderHT varchar(20), suspenderFT varchar(20), calculate bit, isPending bit, isUndecided bit, goalrecord varchar(50))  --Hurri@20120306

	INSERT INTO @m  
	SELECT  
		 m.matchid, mr.IsHTCal, IsNull(ht.username, ''), IsNull(ft.username, ''),   
		 mr.calculate, ISNULL(mr.isPending,0) as isPending, ISNULL(mr.isUndecided,0) as isUndecided,  --Hurri@20120306
		 m.goalrecord
	FROM  
		 DBPRO.BODB02.dbo.match m with (nolock)  
		 INNER JOIN DBPRO.BODB02.dbo.match_remark mr with (nolock) ON m.matchid = mr.matchid  
		 LEFT OUTER JOIN dbo.custinfo ht with (nolock) ON mr.ConfirmHT = ht.custid  
		 LEFT OUTER JOIN dbo.custinfo ft with (nolock) ON mr.ConfirmFT = ft.custid  
	WHERE m.eventdate = @FromDate  
		 AND m.sporttype = case when @sporttype = 0 then sporttype else @sporttype end  
		 AND m.eventstatus <> N'Completed'  
		 AND (m.kickofftime < dateadd(s, -6000, CURRENT_TIMESTAMP) or mr.ConfirmFT > 0)  
  
	SELECT  
		 m.matchid,  
		 m.leagueid,  
		 m.homeid,  
		 m.awayid,  
		 m.matchcode,  
		 m.kickofftime,  
		 m.finalhomescore,  
		 m.finalawayscore,  
		 m.hthomescore,  
		 m.htawayscore,  
		CASE	WHEN m.betstatus like 'Refund FT%' then 'Refund FT'  
				WHEN m.betstatus like 'Refund HT%' then 'Refund HT'  
				WHEN m.betstatus like 'Refund%' then 'Refund'  
				ELSE m.eventstatus  
		END AS eventstatus,  
		m.eventstatus,  
		m.betstatus,  
		m.IsNeutral,  
		C.betcount,  
		ishtcal,  
		suspenderHT,  
		suspenderFT,  
		ISNULL(tm.IsHTCal,0) as IsHTCal,  
		ISNULL(tm.calculate,0) as calculate,  
		ISNULL(tm.IsPending,0) as IsPending,
		ISNULL(tm.isUndecided,0) as isUndecided,  --Hurri@20120306  
		m.goalrecord,
		c.isExistFGLG
	FROM  DBPRO.BODB02.dbo.match m with (nolock)  
		INNER JOIN @m tm ON m.matchid = tm.matchid  
		INNER JOIN  
			  (  
				SELECT b.matchid, COUNT(b.matchid) AS BetCount
					,SUM(CASE WHEN bettype = 14 THEN 1 ELSE 0 END) AS isExistFGLG
				FROM dbo.bettrans b WITH(NOLOCK)
					INNER JOIN @m stm ON b.matchid = stm.matchid  
				WHERE winlostdate = @FromDate
				GROUP BY b.matchid  
			  ) as c ON m.matchid = c.matchid  
  
	ORDER BY  m.eventstatus, m.matchcode
END
GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelCompleted] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_MatchSelCompleted] TO [vnteam] AS [dbo]
