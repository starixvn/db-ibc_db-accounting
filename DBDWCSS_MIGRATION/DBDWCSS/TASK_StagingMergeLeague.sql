CREATE PROCEDURE [dbo].[TASK_StagingMergeLeague]
AS
/*   
 Task: merge league_staging into TPDB.league
 DB: DBDWCSS.bodb_staging
 Revisions:   
  - 20121016@viet: create SP   
*/  
SET NOCOUNT ON

	SET IDENTITY_INSERT TPDB.dbo.league ON
	MERGE TPDB.dbo.league as d
		USING dbo.league_staging s with(nolock) ON d.leagueid = s.leagueid
		WHEN MATCHED THEN 
			UPDATE SET 
				leaguename = s.leaguename
				,maxstake = s.maxstake
				,minstake = s.minstake
				,maxstakeou = s.maxstakeou
				,maxstakeoe = s.maxstakeoe
				,leaguenamec = s.leaguenamec
				,leaguenametc = s.leaguenametc
				,creator = s.creator
				,lcolor = s.lcolor
				,hdp_min = s.hdp_min
				,hdp_max = s.hdp_max
				,hdp_risk = s.hdp_risk
				,hdp_range = s.hdp_range
				,hdp_allowance = s.hdp_allowance
				,hdp_gapodds = s.hdp_gapodds
				,hdp_gapoddsr = s.hdp_gapoddsr
				,ou_min = s.ou_min
				,ou_max = s.ou_max
				,ou_risk = s.ou_risk
				,ou_range = s.ou_range
				,ou_allowance = s.ou_allowance
				,ou_gapodds = s.ou_gapodds
				,ou_gapoddsr = s.ou_gapoddsr
				,oe_min = s.oe_min
				,oe_max = s.oe_max
				,oe_risk = s.oe_risk
				,oe_range = s.oe_range
				,oe_gapodds = s.oe_gapodds
				,cs_min = s.cs_min
				,cs_max = s.cs_max
				,cs_risk = s.cs_risk
				,cs_range = s.cs_range
				,cs_gapodds = s.cs_gapodds
				,b1x2_min = s.b1x2_min
				,b1x2_max = s.b1x2_max
				,b1x2_risk = s.b1x2_risk
				,b1x2_range = s.b1x2_range
				,b1x2_gapodds = s.b1x2_gapodds
				,tg_min = s.tg_min
				,tg_max = s.tg_max
				,tg_risk = s.tg_risk
				,tg_range = s.tg_range
				,tg_gapodds = s.tg_gapodds
				,ht_min = s.ht_min
				,ht_max = s.ht_max
				,ht_risk = s.ht_risk
				,ht_range = s.ht_range
				,ht_allowance = s.ht_allowance
				,ht_gapodds = s.ht_gapodds
				,ht_gapoddsr = s.ht_gapoddsr
				,ht1x2_min = s.ht1x2_min
				,ht1x2_max = s.ht1x2_max
				,ht1x2_risk = s.ht1x2_risk
				,ht1x2_range = s.ht1x2_range
				,ht1x2_gapodds = s.ht1x2_gapodds
				,leaguenamec_uni = s.leaguenamec_uni
				,leaguenamej = s.leaguenamej
				,sporttype = s.sporttype
				,createdate = s.createdate
				,leaguenamecn = s.leaguenamecn
				,oe_gapoddsr = s.oe_gapoddsr
				,DisplayMode = s.DisplayMode
				,isTest = s.isTest
				,leaguenameth = s.leaguenameth
				,ProgramID = s.ProgramID
				,TrackCondition = s.TrackCondition
				,IsActive = s.IsActive
				,leaguenameko = s.leaguenameko
				,TrackConditionCh = s.TrackConditionCh
				,TrackConditionCs = s.TrackConditionCs
				,leaguenameES = s.leaguenameES
				,CountryCode = s.CountryCode
				,leaguenameVN = s.leaguenameVN
				,GameSession = s.GameSession
				,SessionTime = s.SessionTime
				,OverTime = s.OverTime
				,leaguenameEL = s.leaguenameEL
				,OverTimeSession = s.OverTimeSession
				,IsCountDownTimer = s.IsCountDownTimer
		WHEN NOT MATCHED THEN 
		INSERT (
			leagueid, leaguename, maxstake, minstake, maxstakeou, maxstakeoe, leaguenamec, leaguenametc, creator, lcolor, hdp_min, hdp_max, hdp_risk, hdp_range, hdp_allowance, hdp_gapodds, hdp_gapoddsr, ou_min, ou_max, ou_risk, ou_range, ou_allowance, ou_gapodds, ou_gapoddsr, oe_min, oe_max, oe_risk, oe_range, oe_gapodds, cs_min, cs_max, cs_risk, cs_range, cs_gapodds, b1x2_min, b1x2_max, b1x2_risk, b1x2_range, b1x2_gapodds, tg_min, tg_max, tg_risk, tg_range, tg_gapodds, ht_min, ht_max, ht_risk, ht_range, ht_allowance, ht_gapodds, ht_gapoddsr, ht1x2_min, ht1x2_max, ht1x2_risk, ht1x2_range, ht1x2_gapodds, leaguenamec_uni, leaguenamej, sporttype, createdate, leaguenamecn, oe_gapoddsr, DisplayMode, isTest, leaguenameth, ProgramID, TrackCondition, IsActive, leaguenameko, TrackConditionCh, TrackConditionCs, leaguenameES, CountryCode, leaguenameVN, GameSession, SessionTime, OverTime, leaguenameEL, OverTimeSession, IsCountDownTimer
			)
		VALUES (
			s.leagueid, s.leaguename, s.maxstake, s.minstake, s.maxstakeou, s.maxstakeoe, s.leaguenamec, s.leaguenametc, s.creator, s.lcolor, s.hdp_min, s.hdp_max, s.hdp_risk, s.hdp_range, s.hdp_allowance, s.hdp_gapodds, s.hdp_gapoddsr, s.ou_min, s.ou_max, s.ou_risk, s.ou_range, s.ou_allowance, s.ou_gapodds, s.ou_gapoddsr, s.oe_min, s.oe_max, s.oe_risk, s.oe_range, s.oe_gapodds, s.cs_min, s.cs_max, s.cs_risk, s.cs_range, s.cs_gapodds, s.b1x2_min, s.b1x2_max, s.b1x2_risk, s.b1x2_range, s.b1x2_gapodds, s.tg_min, s.tg_max, s.tg_risk, s.tg_range, s.tg_gapodds, s.ht_min, s.ht_max, s.ht_risk, s.ht_range, s.ht_allowance, s.ht_gapodds, s.ht_gapoddsr, s.ht1x2_min, s.ht1x2_max, s.ht1x2_risk, s.ht1x2_range, s.ht1x2_gapodds, s.leaguenamec_uni, s.leaguenamej, s.sporttype, s.createdate, s.leaguenamecn, s.oe_gapoddsr, s.DisplayMode, s.isTest, s.leaguenameth, s.ProgramID, s.TrackCondition, s.IsActive, s.leaguenameko, s.TrackConditionCh, s.TrackConditionCs, s.leaguenameES, s.CountryCode, s.leaguenameVN, s.GameSession, s.SessionTime, s.OverTime, s.leaguenameEL, s.OverTimeSession, s.IsCountDownTimer
			)
	;--end MERGE
	SET IDENTITY_INSERT TPDB.dbo.league OFF

	IF @@ERROR = 0 EXEC dbo.StagingConfirmCompleted @tablename = 'league'
SET NOCOUNT OFF

GO

