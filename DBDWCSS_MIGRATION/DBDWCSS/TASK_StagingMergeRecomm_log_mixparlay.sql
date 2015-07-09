ALTER PROCEDURE [dbo].[TASK_StagingMergeRecomm_log_mixparlay]
AS
/*   
 Task: merge recomm_log_mixparlay_staging into TPDB.recomm_log_mixparlay
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121016@viet: create SP   
*/  
SET NOCOUNT ON

	SET IDENTITY_INSERT TPDB.dbo.recomm_log_mixparlay ON
	MERGE TPDB.dbo.recomm_log_mixparlay as d
		USING dbo.recomm_log_mixparlay_staging s with(nolock) ON d.transid = s.transid
		WHEN MATCHED THEN 
			UPDATE SET 
				recommdate = s.recommdate
				,matchid = s.matchid
				,sporttype = s.sporttype
				,bettype = s.bettype
				,oddsid = s.oddsid
				,hdp1 = s.hdp1
				,hdp2 = s.hdp2
				,odds = s.odds
				,betteam = s.betteam
				,stake = s.stake
				,status = s.status
				,statusID = s.statusID
				,tpositiontaking = s.tpositiontaking
				,livehomescore = s.livehomescore
				,liveawayscore = s.liveawayscore
				,liveindicator = s.liveindicator
				,actualrate = s.actualrate
				,refno = s.refno
				,winlostdate = s.winlostdate
		WHEN NOT MATCHED THEN 
		INSERT (
			transid, recommdate, matchid, sporttype, bettype, oddsid, hdp1, hdp2, odds, betteam, stake, status, statusID, tpositiontaking, livehomescore, liveawayscore, liveindicator, actualrate, refno, winlostdate
			)
		VALUES (
			transid, s.recommdate, s.matchid, s.sporttype, s.bettype, s.oddsid, s.hdp1, s.hdp2, s.odds, s.betteam, s.stake, s.status, s.statusID, s.tpositiontaking, s.livehomescore, s.liveawayscore, s.liveindicator, s.actualrate, s.refno, s.winlostdate
			)
	;--end MERGE
	SET IDENTITY_INSERT TPDB.dbo.recomm_log_mixparlay OFF

	IF @@ERROR = 0 EXEC dbo.StagingConfirmCompleted @tablename = 'recomm_log_mixparlay'
SET NOCOUNT OFF

GO


