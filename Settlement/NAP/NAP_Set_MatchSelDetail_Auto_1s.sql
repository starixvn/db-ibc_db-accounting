ALTER PROCEDURE [dbo].[NAP_Set_MatchSelDetail_Auto_1s]
	@MatchID		INT

AS
/*	Creator: Jamie
	Date: 20150202
	Task: BetRadar - Auto settlement detail for manual calculation 
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:
		- 20160705@Kathy: PH-AIO phase 2 (67 bettypes ) [Redmine:#53154]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON 
			
	DECLARE	@tmpTicketStatus TABLE(
		 ResourceID		VARCHAR(20)
		,BetCount		INT
		,InRunning		INT
	)

	DECLARE	@IsSettleAbandonedMatchIBC	BIT = 0 

	IF EXISTS (
				SELECT 1
				FROM bettrans b WITH (NOLOCK)
					INNER JOIN dbo.f_Set_GetGroupBettypes() f
						ON b.bettype = f.BetType
				WHERE	f.GroupId = 8 
						AND f.IsDetermined = 1
						AND matchid = @matchid AND statusID NOT IN (101, 102, 103) 
						AND ruben = 0 
						--AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND recommend <> 1688156)
			)
	BEGIN
		SELECT @IsSettleAbandonedMatchIBC = 1
	END
	INSERT INTO @tmpTicketStatus(ResourceID, BetCount, InRunning)
	SELECT	CASE	WHEN b.bettype = 135 THEN '135'
					WHEN b.bettype = 160 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 164 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 168 THEN '168'
					WHEN b.bettype = 169 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 173 THEN '173'
					WHEN b.bettype = 174 THEN '174'
					WHEN b.bettype = 175 THEN '175'
					WHEN b.bettype = 176 THEN '176'
					WHEN b.bettype = 180 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 192 THEN '192'
					WHEN b.bettype = 193 THEN '193'
					WHEN b.bettype = 210 THEN '210'
					WHEN b.bettype = 211 THEN '211'
					WHEN b.bettype = 212 THEN '212'
					WHEN b.bettype = 213 THEN '213'
					WHEN b.bettype = 214 THEN '214'
					WHEN b.bettype = 215 THEN '215'
					WHEN b.bettype = 216 THEN '216'
					WHEN b.bettype = 217 THEN '217'
					WHEN b.bettype = 426 THEN '426'
					ELSE 0 END AS ResourceID
			,SUM(CASE	WHEN StatusID BETWEEN 101 AND 102 THEN 0
						ELSE 1 END)
			,SUM(CASE	WHEN StatusID = 0 THEN 1 
						ELSE 0 END)
	FROM	dbo.Bettrans b WITH (NOLOCK)
		INNER JOIN dbo.f_Set_GetGroupBettypes() f
			ON b.bettype = f.BetType
	WHERE	f.GroupId = 8
			AND matchID = @MatchID 
	GROUP BY CASE	WHEN b.bettype = 135 THEN '135'
					WHEN b.bettype = 160 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 164 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 168 THEN '168'
					WHEN b.bettype = 169 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 173 THEN '173'
					WHEN b.bettype = 174 THEN '174'
					WHEN b.bettype = 175 THEN '175'
					WHEN b.bettype = 176 THEN '176'
					WHEN b.bettype = 180 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN b.bettype = 192 THEN '192'
					WHEN b.bettype = 193 THEN '193'
					WHEN b.bettype = 210 THEN '210'
					WHEN b.bettype = 211 THEN '211'
					WHEN b.bettype = 212 THEN '212'
					WHEN b.bettype = 213 THEN '213'
					WHEN b.bettype = 214 THEN '214'
					WHEN b.bettype = 215 THEN '215'
					WHEN b.bettype = 216 THEN '216'
					WHEN b.bettype = 217 THEN '217'
					WHEN b.bettype = 426 THEN '426'
					ELSE 0 END


	-- Match Info 
	SELECT	m.LeagueID
			,m.MatchID
			,m.matchcode
			,m.kickofftime
			,playTime = datediff(minute, m.kickofftime, CURRENT_TIMESTAMP) 
			,m.homeid
			,m.awayid
			,IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC 
	FROM	DBPRO.bodb02.dbo.Match m WITH (NOLOCK)
	WHERE	MatchID = @MatchID

	-- Detail  		 
	SELECT	 ResourceID = CASE WHEN COALESCE(r.ResourceID,t.ResourceID) ='216' THEN '21601' ELSE COALESCE(r.ResourceID,t.ResourceID) END 
			,TicketStatus = CASE WHEN t.ResourceID IS NULL OR t.BetCount = 0 THEN 'No Ticket'
								 WHEN t.InRunning = 0 THEN 'Calculated'
								 ELSE 'Running' END 
 			,HomeValue = CASE WHEN r.ResourceId BETWEEN 214 AND 215 THEN r.AwayValue ELSE r.HomeValue END
			,r.OtherInfo
			,r.ResultStatusID
			,r.SettlementStatusID

	FROM	@tmpTicketStatus t
			FULL JOIN( 
				SELECT	 r.MatchID  
				        ,r.ResourceId
						,CASE WHEN r.ResourceID LIKE '216__' THEN '216' ELSE r.ResourceID END AS ResourceID2 
						,r.HomeValue
						,r.AwayValue
						,r.OtherInfo
						,r.ResultStatusID
						,r.SettlementStatusID
				FROM	DBPRO.bodb02.dbo.ResultDetail r WITH (NOLOCK) 
				WHERE	r.MatchID = @MatchID
							AND( r.ResourceID IN ('135','168','192','193','217','426')
									OR r.ResourceID LIKE '17[3-6]'
									OR r.ResourceID LIKE '21[0-5]'
									OR r.ResourceID LIKE '160__'
									OR r.ResourceID LIKE '164__'
									OR r.ResourceID LIKE '169__'
									OR r.ResourceID LIKE '180__'
									OR r.ResourceID LIKE '216__'
							)
			) r ON t.ResourceID = r.ResourceId2
	ORDER BY ResourceID ASC 

END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelDetail_Auto_1s] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelDetail_Auto_1s] TO [vnteam] AS [dbo]