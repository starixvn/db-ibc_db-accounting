ALTER PROCEDURE [dbo].[NAP_Set_MatchSelDetail_Auto_1s]
	@MatchID		INT

AS
/*	Creator: Jamie
	Date: 20150202
	Task: BetRadar - Auto settlement detail for manual calculation 
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @betCount_135		INT 
			,@betCount_160		INT
			,@betCount_164		INT
			,@betCount_169		INT
			,@betCount_175		INT 
			,@betCount_176		INT
			,@betCount_180		INT 
			,@betCount_192		INT
			,@betCount_193		INT
			
	DECLARE	@tmpTicketStatus TABLE(
		 ResourceID		VARCHAR(20)
		,BetCount		INT
		,InRunning		INT
	)

	INSERT INTO @tmpTicketStatus(ResourceID, BetCount, InRunning)
	SELECT	CASE	WHEN bettype = 135 THEN '135'
					WHEN bettype = 160 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 164 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 169 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 175 THEN '175'
					WHEN bettype = 176 THEN '176'
					WHEN bettype = 180 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 192 THEN '192'
					WHEN bettype = 193 THEN '193'
					ELSE 0 END
			,SUM(CASE	WHEN StatusID BETWEEN 101 AND 102 THEN 0
						ELSE 1 END)
			,SUM(CASE	WHEN StatusID = 0 THEN 1 
						ELSE 0 END)
	FROM	dbo.Bettrans WITH (NOLOCK)
	WHERE	bettype IN (135,160,164,169,175,176,180,192,193)
			AND matchID = @MatchID 
	GROUP BY CASE	WHEN bettype = 135 THEN '135'
					WHEN bettype = 160 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 164 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 169 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 175 THEN '175'
					WHEN bettype = 176 THEN '176'
					WHEN bettype = 180 THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5)
					WHEN bettype = 192 THEN '192'
					WHEN bettype = 193 THEN '193'
					ELSE 0 END
				 
	SELECT	 t.ResourceID
			,t.BetCount
			,t.InRunning
			,r.ResourceId
			,r.HomeValue
			,r.ResultStatusID
			,r.SettlementStatusID
	FROM	@tmpTicketStatus t
			FULL OUTER JOIN ResultDetail r WITH (NOLOCK) ON t.ResourceID = r.ResourceId
	WHERE	r.ResourceID IN ('135','175','176','192','193')
			OR r.ResourceID LIKE '160__'
			OR r.ResourceID LIKE '164__'
			OR r.ResourceID LIKE '169__'
			OR r.ResourceID LIKE '180__'
				
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelDetail_Auto_1s] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelDetail_Auto_1s] TO [vnteam] AS [dbo]