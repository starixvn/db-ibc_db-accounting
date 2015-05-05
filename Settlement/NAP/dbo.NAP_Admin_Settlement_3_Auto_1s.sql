ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_3_Auto_1s] 
  @MatchID		INT
 ,@ResourceIDs	VARCHAR(MAX)	= '' 
 ,@Mode			VARCHAR(6)		= 'CAL'
AS
/*	Creator: Jamie
	Date: 20150205
	Task: BetRadar Auto/Manual Settlement
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:

	Param's Explanation:
*/	
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @betCount_135			INT = 0
			,@betCount_160			INT = 0 
			,@betCount_164			INT = 0
			,@betCount_168			INT = 0
			,@betCount_169			INT = 0
			,@betCount_173			INT = 0
			,@betCount_174			INT = 0
			,@betCount_175			INT = 0
			,@betCount_176			INT = 0
			,@betCount_192			INT = 0
			,@betCount_193			INT = 0
			,@betCount_180			INT = 0
			,@betCount_210			INT = 0
			,@betCount_211			INT = 0
			,@betCount_212			INT = 0
			,@betCount_213			INT = 0
			,@betCount_214			INT = 0
			,@betCount_215			INT = 0
			,@betCount_216			INT = 0
			,@betCount_217			INT = 0

			,@penaltyshootout		VARCHAR(10)	=''
			,@matchDecidedMethod	VARCHAR(10)	=''
			,@1st10Min1x2			VARCHAR(10)	=''
			,@1stGoalTime10Min		VARCHAR(10)	=''
			,@1stGoalTime15Min		VARCHAR(10)	=''
			,@WhoAdvancesNextRound	VARCHAR(10) =''
			,@ExtraTimeandGoal		VARCHAR(10)	=''
			,@ExtraTimeYN			VARCHAR(10) =''	

			,@PlayerSentOff			VARCHAR(10) =''
			,@HTPlayerSentOff		VARCHAR(10) =''
			,@PlayerSentOffHome		VARCHAR(10) =''
			,@HTPlayerSentOffHome	VARCHAR(10) =''
			,@PlayerSentOffAway		VARCHAR(10) =''
			,@HTPlayerSentOffAway	VARCHAR(10) =''
			,@GoalScorerFirst		VARCHAR(10) =''		
				
			,@1HNextGoal			VARCHAR(MAX)=''
			,@NextGoal				VARCHAR(MAX)=''
			,@NextGoalTime15Min		VARCHAR(MAX)=''
			,@ExtraNextGoal			VARCHAR(MAX)=''
			,@GoalScorerAnytime		VARCHAR(MAX)=''

	DECLARE	@tmpResourceIDs TABLE(
		ResourceID	VARCHAR(20)
		,Bettype	INT
	)
	INSERT INTO @tmpResourceIDs(ResourceID,Bettype)
	SELECT val, CAST(LEFT(val,3) AS INT) FROM strSplit(@ResourceIDs,',')

	DECLARE	@tmpResultDetail TABLE(
		 MatchID			INT
		,ResourceID			VARCHAR(20)
		,HomeValue			VARCHAR(20)
		,AwayValue			VARCHAR(20)
		,SettlementStatusID	TINYINT
	)
	INSERT INTO @tmpResultDetail(
		MatchID
		,ResourceID
		,HomeValue
		,AwayValue
		,SettlementStatusID
	)
	SELECT	 MatchID
			,ResourceID
			,HomeValue
			,AwayValue
			,SettlementStatusID
	FROM	DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
	WHERE	MatchID = @MatchID 
			AND ResourceID IN (SELECT ResourceID FROM @tmpResourceIDs)
			AND SettlementStatusID = 4 

	SELECT	 @betCount_135	= ISNULL(SUM(CASE WHEN bettype = 135 THEN 1 ELSE 0 END),0)
			,@betCount_160	= ISNULL(SUM(CASE WHEN bettype = 160 THEN 1 ELSE 0 END),0)
			,@betCount_164	= ISNULL(SUM(CASE WHEN bettype = 164 THEN 1 ELSE 0 END),0)
			,@betCount_168	= ISNULL(SUM(CASE WHEN bettype = 168 THEN 1 ELSE 0 END),0)
			,@betCount_169  = ISNULL(SUM(CASE WHEN bettype = 169 THEN 1 ELSE 0 END),0)
			,@betCount_173	= ISNULL(SUM(CASE WHEN bettype = 173 THEN 1 ELSE 0 END),0)
			,@betCount_174	= ISNULL(SUM(CASE WHEN bettype = 174 THEN 1 ELSE 0 END),0)
			,@betCount_175  = ISNULL(SUM(CASE WHEN bettype = 175 THEN 1 ELSE 0 END),0)
			,@betCount_176  = ISNULL(SUM(CASE WHEN bettype = 176 THEN 1 ELSE 0 END),0)
			,@betCount_192  = ISNULL(SUM(CASE WHEN bettype = 192 THEN 1 ELSE 0 END),0)
			,@betCount_193  = ISNULL(SUM(CASE WHEN bettype = 193 THEN 1 ELSE 0 END),0)
			,@betCount_180  = ISNULL(SUM(CASE WHEN bettype = 180 THEN 1 ELSE 0 END),0)	
			,@betCount_210	= ISNULL(SUM(CASE WHEN bettype = 210 THEN 1 ELSE 0 END),0)
			,@betCount_211	= ISNULL(SUM(CASE WHEN bettype = 211 THEN 1 ELSE 0 END),0)
			,@betCount_212	= ISNULL(SUM(CASE WHEN bettype = 212 THEN 1 ELSE 0 END),0)
			,@betCount_213	= ISNULL(SUM(CASE WHEN bettype = 213 THEN 1 ELSE 0 END),0)
			,@betCount_214	= ISNULL(SUM(CASE WHEN bettype = 214 THEN 1 ELSE 0 END),0)
			,@betCount_215	= ISNULL(SUM(CASE WHEN bettype = 215 THEN 1 ELSE 0 END),0)
			,@betCount_216	= ISNULL(SUM(CASE WHEN bettype = 216 THEN 1 ELSE 0 END),0)
			,@betCount_217	= ISNULL(SUM(CASE WHEN bettype = 217 THEN 1 ELSE 0 END),0)
	FROM	dbo.Bettrans WITH (NOLOCK)
	WHERE	MatchID = @MatchID 
			AND( Bettype IN (135,160,164,168,169,173,174,175,176,180,192,193)
					OR Bettype BETWEEN 210 AND 217 
			)
			AND	Bettype IN  (SELECT Bettype FROM @tmpResourceIDs)
			AND StatusID NOT BETWEEN 101 AND 102 

	SELECT	 @penaltyshootout		= ISNULL(MAX(CASE WHEN ResourceID='135' THEN HomeValue ELSE '' END),'')
			,@WhoAdvancesNextRound	= ISNULL(MAX(CASE WHEN ResourceID='168' THEN HomeValue ELSE '' END),'')
			,@ExtraTimeYN			= ISNULL(MAX(CASE WHEN ResourceID='173' THEN HomeValue ELSE '' END),'')
			,@ExtraTimeandGoal		= ISNULL(MAX(CASE WHEN ResourceID='174' THEN HomeValue ELSE '' END),'')
			,@matchDecidedMethod	= ISNULL(MAX(CASE WHEN ResourceID='175' THEN HomeValue ELSE '' END),'')  
			,@1st10Min1x2			= ISNULL(MAX(CASE WHEN ResourceID='176' THEN HomeValue ELSE '' END),'') 
			,@1stGoalTime10Min		= ISNULL(MAX(CASE WHEN ResourceID='192' THEN HomeValue ELSE '' END),'') 
			,@1stGoalTime15Min		= ISNULL(MAX(CASE WHEN ResourceID='193' THEN HomeValue ELSE '' END),'')

			,@PlayerSentOff			= ISNULL(MAX(CASE WHEN ResourceID='210' THEN HomeValue ELSE '' END),'')
			,@HTPlayerSentOff		= ISNULL(MAX(CASE WHEN ResourceID='211' THEN HomeValue ELSE '' END),'')
			,@PlayerSentOffHome		= ISNULL(MAX(CASE WHEN ResourceID='212' THEN HomeValue ELSE '' END),'')
			,@HTPlayerSentOffHome	= ISNULL(MAX(CASE WHEN ResourceID='213' THEN HomeValue ELSE '' END),'')
			,@PlayerSentOffAway		= ISNULL(MAX(CASE WHEN ResourceID='214' THEN AwayValue ELSE '' END),'')	--AwayValue 
			,@HTPlayerSentOffAway	= ISNULL(MAX(CASE WHEN ResourceID='215' THEN AwayValue ELSE '' END),'') --AwayValue

			,@GoalScorerFirst		= ISNULL(MAX(CASE WHEN ResourceID='217' THEN HomeValue ELSE '' END),'')
	FROM	@tmpResultDetail
	WHERE	MatchID = @MatchID 
			AND ResourceID IN (SELECT ResourceID FROM @tmpResourceIDs)
	
	SELECT	 @NextGoal				= @NextGoal + CASE WHEN ResourceID LIKE '160__' THEN ResourceID + HomeValue +',' ELSE '' END 
			,@ExtraNextGoal			= @ExtraNextGoal +  CASE WHEN ResourceID LIKE '164__' THEN ResourceID + HomeValue +',' ELSE '' END 
			,@NextGoalTime15Min		= @NextGoalTime15Min + CASE WHEN ResourceID LIKE '169__' THEN ResourceID + HomeValue +',' ELSE '' END 
			,@1HNextGoal			= @1HNextGoal + CASE WHEN ResourceID LIKE '180__' THEN ResourceID + HomeValue +',' ELSE '' END 
			,@GoalScorerAnytime		= @GoalScorerAnytime + CASE WHEN ResourceID LIKE '216__' THEN ISNULL(HomeValue,'') +',' ELSE '' END 
	FROM	@tmpResultDetail
	WHERE	MatchID = @MatchID 
			AND ResourceID IN (SELECT ResourceID FROM @tmpResourceIDs)
	
	EXEC dbo.NAP_Admin_Calculate_Main
				 @matchid				= @matchid
				,@action				= 'CAL-AUTO'
				,@mode					= 'CAL'
				,@ResourceIDs			= @ResourceIDs
				,@penaltyshootout		= @penaltyshootout
				,@matchDecidedMethod	= @matchDecidedMethod
				,@1st10Min1x2			= @1st10Min1x2
				,@1stGoalTime10Min		= @1stGoalTime10Min
				,@1stGoalTime15Min		= @1stGoalTime15Min
				,@WhoAdvancesNextRound	= @WhoAdvancesNextRound
				,@ExtraTimeandGoal		= @ExtraTimeandGoal	
				,@ExtraTimeYN			= @ExtraTimeYN
				,@NextGoal				= @NextGoal
				,@ExtraNextGoal			= @ExtraNextGoal
				,@NextGoalTime15Min		= @NextGoalTime15Min
				,@1HNextGoal			= @1HNextGoal
				,@PlayerSentOff			= @PlayerSentOff
				,@HTPlayerSentOff		= @HTPlayerSentOff
				,@PlayerSentOffHome		= @PlayerSentOffHome
				,@HTPlayerSentOffHome	= @HTPlayerSentOffHome
				,@PlayerSentOffAway		= @PlayerSentOffAway
				,@HTPlayerSentOffAway	= @HTPlayerSentOffAway
				,@GoalScorerAnytime		= @GoalScorerAnytime
				,@GoalScorerFirst		= @GoalScorerFirst
				,@betCount_135			= @betCount_135
				,@betCount_160			= @betCount_160
				,@betCount_164			= @betCount_164
				,@betCount_168			= @betCount_168
				,@betCount_169			= @betCount_169
				,@betCount_173			= @betCount_173
				,@betCount_174			= @betCount_174
				,@betCount_175			= @betCount_175
				,@betCount_176			= @betCount_176
				,@betCount_180			= @betCount_180
				,@betCount_192			= @betCount_192
				,@betCount_193			= @betCount_193
				,@betCount_210			= @betCount_210
				,@betCount_211			= @betCount_211
				,@betCount_212			= @betCount_212
				,@betCount_213			= @betCount_213
				,@betCount_214			= @betCount_214
				,@betCount_215			= @betCount_215
				,@betCount_216			= @betCount_216
				,@betCount_217			= @betCount_217
				,@CalledByBrokerService = 0	

END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_3_Auto_1s] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_3_Auto_1s] TO [vnteam] AS [dbo]