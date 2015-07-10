ALTER PROCEDURE dbo.Task_ABMatch_Archive 
@errCode INT = 0 OUTPUT,
@errMesg VARCHAR(1000) = '' OUTPUT
AS 
/*	Created by: Jamie 
	Date: 2012-11-15
	Task: Archive [ABMatch_Remark] to [ABMatch_Remark_BK] 
	DB: DB052.bodb_ABS 
	
	Revisions: 
		- 20130115@Johnson: add column betteam into ABMatch_Remark_BK

*/
SET NOCOUNT ON 
IF EXISTS (
	SELECT	TOP 1 1 
	FROM	ABMatch_Remark abm WITH (NOLOCK) 
			LEFT JOIN bodb02.dbo.Match m WITH (NOLOCK) ON abm.matchid = m.matchid 
			LEFT JOIN bodb02.dbo.Match14 m14 WITH (NOLOCK) ON abm.matchid = m14.matchID 
	WHERE	abm.MatchID IS NOT NULL
			AND m.matchID IS NULL
			AND m14.MatchID IS NULL 	
) 
BEGIN 
	
	CREATE TABLE #tmpABMatch (MatchID INT PRIMARY KEY)

	INSERT INTO #tmpABMatch(MatchID)
	SELECT	DISTINCT abm.matchid
	FROM	ABMatch_Remark abm WITH (NOLOCK) 
			LEFT JOIN bodb02.dbo.Match m WITH (NOLOCK) ON abm.matchid = m.matchid 
			LEFT JOIN bodb02.dbo.Match14 m14 WITH (NOLOCK) ON abm.matchid = m14.matchID 
	WHERE	abm.MatchID IS NOT NULL
			AND m.matchID IS NULL
			AND m14.MatchID IS NULL 	


	INSERT INTO [bodb_ABS].[dbo].[ABMatch_Remark_BK]
			   ([matchid]
			   ,[bettype]
			   ,[betteam]
			   ,[hdp]
			   ,[odds]
			   ,[transid])
	           
	SELECT	[matchid]
		   ,[bettype]
		   ,[betteam]
		   ,[hdp]
		   ,[odds]
		   ,[transid]
	FROM	[bodb_ABS].[dbo].[ABMatch_Remark] WITH (NOLOCK) 
	WHERE	matchid IN (
				SELECT matchid FROM #tmpABMatch WITH (NOLOCK)
			)
	IF @@ERROR = 0 
	BEGIN	
		WHILE (1=1)
		BEGIN		
			DELETE TOP(10000) FROM ABMatch_Remark WITH (ROWLOCK)
			WHERE	matchid IN (SELECT matchid FROM #tmpABMatch WITH (NOLOCK))
			
			IF @@ROWCOUNT < 10000 BREAK 
			
		END
	END 
	ELSE 
	BEGIN
		SELECT	@errCode = 100,
				@errMesg = 'FAILED: Archiving Match(es).'
		RETURN
	END

	DROP TABLE #tmpABMatch

END 