USE bodb_CustomerLog
GO

ALTER PROCEDURE dbo.NAP_Set_AutoPayout_ReferenceActionByMatchSel @MatchIds VARCHAR(MAX)
	, @ActionIds VARCHAR(1024)
AS

/*	Creator: 20160311@Patrick
	Task: Auto Payout - Get reference action
	DB: DB052/bodb_CustomerLog
	
	Revision:	
		- 20160930@Bobby: #65002 - Add HomeValue & AwayValue info
      
	Param's Explanation:
		
		
*/
BEGIN
	SET NOCOUNT ON

	;WITH MatchTmp AS (
		SELECT CAST(val AS INT) AS MatchId
		FROM bodb02.dbo.Lrf_f_StringSplit(@MatchIds, ',')
	), ActionLogTmp AS (
		SELECT CAST(val AS INT) AS ActionId
		FROM bodb02.dbo.strSplit(@ActionIds, ',')
	)

	SELECT LogId, MatchID, ActionID, CASE WHEN Remark LIKE 'Failed%' THEN 1 ELSE 0 END AS IsFailed
		, CASE 	WHEN ActionID = 178 THEN hthomescore 
				WHEN ActionID = 179 THEN finalhomescore 
				ELSE 0 
		END AS HomeValue
		, CASE 	WHEN ActionID = 178 THEN htawayscore 
				WHEN ActionID = 179 THEN finalawayscore 
				ELSE 0 
		END AS AwayValue
		
	FROM dbo.UserLog_Settle l WITH(NOLOCK)
	WHERE EXISTS (SELECT TOP 1 1 FROM MatchTmp f WHERE f.MatchId = l.MatchID)
		AND EXISTS (SELECT TOP 1 1 FROM ActionLogTmp f WHERE f.ActionId = l.ActionID)
	ORDER BY LogId

END

GO

GRANT EXECUTE ON dbo.NAP_Set_AutoPayout_ReferenceActionByMatchSel TO [bodbAdminNet] AS [dbo]
GO
