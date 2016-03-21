USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Set_AutoPayout_ScheduleSel] 
AS
/*	Creator: 20160303@Patrick
	Task: Get list matches use for auto-pay-out service
	DB: DBPRO/BODB02
	
	Revisions:
		
	Param's Explanation:
 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @TypeIds TABLE(TypeId TINYINT)

	INSERT INTO @TypeIds(TypeId)
	VALUES(1) --half time
		, (2) --full time

	SELECT MatchId, HomeValue, AwayValue, TypeId, IsUndecided, IsPending, IsConfirmHT
		, IsConfirmFT, BetStatus, GoalRecord, IsHalfTimeCalculated
	FROM (
		SELECT m.matchid AS MatchId
			, CASE WHEN mr.ConfirmHT > 0 AND f.typeId = 1 THEN m.hthomescore
				WHEN mr.ConfirmFT > 0 AND f.typeId = 2 THEN m.finalhomescore
				ELSE NULL END AS HomeValue
			, CASE WHEN mr.ConfirmHT > 0 AND f.typeId = 1 THEN m.htawayscore
				WHEN mr.ConfirmFT > 0 AND f.typeId = 2 THEN m.finalawayscore
				ELSE NULL END AS AwayValue
			, f.TypeId
			, mr.isUndecided AS IsUndecided
			, mr.isPending AS IsPending
			, CASE WHEN f.TypeId = 1 THEN mr.ConfirmHT
					WHEN f.TypeId = 2 THEN mr.ConfirmFT
					ELSE 0 END AS IsConfirmed
			, mr.ConfirmHT AS IsConfirmHT
			, mr.ConfirmFT AS IsConfirmFT
			, m.betstatus AS BetStatus
			, m.GoalRecord
			, mr.IsHTCal AS IsHalfTimeCalculated
		FROM dbo.match m WITH(NOLOCK)
			INNER JOIN dbo.match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			INNER JOIN dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
			CROSS APPLY @typeIds f
		WHERE m.eventstatus = 'running' and m.sporttype = 1
			AND (mr.ConfirmHT > 0 OR mr.ConfirmFT > 0)
			AND 1 = CASE WHEN m.IsAutoPayout IS NULL THEN ISNULL(l.IsAutoPayout, 0)
						 WHEN m.IsAutoPayout = 1 THEN 1
					ELSE 0 END
			AND NOT EXISTS (SELECT TOP 1 1 
								FROM dbo.AutoPayoutResult rs WITH(NOLOCK) 
								WHERE rs.MatchId = m.matchid 
									AND f.TypeId = rs.CalculationType AND rs.StatusId IN (1, 2, 3))
	)t
	WHERE IsConfirmed > 0
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_ScheduleSel] TO [bodbAdminNet] AS [dbo]
GO
