ALTER PROCEDURE [dbo].[TASK_StagingMergeRecomm_log]
AS
/*   
 Task: merge recomm_log_staging into TPDB.recomm_log
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121016@viet: create SP   
*/  
SET NOCOUNT ON

	SET IDENTITY_INSERT TPDB.dbo.recomm_log ON
	MERGE TPDB.dbo.recomm_log as d
		USING dbo.recomm_log_staging s with(nolock) ON d.recommid = s.recommid
		WHEN MATCHED THEN 
			UPDATE SET 
				LCSid = s.LCSid
				,recommdate = s.recommdate
				,matchid = s.matchid
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
				,currency = s.currency
				,currency2 = s.currency2
				,actualrate = s.actualrate
				,virtualrate = s.virtualrate
				,betdaqid = s.betdaqid
				,SecAcceptFlag = s.SecAcceptFlag
				,checktime = s.checktime
				,refno = s.refno
				,winlostdate = s.winlostdate
				,betid = s.betid
				,betcheck = s.betcheck
		WHEN NOT MATCHED THEN 
		INSERT (
			recommid, LCSid, recommdate, matchid, bettype, oddsid, hdp1, hdp2, odds, betteam, stake, status, statusID, tpositiontaking, livehomescore, liveawayscore, liveindicator, currency, currency2, actualrate, virtualrate, betdaqid, SecAcceptFlag, checktime, refno, winlostdate, betid, betcheck
			)
		VALUES (
			s.recommid, s.LCSid, s.recommdate, s.matchid, s.bettype, s.oddsid, s.hdp1, s.hdp2, s.odds, s.betteam, s.stake, s.status, s.statusID, s.tpositiontaking, s.livehomescore, s.liveawayscore, s.liveindicator, s.currency, s.currency2, s.actualrate, s.virtualrate, s.betdaqid, s.SecAcceptFlag, s.checktime, s.refno, s.winlostdate, s.betid, s.betcheck
			)
	;--end MERGE
	SET IDENTITY_INSERT TPDB.dbo.recomm_log OFF

	IF @@ERROR = 0 EXEC dbo.StagingConfirmCompleted @tablename = 'recomm_log'
SET NOCOUNT OFF

GO